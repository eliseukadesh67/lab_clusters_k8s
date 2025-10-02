import grpc
import sys
from tqdm import tqdm
import downloader_pb2
import downloader_pb2_grpc

def run_client(video_url: str):
    server_address = 'localhost:50052'
    
    with grpc.insecure_channel(server_address) as channel:
        stub = downloader_pb2_grpc.DownloaderServiceStub(channel)
        
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
                        print(f"\n✅ Sucesso: {response.final_message}")
                    elif status_type == 'error_message':
                        pbar.close()
                        print(f"\n--> Erro: {response.error_message}")

        except grpc.RpcError as e:
            print(f"\n--> Falha na comunicação com o servidor: {e.details()}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python downloader_client.py <url_do_video>")
        sys.exit(1)
        
    run_client(sys.argv[1])