require 'grpc'
require 'securerandom'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

class PlaylistServer < Playlist::PlaylistService::Service

  def create_playlist(request, _call)

    response = Playlist::PlaylistResponse.new(
      id: SecureRandom.uuid,
      name: request.name,
      videos: []
    )

    response
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