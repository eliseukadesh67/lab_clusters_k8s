require 'grpc'
require 'securerandom'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

class PlaylistServer < Playlist::PlaylistService::Service

  def initialize
    @playlists = {}
  end

  def create_playlist(request, _call)
    new_playlist = {
      id: SecureRandom.uuid,
      name: request.name,
      videos: []
    }

    @playlists[new_playlist[:id]] = new_playlist

    Playlist::PlaylistResponse.new(
      id: new_playlist[:id],
      name: new_playlist[:name],
      qtd_video: new_playlist[:videos].count
    )
  end

  def get_playlist(request, _call)
    playlist_id = request.playlist_id
    playlist = @playlists[playlist_id]
    unless playlist
      raise GRPC::NotFound.new("Playlist com ID '#{playlist_id}' não encontrada.")
    end
    Playlist::PlaylistResponse.new(
      id: playlist[:id],
      name: playlist[:name],
      qtd_video: playlist[:videos].count
    )
  end

  def list_playlists(_request, _call)
    all_playlists = @playlists.values.map do |playlist|
      Playlist::PlaylistResponse.new(
        id: playlist[:id],
        name: playlist[:name],
        qtd_video: playlist[:videos].count
      )
    end
    Playlist::ListPlaylistsResponse.new(playlists: all_playlists)
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