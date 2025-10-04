import grpc
import os
import yt_dlp
from concurrent import futures
import threading
import queue
import download_pb2
import download_pb2_grpc

class DownloadService(download_pb2_grpc.DownloadServiceServicer):

    def GetVideoMetadata(self, request, context):
        """
        Extrai metadados de um vídeo sem baixá-lo.
        """
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
        }
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info_dict = ydl.extract_info(request.video_url, download=False)
            title = info_dict.get('title', 'N/A')
            duration = int(info_dict.get('duration', 0))
            thumbnail_url = info_dict.get('thumbnail', '')
            
            return download_pb2.VideoMetadataResponse(
                title=title,
                duration=duration,
                thumbnail_url=thumbnail_url
            )
        except Exception as e:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details(f"Não foi possível extrair metadados: {e}")
            return download_pb2.VideoMetadataResponse()
    
    def DownloadVideo(self, request, context):
        progress_queue = queue.Queue()

        def progress_hook(d):
            if d['status'] == 'downloading':
                try:
                    total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate')
                    if total_bytes:
                        downloaded_bytes = d.get('downloaded_bytes', 0)
                        percentage = (downloaded_bytes / total_bytes) * 100
                        progress_queue.put(download_pb2.DownloadStatusResponse(progress_percentage=percentage))
                except (TypeError, ZeroDivisionError):
                    pass

        ydl_opts = {
            'outtmpl': os.path.join("downloads", '%(title)s.%(ext)s'),
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best/bestvideo+bestaudio',
            'merge_output_format': 'mp4',
            'progress_hooks': [progress_hook],
            'ignoreerrors': False,
            'quiet': True,
            'no_warnings': True,
        }
        
        def download_thread_target():
            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    ydl.download([request.video_url])
                final_msg = f"Download de '{request.video_url}' concluído com sucesso."
                progress_queue.put(download_pb2.DownloadStatusResponse(final_message=final_msg))
            except Exception as e:
                error_msg = f"Erro ao baixar '{request.video_url}': {e}"
                progress_queue.put(download_pb2.DownloadStatusResponse(error_message=error_msg))
            finally:
                progress_queue.put(None)

        thread = threading.Thread(target=download_thread_target)
        thread.start()

        while True:
            item = progress_queue.get()
            if item is None:
                break
            yield item

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    download_pb2_grpc.add_DownloadServiceServicer_to_server(DownloadService(), server)
    port = '50052'
    server.add_insecure_port(f'[::]:{port}')
    server.start()
    
    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == '__main__':
    serve()