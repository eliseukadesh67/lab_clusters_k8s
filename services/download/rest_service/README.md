# Service B - Download REST API Server

Este é um servidor REST API em Python/Flask que gerencia o download de vídeos do YouTube com rastreamento de progresso em tempo real.

## Funcionalidades

### Extração de Metadados
- **Obter metadados** - Extrai informações do vídeo (título, duração, thumbnail) sem fazer download

### Download de Vídeos
- **Download com progresso** - Baixa vídeos com streaming de progresso em tempo real via Server-Sent Events (SSE)
- **Suporte a múltiplos formatos** - MP4, WebM, e outros formatos disponíveis
- **Qualidade otimizada** - Seleciona automaticamente a melhor qualidade disponível

### Recursos Técnicos
- **Server-Sent Events (SSE)** - Progresso em tempo real via streaming HTTP
- **Threading** - Downloads assíncronos sem bloquear o servidor
- **Tratamento de erros** - Respostas estruturadas para diferentes tipos de erro
- **FFmpeg integrado** - Conversão e merge automático de áudio/vídeo

## Pré-requisitos

- Python 3.8+
- FFmpeg instalado no sistema

## Instalação

1. Instale o FFmpeg:
```bash
sudo apt install ffmpeg
```

2. Crie um ambiente virtual:
```bash
python3 -m venv venv
source venv/bin/activate
```

3. Instale as dependências:
```bash
pip install -r requirements.txt
```

## Execução

### Servidor
```bash
python3 download_rest_server.py
```

O servidor será iniciado em `http://localhost:5002`.

### Saída esperada:
```
============================================================
Service B - Download REST API Server
============================================================
Servidor iniciado em http://localhost:5002

Endpoints disponíveis:
  POST /metadata  - Obter metadados do vídeo
  POST /download  - Baixar vídeo com progresso (SSE)
  GET  /health    - Health check
============================================================
```

## API Endpoints

### 1. Health Check
```bash
GET /health
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "service": "download-service"
}
```

### 2. Obter Metadados do Vídeo
```bash
POST /metadata
Content-Type: application/json

{
  "video_url": "https://www.youtube.com/watch?v=njC24ts24Pg"
}
```

**Response (200 OK):**
```json
{
  "title": "gRPC in 5 minutes | Eric Anderson & Ivy Zhuang, Google",
  "duration": 300,
  "thumbnail_url": "https://i.ytimg.com/vi_webp/njC24ts24Pg/maxresdefault.webp"
}
```

**Response (400 Bad Request):**
```json
{
  "error": "video_url é obrigatório"
}
```

**Response (404 Not Found):**
```json
{
  "error": "Não foi possível extrair metadados: ..."
}
```

### 3. Baixar Vídeo com Progresso
```bash
POST /download
Content-Type: application/json

{
  "video_url": "https://www.youtube.com/watch?v=gnchfOojMk4"
}
```

**Response (200 OK) - Server-Sent Events:**
```
Content-Type: text/event-stream

data: {"type": "progress", "percentage": 0.0}

data: {"type": "progress", "percentage": 45.5}

data: {"type": "progress", "percentage": 100.0}

data: {"type": "success", "message": "Download de '...' concluído com sucesso."}
```

**Response (400 Bad Request):**
```json
{
  "error": "video_url é obrigatório"
}
```

**Em caso de erro durante o download (SSE):**
```
data: {"type": "error", "message": "Erro ao baixar '...': ..."}
```

## Testando a API

### Usando o script de teste
```bash
./test_download_api.sh
```

### Usando curl manualmente

#### Obter metadados:
```bash
curl -X POST http://localhost:5002/metadata \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://www.youtube.com/watch?v=njC24ts24Pg"}'
```

#### Baixar vídeo com progresso:
```bash
curl -N -X POST http://localhost:5002/download \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://www.youtube.com/watch?v=njC24ts24Pg"}'
```

### Usando Python requests

#### Obter metadados:
```python
import requests

response = requests.post(
    'http://localhost:5002/metadata',
    json={'video_url': 'https://www.youtube.com/watch?v=njC24ts24Pg'}
)
print(response.json())
```

#### Baixar vídeo com progresso:
```python
import requests
import json

response = requests.post(
    'http://localhost:5002/download',
    json={'video_url': 'https://www.youtube.com/watch?v=njC24ts24Pg'},
    stream=True
)

for line in response.iter_lines():
    if line:
        line = line.decode('utf-8')
        if line.startswith('data: '):
            data = json.loads(line[6:])
            print(data)
```

## Estrutura do Projeto

```
server_b/
├── venv/                      # Ambiente virtual Python
├── downloads/                 # Diretório onde os vídeos são salvos
├── requirements.txt           # Dependências Python
├── download_rest_server.py    # Implementação do servidor REST
├── test_download_api.sh       # Script de testes
└── README.md                  # Esta documentação
```

## Diferenças em relação ao gRPC

### Comunicação
- **gRPC**: Usa Protocol Buffers e HTTP/2
- **REST**: Usa JSON e HTTP/1.1

### Streaming de Progresso
- **gRPC**: Server-side streaming nativo
- **REST**: Server-Sent Events (SSE) para streaming unidirecional

### Endpoints
- **gRPC**: RPCs definidos em `.proto`
  - `GetVideoMetadata(DownloadRequest) returns (VideoMetadataResponse)`
  - `DownloadVideo(DownloadRequest) returns (stream DownloadStatusResponse)`
- **REST**: Endpoints HTTP
  - `POST /metadata`
  - `POST /download`

### Códigos de Status
- **gRPC**: Status codes específicos (OK, NOT_FOUND, INVALID_ARGUMENT, etc.)
- **REST**: Códigos HTTP padrão (200, 400, 404, 500, etc.)

## Integração com Service A

O Service A (Playlist) faz chamadas HTTP para este serviço:

```ruby
# Service A chamando Service B
require 'net/http'
require 'json'

uri = URI('http://localhost:5002/metadata')
request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
request.body = { video_url: url }.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.code == '200'
  metadata = JSON.parse(response.body)
  # Usar metadata['title'], metadata['duration'], metadata['thumbnail_url']
end
```

## Troubleshooting

### Erro: "FFmpeg not found"
Instale o FFmpeg:
```bash
sudo apt install ffmpeg
```

### Erro: "Port 5002 already in use"
Mate o processo que está usando a porta:
```bash
lsof -ti:5002 | xargs kill -9
```

### Erro ao extrair metadados
Verifique se a URL do vídeo é válida e acessível.
