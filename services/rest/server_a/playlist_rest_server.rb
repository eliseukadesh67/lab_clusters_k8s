require 'sinatra'
require 'json'
require 'net/http'
require_relative 'playlist_repository'

# Configure Sinatra
set :port, 5001
set :bind, '0.0.0.0'
set :show_exceptions, false

DOWNLOAD_SERVICE_URL = 'http://localhost:5002'

# Helper methods
helpers do
  def json_params
    request.body.rewind
    JSON.parse(request.body.read, symbolize_names: true)
  rescue JSON::ParserError
    halt 400, json_error('JSON inválido')
  end

  def json_response(data, status = 200)
    content_type :json
    status status
    data.to_json
  end

  def json_error(message, status = 400)
    content_type :json
    status status
    { error: message }.to_json
  end

  def model_to_hash_video(video_model)
    {
      id: video_model.id,
      url: video_model.url,
      title: video_model.title,
      duration: video_model.duration,
      thumbnail_url: video_model.thumbnail_url,
      playlist_id: video_model.playlist_id
    }
  end

  def model_to_hash_playlist(playlist_model)
    {
      id: playlist_model.id,
      name: playlist_model.name,
      videos: playlist_model.videos.map { |v| model_to_hash_video(v) }
    }
  end

  def get_video_metadata_from_service_b(video_url)
    uri = URI("#{DOWNLOAD_SERVICE_URL}/metadata")
    request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    request.body = { video_url: video_url }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.code == '200'
      JSON.parse(response.body, symbolize_names: true)
    else
      error_data = JSON.parse(response.body, symbolize_names: true) rescue { error: 'Erro desconhecido' }
      raise "Erro ao obter metadados do vídeo: #{error_data[:error]}"
    end
  rescue StandardError => e
    raise "Erro ao comunicar com Service B: #{e.message}"
  end
end

# Health check
get '/health' do
  json_response({ status: 'healthy', service: 'playlist-service' })
end

# ========================================
# Playlist Endpoints
# ========================================

# List all playlists
get '/playlists' do
  repo = PlaylistRepository.new
  playlists_models = repo.get_playlists
  items = playlists_models.map { |p| model_to_hash_playlist(p) }
  json_response({ items: items })
end

# Get playlist by ID
get '/playlists/:id' do
  repo = PlaylistRepository.new
  playlist_model = repo.get_playlists_by_id(params[:id])
  
  if playlist_model
    json_response(model_to_hash_playlist(playlist_model))
  else
    json_error("Playlist com ID '#{params[:id]}' não encontrada.", 404)
  end
end

# Create new playlist
post '/playlists' do
  data = json_params
  
  unless data[:name]
    halt 400, json_error('Nome da playlist é obrigatório.')
  end

  begin
    repo = PlaylistRepository.new
    new_playlist = repo.post_playlists(name: data[:name])
    json_response({ id: new_playlist.id }, 201)
  rescue SQLite3::ConstraintException
    json_error("Playlist com nome '#{data[:name]}' já existe.", 409)
  end
end

# Update playlist
patch '/playlists/:id' do
  data = json_params
  
  unless data[:name]
    halt 400, json_error('Nome da playlist é obrigatório.')
  end

  begin
    repo = PlaylistRepository.new
    updated_playlist = repo.patch_playlists(id: params[:id], name: data[:name])
    
    if updated_playlist
      json_response({ id: updated_playlist.id })
    else
      json_error("Playlist com ID '#{params[:id]}' não encontrada.", 404)
    end
  rescue SQLite3::ConstraintException
    json_error("Playlist com nome '#{data[:name]}' já existe.", 409)
  end
end

# Delete playlist
delete '/playlists/:id' do
  repo = PlaylistRepository.new
  was_deleted = repo.delete_playlists(id: params[:id])
  
  if was_deleted
    status 204
    ''
  else
    json_error("Playlist com ID '#{params[:id]}' não encontrada.", 404)
  end
end

# ========================================
# Video Endpoints
# ========================================

# Get video by ID
get '/videos/:id' do
  repo = PlaylistRepository.new
  video_model = repo.get_videos_by_id(params[:id])
  
  if video_model
    json_response(model_to_hash_video(video_model))
  else
    json_error("Vídeo com ID '#{params[:id]}' não encontrado.", 404)
  end
end

# Add video to playlist
post '/videos' do
  data = json_params
  
  unless data[:playlist_id] && data[:url]
    halt 400, json_error('playlist_id e url são obrigatórios.')
  end

  repo = PlaylistRepository.new
  
  # Check if playlist exists
  unless repo.get_id_playlists(data[:playlist_id])
    halt 404, json_error("Playlist com ID '#{data[:playlist_id]}' não encontrada.")
  end

  begin
    # Get video metadata from Service B
    metadata = get_video_metadata_from_service_b(data[:url])
    
    # Save video with metadata
    new_video = repo.post_videos(
      playlist_id: data[:playlist_id],
      url: data[:url],
      title: metadata[:title],
      duration: metadata[:duration],
      thumbnail_url: metadata[:thumbnail_url]
    )
    
    json_response({ id: new_video.id }, 201)
  rescue SQLite3::ConstraintException
    json_error("Vídeo com URL '#{data[:url]}' já existe na playlist.", 409)
  rescue StandardError => e
    json_error(e.message, 400)
  end
end

# Delete video
delete '/videos/:id' do
  repo = PlaylistRepository.new
  was_deleted = repo.delete_videos(id: params[:id])
  
  if was_deleted
    status 204
    ''
  else
    json_error("Vídeo não encontrado na playlist.", 404)
  end
end

# Error handlers
error 400 do
  json_error('Bad Request', 400)
end

error 404 do
  json_error('Not Found', 404)
end

error 500 do
  json_error('Internal Server Error', 500)
end

# Start server
if __FILE__ == $0
  puts "=" * 60
  puts "Service A - Playlist REST API Server"
  puts "=" * 60
  puts "Servidor iniciado em http://localhost:5001"
  puts ""
  puts "Endpoints disponíveis:"
  puts "  GET    /playlists        - Listar todas as playlists"
  puts "  GET    /playlists/:id    - Buscar playlist por ID"
  puts "  POST   /playlists        - Criar nova playlist"
  puts "  PATCH  /playlists/:id    - Editar playlist"
  puts "  DELETE /playlists/:id    - Deletar playlist"
  puts "  GET    /videos/:id       - Buscar vídeo por ID"
  puts "  POST   /videos           - Adicionar vídeo à playlist"
  puts "  DELETE /videos/:id       - Deletar vídeo"
  puts "  GET    /health           - Health check"
  puts "=" * 60
  puts ""
  puts "IMPORTANTE: Certifique-se de que o Service B está rodando em #{DOWNLOAD_SERVICE_URL}"
  puts "=" * 60
end
