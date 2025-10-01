require 'grpc'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

def main
  
  playlist_name = ARGV[0]

  if playlist_name.nil? || playlist_name.empty?
    puts "Erro: Você precisa de fornecer o nome da playlist como argumento."
    puts "Exemplo de uso: bundle exec ruby -I . playlist_client.rb \"Nome da Playlist\""
    exit 1
  end
  
  hostname = 'localhost:50051'
  stub = Playlist::PlaylistService::Stub.new(hostname, :this_channel_is_insecure)
  
  begin
    puts "--> A enviar pedido para criar a playlist: '#{playlist_name}'..."
    
    request = Playlist::CreatePlaylistRequest.new(name: playlist_name)
    
    response = stub.create_playlist(request)
    
    puts "   ID: #{response.id}"
    puts "   Nome: #{response.name}"
    puts "   Vídeos: #{response.videos.empty? ? '0' : response.videos}"
    
  rescue GRPC::BadStatus => e
    puts "❌ Ocorreu um erro: #{e.message}"
  end
end

main