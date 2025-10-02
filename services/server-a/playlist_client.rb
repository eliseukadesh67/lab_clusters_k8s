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
  puts "Comandos de Vídeo:"
  puts "  add_video <id_playlist> <url_video>"
  puts "  get_video <id_playlist> <id_video>"
  puts "  list_video <id_playlist>"
  puts "  delete_video <id_playlist> <id_video>"
  exit 1
end

def print_playlist(response)
  puts "ID Playlist: #{response.playlist_id}"
  puts "   - Nome: '#{response.name}'"
  puts "   - Qtd. Vídeos: #{response.qtd_video}"
end

def print_video(response)
  puts "  - ID Vídeo: #{response.video_id} - URL: #{response.url}"
end

def print_videos_to_playlist(response)
  puts "ID Playlist: #{response.playlist_id}"
  response.videos.each do |video|
    print_video(video)
  end
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
    when 'add_video'
      print_usage if ARGV[1].nil? || ARGV[2].nil?
      response = stub.add_video(Playlist::AddVideoRequest.new(playlist_id: ARGV[1], url: ARGV[2]))
      print_video(response)
    when 'get_video'
      print_usage if ARGV[1].nil? || ARGV[2].nil?
      response = stub.get_video(Playlist::GetVideoRequest.new(playlist_id: ARGV[1], video_id: ARGV[2]))
      print_video(response)
    when 'list_video'
      print_usage if ARGV[1].nil?
      response = stub.list_videos(Playlist::ListVideoRequest.new(playlist_id: ARGV[1]))
      print_videos_to_playlist(response)
    when 'delete_video'
      print_usage if ARGV[1].nil? || ARGV[2].nil?
      response = stub.delete_video(Playlist::DeleteVideoRequest.new(playlist_id: ARGV[1], video_id: ARGV[2]))
      print_videos_to_playlist(response)
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