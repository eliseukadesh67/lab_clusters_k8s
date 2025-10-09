require 'grpc'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'

def print_usage
  puts "Uso: ruby #{$PROGRAM_NAME} <comando> [argumentos...]"
  puts "\nPLAYLISTS:"
  puts "  post_playlists <'nome da playlist'>"
  puts "  get_playlists"
  puts "  get_playlists_by_id <id_playlist>"
  puts "  patch_playlists <id_playlist> <'novo nome'>"
  puts "  delete_playlists <id_playlist>"
  puts "\nVÍDEOS:"
  puts "  get_videos_by_id <id_video>"
  puts "  post_videos <id_playlist> <url_do_video>"
  puts "  delete_videos <id_video>"
end

def print_playlist(p)
  puts "   #{p.name} (ID: #{p.id}) [#{p.videos.size} vídeo(s)]"
  p.videos.each { |v| puts "  - 🎵 #{v.title} (ID: #{v.id})" }
  puts "-" * 40
end

def print_video(video)
  puts "   #{video.title} (ID: #{video.id})"
  puts "   URL: #{video.url}"
  puts "   Thumbnail: #{video.thumbnail_url}"
  puts "   Duração: #{Time.at(video.duration).utc.strftime('%H:%M:%S').sub(/^00:/, '')}"
  puts "-" * 40
end

def main
  command, *args = ARGV
  print_usage if command.nil?

  hostname = 'localhost:50051'
  stub = Playlist::PlaylistService::Stub.new(hostname, :this_channel_is_insecure)

  begin
    case command
    when 'get_playlists'
      response = stub.get_playlists(Playlist::Empty.new)
      puts "Encontradas #{response.items.count} playlists."
      response.items.each { |p| print_playlist(p) }

    when 'get_playlists_by_id'
      raise "É necessário fornecer o ID da playlist." if args.empty?
      request = Playlist::PlaylistId.new(id: args[0])
      response = stub.get_playlists_by_id(request)
      print_playlist(response)

    when 'post_playlists'
      raise "É necessário fornecer o nome da playlist." if args.empty?
      request = Playlist::PlaylistInfo.new(name: args.join(' '))
      response = stub.post_playlists(request)
      puts "Playlist criada com sucesso! ID: #{response.id}"

    when 'patch_playlists'
      raise "Forneça o ID da playlist e o novo nome." if args.size < 2
      request = Playlist::PlaylistPatchInfo.new(id: args[0], name: args[1])
      response_id = stub.patch_playlists(request)
      puts "--> Playlist atualizada!"
      updated_playlist = stub.get_playlists_by_id(response_id)
      print_playlist(updated_playlist)

    when 'delete_playlists'
      raise "Forneça o ID da playlist." if args.empty?
      request = Playlist::PlaylistId.new(id: args[0])
      stub.delete_playlists(request)
      puts "--> Playlist com ID '#{args[0]}' deletada com sucesso."

    when 'get_videos_by_id'
      raise "Forneça o ID do vídeo." if args.empty?
      request = Playlist::VideoId.new(id: args[0])
      response = stub.get_videos_by_id(request)
      print_video(response)

    when 'post_videos'
      raise "Forneça o ID da playlist e a URL do vídeo." if args.size < 2
      request = Playlist::VideoPostInfo.new(playlist_id: args[0], url: args[1])
      response_id = stub.post_videos(request)
      puts "--> Vídeo adicionado com sucesso! (ID: #{response_id.id})"
      
      video_request = Playlist::VideoId.new(id: response_id.id)
      video_response = stub.get_videos_by_id(video_request)
      print_video(video_response)

    when 'delete_videos'
      raise "Forneça o ID do vídeo a ser deletado." if args.empty?
      request = Playlist::VideoId.new(id: args[0])
      stub.delete_videos(request)
      puts "--> Vídeo com ID '#{args[0]}' deletado com sucesso."

    else
      puts "Comando '#{command}' desconhecido."
      print_usage
    end
  rescue GRPC::BadStatus => e
    puts "--> ERRO: #{e.details}"
  rescue StandardError => e
    puts "--> ERRO: #{e.message}"
  end
end

main