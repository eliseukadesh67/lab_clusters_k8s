require 'sqlite3'
require 'ulid'

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
      videos = get_videos(row['id'])
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
