import grpc
import os
import yt_dlp
from concurrent import futures
import threading
import queue
import time
import download_pb2
import download_pb2_grpc
import logging

logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Cria o diretório de downloads se não existir
if not os.path.exists('downloads'):
    os.makedirs('downloads')

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
            logging.info(f"[GetMetadata] extraction time: {elapsed:.3f}s for url: {request.url}")
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

        # --- MUDANÇA 1: O hook agora também pega o total de bytes ---
        def progress_hook(d):
            if d['status'] == 'downloading':
                try:
                    downloaded_bytes = d.get('downloaded_bytes', 0)
                    total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                    
                    progress_queue.put(download_pb2.DownloadChunk(
                        progress=download_pb2.ProgressUpdate(
                            bytes_downloaded=int(downloaded_bytes),
                            total_bytes=int(total_bytes)
                        )
                    ))
                except (TypeError, ValueError):
                    pass

        ydl_opts = {
            'outtmpl': os.path.join("downloads", '%(id)s.%(ext)s'), # Usar ID para nome de arquivo previsível
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best/bestvideo+bestaudio',
            'merge_output_format': 'mp4',
            'progress_hooks': [progress_hook],
            'ignoreerrors': False,
            'quiet': True,
            'no_warnings': True,
        }
        
        # --- MUDANÇA 2: A lógica da thread foi reestruturada ---
        def download_thread_target():
            filepath = None
            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    logging.info(f"[yt-dlp] Iniciando download para: {request.url}")
                    # Extrai informações para obter o nome do arquivo final
                    info = ydl.extract_info(request.url, download=True)
                    filepath = ydl.prepare_filename(info)
                    
                logging.info(f"[yt-dlp] Download concluído. Arquivo: {filepath}")
                logging.info(f"[gRPC] Iniciando streaming do arquivo para o cliente.")

                # Agora, envia o arquivo em pedaços (chunks)
                chunk_size = 1024 * 1024  # 1 MB
                with open(filepath, 'rb') as f:
                    while True:
                        chunk_data = f.read(chunk_size)
                        if not chunk_data:
                            break # Fim do arquivo
                        # Coloca o pedaço de dados do arquivo na fila
                        progress_queue.put(download_pb2.DownloadChunk(data=chunk_data))

                logging.info(f"[gRPC] Streaming concluído.")

            except Exception as e:
                logging.info(f"[yt-dlp] Erro durante o processo: {e}")
                progress_queue.put(DownloadThreadError(f"Falha no processo: {e}"))
            finally:
                # Garante que o arquivo seja deletado, mesmo se ocorrer um erro
                if filepath and os.path.exists(filepath):
                    try:
                        os.remove(filepath)
                        logging.info(f"[System] Arquivo temporário removido: {filepath}")
                    except OSError as e:
                        logging.info(f"Erro ao remover arquivo {filepath}: {e}")
                # Sinaliza que a thread terminou
                progress_queue.put(None)

        thread = threading.Thread(target=download_thread_target, daemon=True)
        thread.start()

        while True:
            item = progress_queue.get()
            if item is None:
                break
            
            if isinstance(item, DownloadThreadError):
                context.set_code(grpc.StatusCode.INTERNAL)
                context.set_details(str(item))
                raise item

            # Envia o item (seja progresso ou chunk de dados) para o cliente
            yield item

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    download_pb2_grpc.add_DownloadServiceServicer_to_server(DownloadService(), server)
    port = '50052'
    server.add_insecure_port(f'[::]:{port}')
    server.start()
    logging.info(f"✅ Servidor gRPC rodando na porta {port}")
    try:
        server.wait_for_termination()
    except KeyboardInterrupt:
        server.stop(0)
        
if __name__ == '__main__':
  serve()