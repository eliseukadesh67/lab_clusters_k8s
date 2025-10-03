require 'grpc'
require 'securerandom'
require_relative 'playlist_pb'
require_relative 'playlist_services_pb'
require_relative 'download_pb'
require_relative 'download_services_pb'

DOWNLOAD_SERVER_ADDR = 'localhost:50052'

class PlaylistServer < Playlist::PlaylistService::Service
  
  # --- PLAYLIST ---

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
    find_playlist!(request.playlist_id)
    @playlists.delete(request.playlist_id)
    list_playlists(nil, nil)
  end

  # --- VIDEO ---

  def download_stub
    @download_stub ||= Download::DownloadService::Stub.new(DOWNLOAD_SERVER_ADDR, :this_channel_is_insecure)
  end

  def add_video(request, _call)
    playlist = find_playlist!(request.playlist_id)
    if playlist[:videos].any? { |v| v[:url] == request.url }
      raise GRPC::AlreadyExists.new("Vídeo com URL '#{request.url}' já existe na playlist.")
    end
    begin
      metadata_request = Download::DownloadRequest.new(video_url: request.url)
      metadata_response = download_stub.get_video_metadata(metadata_request)
    rescue GRPC::BadStatus => e
      raise GRPC::InvalidArgument.new("Erro ao obter metadados do vídeo: #{e.message}")
    end

    video = {
      id: SecureRandom.uuid,
      url: request.url,
      title: metadata_response.title,
      duration: metadata_response.duration,
      thumbnail_url: metadata_response.thumbnail_url
    }
    playlist[:videos] << video
    Playlist::VideoResponse.new(
      playlist_id: playlist[:id],
      video_id: video[:id],
      url: video[:url],
      title: video[:title],
      duration: video[:duration],
      thumbnail_url: video[:thumbnail_url]
    )
  end

  def get_video(request, _call)
    playlist = find_playlist!(request.playlist_id)
    video = find_video!(playlist, request.video_id)
    Playlist::VideoResponse.new(
      playlist_id: playlist[:id],
      video_id: video[:id],
      url: video[:url],
      title: video[:title],
      duration: video[:duration],
      thumbnail_url: video[:thumbnail_url]
    )
  end
  
  def list_videos(request, _call)
    playlist = find_playlist!(request.playlist_id)
    videos = playlist[:videos].map { |v| Playlist::VideoResponse.new(
      playlist_id: playlist[:id],
      video_id: v[:id],
      url: v[:url],
      title: v[:title],
      duration: v[:duration],
      thumbnail_url: v[:thumbnail_url]
    ) }
    Playlist::ListVideosResponse.new(playlist_id: playlist[:id], videos: videos)
  end

  def delete_video(request, _call)
    playlist = find_playlist!(request.playlist_id)
    video = find_video!(playlist, request.video_id)
    playlist[:videos].delete(video)
    list_videos(Playlist::ListVideoRequest.new(playlist_id: request.playlist_id), nil)
  end

  # --- AUX ---
  private

  def response_playlist(playlist)
    Playlist::PlaylistResponse.new(
      playlist_id: playlist[:id],
      name: playlist[:name],
      qtd_video: playlist[:videos].count
    )
  end

  def find_playlist!(playlist_id)
    playlist = @playlists[playlist_id]
    raise GRPC::NotFound.new("Playlist com ID '#{playlist_id}' não encontrada.") unless playlist
    playlist
  end

  def find_video!(playlist, video_id)
    video = playlist[:videos].find { |v| v[:id] == video_id }
    raise GRPC::NotFound.new("Vídeo com ID '#{video_id}' não encontrado.") unless video
    video
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