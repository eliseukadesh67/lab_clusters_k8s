import time
from locust import HttpUser, task, between
import random

# URL de um vídeo de exemplo que seu microsserviço de download deve conseguir processar.
# É CRUCIAL que esta URL seja válida para que o teste gere carga real no gRPC/I/O.
# VIDEO_URL = "https://example.com/some-test-video.mp4" 

# Lista de URLs de teste (para simular diferentes downloads)
TEST_URLS = [
    "https://www.youtube.com/watch?v=_-ywSPWu3K8",
    "https://www.youtube.com/watch?v=d_HlPboLRL8",
    "https://www.youtube.com/watch?v=evBgLWQwAFA",
]

# Assumindo que seu roteador Express tem a rota mapeada como '/download'
DOWNLOAD_ENDPOINT = "/download"
# METADATA_ENDPOINT = "/metadata"

class GatewayDownloadUser(HttpUser):
    # Tempo de espera aleatório entre 1 e 3 segundos entre requisições
    # Downloads são operações longas; um tempo de espera maior simula melhor o uso real.
    wait_time = between(1, 3)
    
    # Timeout mais longo para lidar com o streaming e I/O de disco do download.
    # O default pode ser 60s, mas downloads podem levar mais tempo.
    network_timeout = 180 

    @task(3) # Peso 3: Tarefa principal, mais frequente
    def initiate_video_download_stream(self):
        """
        Simula a chamada ao endpoint downloadVideo, que inicia o stream gRPC
        e a conexão SSE (que fica aberta até o download ser concluído).
        """
        # Escolhe uma URL aleatória da lista
        url_to_download = random.choice(TEST_URLS)
        
        # A URL completa para o Gateway deve ser: /download?url=<url_to_download>
        # Usamos 'name' para agrupar todas as requisições de download no relatório do Locust.
        response = self.client.get(
            f"{DOWNLOAD_ENDPOINT}?url={url_to_download}", 
            name=DOWNLOAD_ENDPOINT + "?url=[dynamic]",
            stream=True # Habilita o streaming para lidar com a conexão SSE/gRPC
        )
        
        # O Locust/requests aguardará até que o servidor feche a conexão SSE.
        # Não tentaremos analisar o stream SSE, apenas mediremos o tempo total da operação.
        if response.status_code == 200:
            print(f"Download iniciado e concluído com sucesso para: {url_to_download}")
        elif response.status_code == 400 and response.json().get('error'):
            print(f"Falha de validação (400): {response.json()['error']}")
            response.failure(f"Erro 400: {response.json()['error']}")
        else:
            response.failure(f"Download falhou. Status: {response.status_code}")
    
    #@task(1) # Peso 1: Simula chamadas de metadados menos frequentes
    #def get_video_metadata(self):
    #    """
    #    Simula a chamada ao endpoint getVideoMetadata.
    #    """
    #    url_for_metadata = VIDEO_URL
    #    
    #    self.client.get(
    #        f"{METADATA_ENDPOINT}?url={url_for_metadata}",
    #        name=METADATA_ENDPOINT + "?url=[static]"
    #    )