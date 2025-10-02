import grpc
import sys
from tqdm import tqdm
import downloader_pb2
import downloader_pb2_grpc

def run_client(command: str, video_url: str):
    server_address = 'localhost:50052'
    
    with grpc.insecure_channel(server_address) as channel:
        stub = downloader_pb2_grpc.DownloaderServiceStub(channel)
        
        if command == "download":
            run_download(stub, video_url)
        elif command == "metadata":
            run_get_metadata(stub, video_url)
        else:
            print(f"Comando desconhecido: {command}")
            print_usage()

def run_download(stub, video_url):
    try:
        request = downloader_pb2.DownloadRequest(video_url=video_url)
        response_stream = stub.DownloadVideo(request)
        
        with tqdm(total=100, desc="Progresso", unit="%", bar_format="{l_bar}{bar}| {n:.1f}/{total:.0f}%") as pbar:
            for response in response_stream:
                status_type = response.WhichOneof('status')
                
                if status_type == 'progress_percentage':
                    pbar.n = round(response.progress_percentage, 1)
                    pbar.refresh()
                elif status_type == 'final_message':
                    pbar.n = 100
                    pbar.refresh()
                    print(f"\nSucesso: {response.final_message}")
                elif status_type == 'error_message':
                    pbar.close()
                    print(f"\n--> Erro: {response.error_message}")

    except grpc.RpcError as e:
        print(f"\n--> Falha na comunicação com o servidor: {e.details()}")

def run_get_metadata(stub, video_url):
    try:
        request = downloader_pb2.DownloadRequest(video_url=video_url)
        response = stub.GetVideoMetadata(request)
        duration_in_seconds = response.duration
        minutes, seconds = divmod(duration_in_seconds, 60)
        hours, minutes = divmod(minutes, 60)

        if hours > 0:
            duration_formatted = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        else:
            duration_formatted = f"{minutes:02d}:{seconds:02d}"

        print("\n--- Metadados do Vídeo ---")
        print(f"Título: {response.title}")
        print(f"Duração: {duration_formatted}")
        print(f"URL da Capa: {response.thumbnail_url}")
        print("--------------------------")

    except grpc.RpcError as e:
        print(f"\n--> Falha ao buscar metadados: {e.details()}")

def print_usage():
    print("Uso: python downloader_client.py <comando> <url_do_video>")
    print("Comandos:")
    print("  download   - Baixa o vídeo com barra de progresso.")
    print("  metadata   - Extrai os metadados (título, duração, capa) do vídeo.")
    sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print_usage()
        
    command_arg = sys.argv[1]
    video_link_arg = sys.argv[2]
    run_client(command_arg, video_link_arg)