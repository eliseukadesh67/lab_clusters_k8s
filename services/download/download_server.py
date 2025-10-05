import grpc
import os
import yt_dlp
from concurrent import futures
import threading
import queue
import time
import download_pb2
import download_pb2_grpc

class DownloadThreadError(Exception):
    pass

class DownloadService(download_pb2_grpc.DownloadServiceServicer):

    def GetMetadata(self, request, context):
        start = time.time()
        ydl_opts = {'quiet': True, 'no_warnings': True}
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info_dict = ydl.extract_info(request.url, download=False)
            title = info_dict.get('title', 'N/A')
            duration = int(info_dict.get('duration', 0) or 0)
            thumbnail_url = info_dict.get('thumbnail', '')
            total_bytes = int(info_dict.get('filesize') or info_dict.get('filesize_approx') or 0)
            elapsed = time.time() - start
            print(f"[GetMetadata] extraction time: {elapsed:.3f}s for url: {request.url}")
            try:
                context.set_trailing_metadata((('extraction-time-seconds', f"{elapsed:.3f}"),))
            except Exception:
                pass
            return download_pb2.Metadata(
                title=title,
                duration=duration,
                thumbnail_url=thumbnail_url,
                total_bytes=total_bytes
            )
        except Exception as e:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details(f"Não foi possível extrair metadados: {e}")
            return download_pb2.Metadata()

    def GetFile(self, request, context):
        progress_queue = queue.Queue()

        def progress_hook(d):
            status = d.get('status')
            if status == 'downloading':
                try:
                    downloaded_bytes = d.get('downloaded_bytes') or d.get('tmpfilesize') or 0
                    progress_queue.put(download_pb2.DownloadChunk(
                        progress=download_pb2.ProgressUpdate(bytes_downloaded=int(downloaded_bytes))
                    ))
                except (TypeError, ValueError):
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
                    print(f"[yt-dlp] Iniciando download para: {request.url}")
                    ydl.download([request.url])
                # Sinal de sucesso
                progress_queue.put(download_pb2.DownloadChunk(
                    progress=download_pb2.ProgressUpdate(bytes_downloaded=-1)
                ))
            except Exception as e:
                # --- MUDANÇA 1: Colocar o objeto de erro na fila ---
                print(f"[yt-dlp] Erro durante o download: {e}")
                progress_queue.put(DownloadThreadError(f"Falha no download com yt-dlp: {e}"))
            finally:
                # Sinaliza que a thread terminou
                progress_queue.put(None)

        thread = threading.Thread(target=download_thread_target, daemon=True)
        thread.start()

        while True:
            item = progress_queue.get()
            if item is None:
                break
            
            # --- MUDANÇA 2: Verificar se o item é um erro e levantá-lo ---
            # Isso fará com que o gRPC encerre a chamada com um status de erro
            if isinstance(item, DownloadThreadError):
                context.set_code(grpc.StatusCode.INTERNAL)
                context.set_details(str(item))
                # Levantar a exceção interrompe o 'yield' e finaliza o RPC com erro
                raise item

            # Se não for um erro, envia o chunk de dados normalmente
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