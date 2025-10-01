require 'grpc'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

def print_usage
  puts "Erro: Argumentos inválidos."
  puts "Uso:"
  puts "  bundle exec ruby -I . client.rb create \"<nome_da_playlist>\""
  puts "  bundle exec ruby -I . client.rb get_id \"<id_da_playlist>\""
  puts "  bundle exec ruby -I . client.rb list"
  exit 1
end

def print_playlist(response)
  puts "   - ID: #{response.id}, Nome: '#{response.name}', Qtd. Vídeos: #{response.qtd_video}"
end

def main
  
  command, argument = ARGV

  print_usage if command.nil?
  
  hostname = 'localhost:50051'
  stub = Playlist::PlaylistService::Stub.new(hostname, :this_channel_is_insecure)
  
  begin
    case command
    when 'create'
      request = Playlist::CreatePlaylistRequest.new(name: argument)
      response = stub.create_playlist(request)
      print_playlist(response)
    when 'getId'
      request = Playlist::GetPlaylistRequest.new(playlist_id: argument)
      response = stub.get_playlist(request)
      print_playlist(response)
    when 'list'
      request = Playlist::ListPlaylistsRequest.new
      response = stub.list_playlists(request)
      response.playlists.each do |playlist|
        print_playlist(playlist)
      end
    else
      puts "Comando '#{command}' desconhecido."
      print_usage
    end

  rescue GRPC::NotFound => e
    puts e.details.force_encoding('UTF-8')
  rescue GRPC::BadStatus => e
    puts e.message
  end
end

main