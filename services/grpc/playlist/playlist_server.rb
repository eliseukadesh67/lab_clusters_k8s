require 'grpc'
require 'sqlite3'
require 'ulid'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'
require_relative 'download_pb'
require_relative 'download_services_pb'

$stdout.sync = true

DOWNLOAD_SERVICE_ADDR = ENV["DOWNLOADS_GRPC_URL"]

module Model
  Playlist = Struct.new(:id, :name, :videos, keyword_init: true)
  Video = Struct.new(:id, :url, :title, :duration, :thumbnail_url, :playlist_id, keyword_init: true)
end

class PlaylistRepository
  DB_FILE = 'playlists.db'

  def initialize
    @db = SQLite3::Database.new(DB_FILE)
    @db.results_as_hash = true
    @db.execute("PRAGMA journal_mode = WAL;") 
    @db.execute("PRAGMA foreign_keys = OFF;")
    create_schema_if_not_exists
  end

  def get_playlists_by_id(id)
    rows = @db.execute("SELECT * FROM playlists WHERE id LIKE ?", [id])
    return nil if rows.empty?
    
    row = rows.first
    videos = get_videos(id)
    Model::Playlist.new(id: row['id'], name: row['name'], videos: videos)
  end

  def get_id_playlists(id)
    rows = @db.execute("SELECT id FROM playlists WHERE id LIKE ?", [id])
    return nil if rows.empty?
    rows.first['id']
  end

  def get_playlists
    rows = @db.execute("SELECT * FROM playlists ORDER BY id DESC")
    rows.map do |row|
      videos = get_videos(row['iurld'])
      Model::Playlist.new(id: row['id'], name: row['name'], videos: videos)
    end
  end
  
  def post_playlists(name:)
    new_id = ULID.generate
    @db.execute("INSERT INTO playlists (id, name) VALUES (?, ?)", [new_id, name])
    get_playlists_by_id(new_id)
  end

  def patch_playlists(id:, name:)
    @db.execute("UPDATE playlists SET name = ? WHERE id LIKE ?", [name, id])
    get_playlists_by_id(id)
  end

  def delete_playlists(id:)
    @db.execute("DELETE FROM playlists WHERE id LIKE ?", [id])
    @db.changes > 0
  end

  def get_videos_by_id(id)
    row = @db.get_first_row("SELECT * FROM videos WHERE id LIKE ?", [id])
    return nil unless row
    Model::Video.new(row.transform_keys(&:to_sym))
  end

  def get_videos(playlist_id)
    rows = @db.execute("SELECT * FROM videos WHERE playlist_id LIKE ? ORDER BY id", [playlist_id])
    rows.map { |row| Model::Video.new(row.transform_keys(&:to_sym)) }
  end

  def post_videos(playlist_id:, url:, title:, duration:, thumbnail_url:)
    video_id = ULID.generate
    @db.execute(
      "INSERT INTO videos (id, playlist_id, url, title, duration, thumbnail_url) VALUES (?, ?, ?, ?, ?, ?)",
      [video_id, playlist_id, url, title, duration, thumbnail_url]
    )
    get_videos_by_id(video_id)
  end

  def delete_videos(id:)
    @db.execute("DELETE FROM videos WHERE id LIKE ?", [id])
    @db.changes > 0
  end

  private

  def create_schema_if_not_exists
    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      );
    SQL

    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS videos (
        id TEXT PRIMARY KEY,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        duration INTEGER NOT NULL,
        thumbnail_url TEXT NOT NULL,
        playlist_id TEXT NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        UNIQUE(playlist_id, url)
      );
    SQL
  end
end

class PlaylistServer < Playlist::PlaylistService::Service
  def initialize
    @download_stub = Download::DownloadService::Stub.new(DOWNLOAD_SERVICE_ADDR, :this_channel_is_insecure)
  end

  def get_playlists(_empty_request, _call)
    repo = PlaylistRepository.new
    playlists_models = repo.get_playlists
    items = playlists_models.map { |p_model| model_to_proto_playlist(p_model) }
    Playlist::Playlists.new(items: items)
  end

  def get_playlists_by_id(request, _call)
    repo = PlaylistRepository.new
    playlist_model = repo.get_playlists_by_id(request.id)
    raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.") unless playlist_model
    model_to_proto_playlist(playlist_model)
  end

  def post_playlists(request, _call)
    repo = PlaylistRepository.new
    new_playlist_model = repo.post_playlists(name: request.name)
    Playlist::PlaylistId.new(id: new_playlist_model.id)
  end

  def patch_playlists(request, _call)
    repo = PlaylistRepository.new
    updated_playlist = repo.patch_playlists(id: request.id, name: request.name)
    raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.") unless updated_playlist
    Playlist::PlaylistId.new(id: updated_playlist.id)
  end

  def delete_playlists(request, _call)
    repo = PlaylistRepository.new
    was_deleted = repo.delete_playlists(id: request.id)
    raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.") unless was_deleted
    Playlist::Empty.new
  end

  def get_videos_by_id(request, _call)
    repo = PlaylistRepository.new
    video_model = repo.get_videos_by_id(request.id)
    raise GRPC::NotFound.new("Vídeo com ID '#{request.id}' não encontrado.") unless video_model
    model_to_proto_video(video_model)
  end

  def post_videos(request, _call)
    repo = PlaylistRepository.new
    raise GRPC::NotFound.new("Playlist com ID '#{request.playlist_id}' não encontrada.") unless repo.get_id_playlists(request.playlist_id)

    begin
      metadata = @download_stub.get_metadata(Download::Request.new(url: request.url))

      new_video = repo.post_videos(
        playlist_id: request.playlist_id,
        url: request.url,
        title: metadata.title,
        duration: metadata.duration,
        thumbnail_url: metadata.thumbnail_url
      )
      Playlist::VideoId.new(id: new_video.id)
    rescue GRPC::BadStatus => e
      raise GRPC::InvalidArgument.new("Erro ao obter metadados do vídeo: #{e.details}")
    rescue SQLite3::ConstraintException
      raise GRPC::AlreadyExists.new("Vídeo com URL '#{request.url}' já existe na playlist.")
    end
  end
  
  def delete_videos(request, _call)
    repo = PlaylistRepository.new
    was_deleted = repo.delete_videos(id: request.id)
    raise GRPC::NotFound.new("Vídeo não encontrado na playlist.") unless was_deleted
    Playlist::Empty.new
  end

  private

  def model_to_proto_video(video_model)
    Playlist::Video.new(
      id: video_model.id, 
      url: video_model.url, 
      title: video_model.title,
      duration: video_model.duration, 
      thumbnail_url: video_model.thumbnail_url,
      playlist_id: video_model.playlist_id
    )
  end

  def model_to_proto_playlist(playlist_model)
    proto_videos = playlist_model.videos.map { |v| model_to_proto_video(v) }
    Playlist::Playlist.new(
      id: playlist_model.id, 
      name: playlist_model.name, 
      videos: proto_videos
    )
  end
end

def main
  port = '0.0.0.0:50051'
  server = GRPC::RpcServer.new
  server.add_http2_port(port, :this_port_is_insecure)
  server.handle(PlaylistServer.new)  
  server.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT'])
end

main
