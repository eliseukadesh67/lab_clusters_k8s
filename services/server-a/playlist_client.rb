require 'grpc'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

def print_usage
  puts "Uso: client.rb <comando> [argumentos...]"
  puts "Comandos de Playlist:"
  puts "  create <nome_playlist>"
  puts "  get <id_playlist>"
  puts "  list"
  puts "  edit <id_playlist> <novo_nome>"
  puts "  delete <id_playlist>"
  exit 1
end

def print_playlist(response)
  puts "ID Playlist: #{response.id}"
  puts "   - Nome: '#{response.name}'"
  puts "   - Qtd. Vídeos: #{response.qtd_video}"
end

def main
  print_usage if ARGV[0].nil?
  hostname = 'localhost:50051'
  stub = Playlist::PlaylistService::Stub.new(hostname, :this_channel_is_insecure)
  begin
    case ARGV[0]
    when 'create'
      print_usage if ARGV[1].nil?
      response = stub.create_playlist(Playlist::CreatePlaylistRequest.new(name: ARGV[1]))
      print_playlist(response)
    when 'get'
      print_usage if ARGV[1].nil?
      response = stub.get_playlist(Playlist::GetPlaylistRequest.new(playlist_id: ARGV[1]))
      print_playlist(response)
    when 'list'
      response = stub.list_playlists(Playlist::ListPlaylistsRequest.new)
      puts "#{response.playlists.count} PLAYLISTS:"
      response.playlists.each do |playlist| print_playlist(playlist) end
      when 'edit'
        print_usage if ARGV[1].nil? || ARGV[2].nil?
        response = stub.edit_playlist(Playlist::EditPlaylistRequest.new(playlist_id: ARGV[1], name: ARGV[2]))
        print_playlist(response)
      when 'delete'
        print_usage if ARGV[1].nil?
        response = stub.delete_playlist(Playlist::DeletePlaylistRequest.new(playlist_id: ARGV[1]))
        puts "#{response.playlists.count} PLAYLISTS:"
        response.playlists.each do |playlist| print_playlist(playlist) end
      else
        puts "Comando '#{ARGV[0]}' desconhecido."
        print_usage
      end
  rescue GRPC::AlreadyExists => e
    puts e.details.force_encoding('UTF-8')
  rescue GRPC::NotFound => e
    puts e.details.force_encoding('UTF-8')
  rescue GRPC::BadStatus => e
    puts e.message
  end
end

main