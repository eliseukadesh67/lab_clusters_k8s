require 'grpc'
require 'securerandom'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

class PlaylistServer < Playlist::PlaylistService::Service

  def initialize
    @playlists = {}
  end

  def create_playlist(request, _call)
    if @playlists.values.any? { |p| p[:name] == request.name }
      raise GRPC::AlreadyExists.new("Playlist com nome '#{request.name}' já existe.")
    end
    new_playlist = {id: SecureRandom.uuid,name: request.name,videos: []}
    @playlists[new_playlist[:id]] = new_playlist
    response_playlist(new_playlist)
  end

  def get_playlist(request, _call)
    playlist = find_playlist!(request.playlist_id)
    response_playlist(playlist)
  end

  def list_playlists(_request, _call)
    all_playlists = @playlists.values.map { |p| response_playlist(p) }
    Playlist::ListPlaylistsResponse.new(playlists: all_playlists)
  end

  def edit_playlist(request, _call)
    if @playlists.values.any? { |p| p[:name] == request.name && p[:id] != request.playlist_id }
      raise GRPC::AlreadyExists.new("Já existe outra playlist com o nome '#{request.name}'.")
    end
    playlist = find_playlist!(request.playlist_id)
    playlist[:name] = request.name
    response_playlist(playlist)
  end

  def delete_playlist(request, _call)
    find_playlist!(request.playlist_id)  # Já lança exceção se não existir
    @playlists.delete(request.playlist_id)
    list_playlists(nil, nil)
  end

  def response_playlist(playlist)
    Playlist::PlaylistResponse.new(
      id: playlist[:id],
      name: playlist[:name],
      qtd_video: playlist[:videos].count
    )
  end

  def find_playlist!(playlist_id)
    playlist = @playlists[playlist_id]
    raise GRPC::NotFound.new("Playlist com ID '#{playlist_id}' não encontrada.") unless playlist
    playlist
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