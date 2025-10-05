import grpc
import sys
import os
from tqdm import tqdm
import download_pb2
import download_pb2_grpc

def run_client(command: str, video_url: str):
    server_address = 'localhost:50052'
    
    with grpc.insecure_channel(server_address) as channel:
        stub = download_pb2_grpc.DownloadServiceStub(channel)
        
        if command == "download":
            run_download(stub, video_url)
        elif command == "metadata":
            run_get_metadata(stub, video_url)
        else:
            print(f"Comando desconhecido: {command}")
            print_usage()

def run_download(stub, video_url):
    try:
        request = download_pb2.Request(url=video_url)
        response_stream = stub.GetFile(request)

        metadata_request = download_pb2.Request(url=video_url)
        try:
            metadata = stub.GetMetadata(metadata_request)
            total_bytes = metadata.total_bytes
            print(f"Iniciando download: {metadata.title}")
        except:
            total_bytes = 0
            print("Iniciando download...")
        
        bytes_downloaded = 0
        output_file = None
        
        if total_bytes > 0:
            pbar = tqdm(total=total_bytes, unit='B', unit_scale=True, desc="Download")
        else:
            pbar = tqdm(unit='B', unit_scale=True, desc="Download")
        
        try:
            for chunk in response_stream:
                payload_type = chunk.WhichOneof('payload')
                
                if payload_type == 'progress':
                    new_bytes = chunk.progress.bytes_downloaded
                    if new_bytes > bytes_downloaded:
                        bytes_downloaded = new_bytes
                        if total_bytes > 0:
                            pbar.n = bytes_downloaded
                        else:
                            pbar.update(new_bytes - pbar.n)
                        pbar.refresh()
                        
                elif payload_type == 'data':
                    if output_file is None:
                        output_filename = f"downloaded_video_{hash(video_url) % 10000}.mp4"
                        os.makedirs("client_downloads", exist_ok=True)
                        output_file = open(os.path.join("client_downloads", output_filename), 'wb')
                        print(f"\nSalvando como: {output_filename}")
                    
                    output_file.write(chunk.data)
        
                    if total_bytes == 0:
                        pbar.update(len(chunk.data))
            
            pbar.close()
            
            if output_file:
                output_file.close()
                print(f"\nDownload concluído! Arquivo salvo em: client_downloads/{output_filename}")
            else:
                print("\nNenhum dado de arquivo foi recebido.")
                
        except Exception as e:
            pbar.close()
            if output_file:
                output_file.close()
            print(f"\nErro durante o download: {e}")

    except grpc.RpcError as e:
        print(f"\nFalha na comunicação com o servidor: {e.details()}")

def run_get_metadata(stub, video_url):
    try:
        request = download_pb2.Request(url=video_url)
        response = stub.GetMetadata(request)
        
        duration_in_seconds = response.duration
        minutes, seconds = divmod(duration_in_seconds, 60)
        hours, minutes = divmod(minutes, 60)

        if hours > 0:
            duration_formatted = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        else:
            duration_formatted = f"{minutes:02d}:{seconds:02d}"

        total_bytes = response.total_bytes
        if total_bytes > 0:
            if total_bytes >= 1024**3:  # GB
                size_formatted = f"{total_bytes / (1024**3):.2f} GB"
            elif total_bytes >= 1024**2:  # MB
                size_formatted = f"{total_bytes / (1024**2):.2f} MB"
            elif total_bytes >= 1024:  # KB
                size_formatted = f"{total_bytes / 1024:.2f} KB"
            else:
                size_formatted = f"{total_bytes} bytes"
        else:
            size_formatted = "Tamanho desconhecido"

        print("\n--- Metadados do Vídeo ---")
        print(f"Título: {response.title}")
        print(f"Duração: {duration_formatted}")
        print(f"Tamanho estimado: {size_formatted}")
        print(f"URL da Capa: {response.thumbnail_url}")
        print("--------------------------")

    except grpc.RpcError as e:
        print(f"\nFalha ao buscar metadados: {e.details()}")

def print_usage():
    print("Uso: python download_client.py <comando> <url_do_video>")
    print("Comandos:")
    print("  download   - Baixa o vídeo com barra de progresso.")
    print("  metadata   - Extrai os metadados (título, duração, capa) do vídeo.")
    print("\nExemplos:")
    print("  python download_client.py metadata 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'")
    print("  python download_client.py download 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'")
    sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print_usage()
        
    command_arg = sys.argv[1]
    video_link_arg = sys.argv[2]
    run_client(command_arg, video_link_arg)