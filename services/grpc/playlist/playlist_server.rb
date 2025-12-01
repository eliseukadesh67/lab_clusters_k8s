require 'grpc'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'rack'
require 'webrick'
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
  def setup_metrics
    @registry = Prometheus::Client.registry
    @grpc_requests_total = Prometheus::Client::Counter.new(
      :grpc_server_requests_total,
      docstring: 'Total de requisições gRPC por método e código',
      labels: [:service, :grpc_method, :grpc_code]
    )
    @grpc_handling_seconds = Prometheus::Client::Histogram.new(
      :grpc_server_handling_seconds,
      docstring: 'Duração das requisições gRPC por método',
      labels: [:service, :grpc_method],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    )

    @registry.register(@grpc_requests_total)
    @registry.register(@grpc_handling_seconds)

    start_metrics_server
  end

  def start_metrics_server
    app = proc do |env|
      if env['PATH_INFO'] == '/metrics'
        body = Prometheus::Client::Formats::Text.marshal(@registry)
        [200, { 'Content-Type' => 'text/plain; version=0.0.4' }, [body]]
      else
        [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
      end
    end

    Thread.new do
      Rack::Handler::WEBrick.run(app, Host: '0.0.0.0', Port: 9464, AccessLog: [], Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO))
    end
  end

  SERVICE = 'grpc-playlist'.freeze
  def initialize
    super
    setup_metrics
    @download_stub = Download::DownloadService::Stub.new(DOWNLOAD_SERVICE_ADDR, :this_channel_is_insecure)
  end

  def get_playlists(_empty_request, _call)
    method = 'GetPlaylists'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    playlists_models = repo.get_playlists
    items = playlists_models.map { |p_model| model_to_proto_playlist(p_model) }
    resp = Playlist::Playlists.new(items: items)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def get_playlists_by_id(request, _call)
    method = 'GetPlaylistsById'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    playlist_model = repo.get_playlists_by_id(request.id)
    unless playlist_model
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'NOT_FOUND' })
      raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.")
    end
    resp = model_to_proto_playlist(playlist_model)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def post_playlists(request, _call)
    method = 'PostPlaylists'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    new_playlist_model = repo.post_playlists(name: request.name)
    resp = Playlist::PlaylistId.new(id: new_playlist_model.id)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def patch_playlists(request, _call)
    method = 'PatchPlaylists'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    updated_playlist = repo.patch_playlists(id: request.id, name: request.name)
    unless updated_playlist
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'NOT_FOUND' })
      raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.")
    end
    resp = Playlist::PlaylistId.new(id: updated_playlist.id)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def delete_playlists(request, _call)
    method = 'DeletePlaylists'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    was_deleted = repo.delete_playlists(id: request.id)
    unless was_deleted
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'NOT_FOUND' })
      raise GRPC::NotFound.new("Playlist com ID '#{request.id}' não encontrada.")
    end
    resp = Playlist::Empty.new
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def get_videos_by_id(request, _call)
    method = 'GetVideosById'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    video_model = repo.get_videos_by_id(request.id)
    unless video_model
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'NOT_FOUND' })
      raise GRPC::NotFound.new("Vídeo com ID '#{request.id}' não encontrado.")
    end
    resp = model_to_proto_video(video_model)
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
  end

  def post_videos(request, _call)
    method = 'PostVideos'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
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
      resp = Playlist::VideoId.new(id: new_video.id)
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
      resp
    rescue GRPC::BadStatus => e
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: e.code || 'ERROR' })
      raise GRPC::InvalidArgument.new("Erro ao obter metadados do vídeo: #{e.details}")
    rescue SQLite3::ConstraintException
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'ALREADY_EXISTS' })
      raise GRPC::AlreadyExists.new("Vídeo com URL '#{request.url}' já existe na playlist.")
    end
  end
  
  def delete_videos(request, _call)
    method = 'DeleteVideos'
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    repo = PlaylistRepository.new
    was_deleted = repo.delete_videos(id: request.id)
    unless was_deleted
      @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'NOT_FOUND' })
      raise GRPC::NotFound.new("Vídeo não encontrado na playlist.")
    end
    resp = Playlist::Empty.new
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    @grpc_handling_seconds.observe({ service: SERVICE, grpc_method: method }, duration)
    @grpc_requests_total.increment({ service: SERVICE, grpc_method: method, grpc_code: 'OK' })
    resp
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
