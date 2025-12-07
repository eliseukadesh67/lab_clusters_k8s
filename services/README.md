# Lab gRPC - Services

Este diretório contém as implementações dos serviços usando **gRPC**.

## Estrutura do Projeto

```
services/
├── grpc/
│   ├── download/       # Service Download em Python
│   └── playlist/       # Service Playlist em Ruby
```

## Visão Geral dos Serviços

### Playlist Service
Gerencia playlists e vídeos, armazenando informações em banco de dados SQLite3.

**Funcionalidades:**
- Criar, listar, buscar, editar e deletar playlists
- Adicionar, buscar e deletar vídeos em playlists
- Integração com Service Download para obter metadados de vídeos

**Tecnologias:**
- Ruby + Protocol Buffers + gRPC

### Download Service
Extrai metadados e faz download de vídeos do YouTube.

**Funcionalidades:**
- Extrair metadados de vídeos (título, duração, thumbnail)
- Download de vídeos com progresso em tempo real

**Tecnologias:**
- Python + Protocol Buffers + gRPC + yt-dlp
| **Códigos de status** | gRPC status codes | HTTP status codes |
| **Performance** | Mais rápido (binário) | Mais lento (texto) |
| **Legibilidade** | Menos legível | Mais legível |
| **Ferramentas** | Requer ferramentas específicas | curl, Postman, navegadores |
| **Compatibilidade** | Requer suporte HTTP/2 | Universal |

## Como Executar

### Download Service (Python)
```bash
cd services/grpc/download
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python download_server.py
```

### Playlist Service (Ruby)
```bash
cd services/grpc/playlist
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby playlist_server.rb
```

## Portas Utilizadas

| Serviço | Porta gRPC |
|---------|------------|
| Service Playlist | 50051 |
| Service Download | 50052 |

## Testes

Consulte os READMEs específicos em cada diretório `services/grpc/download` e `services/grpc/playlist`.

## Comunicação entre Serviços

Service Playlist faz chamadas gRPC para Service Download usando stubs:
```ruby
@download_stub = Download::DownloadService::Stub.new('localhost:50052', :this_channel_is_insecure)
metadata = @download_stub.get_video_metadata(Download::DownloadRequest.new(video_url: url))
```

## Mapeamento de Endpoints

### Service Playlists

| gRPC RPC | REST Endpoint | Método HTTP |
|----------|---------------|-------------|
| GetPlaylists | /playlists | GET |
| GetPlaylistsById | /playlists/:id | GET |
| PostPlaylists | /playlists | POST |
| PatchPlaylists | /playlists/:id | PATCH |
| DeletePlaylists | /playlists/:id | DELETE |
| GetVideosById | /videos/:id | GET |
| PostVideos | /videos | POST |
| DeleteVideos | /videos/:id | DELETE |

### Service Download

| gRPC RPC | REST Endpoint | Método HTTP |
|----------|---------------|-------------|
| GetVideoMetadata | /metadata | POST |
| DownloadVideo | /download | POST (SSE) |

## Decisões de Design

### 1. Protocolo gRPC
**Escolha:** gRPC com Protocol Buffers
**Motivo:** Alta performance, tipagem forte e suporte nativo a streaming.

### 2. Streaming de Progresso
Server-side streaming nativo do gRPC para downloads com progresso em tempo real.

### 3. Estrutura de Diretórios
```
services/
├── grpc/
│   ├── download/
│   │   ├── Dockerfile
│   │   ├── download_server.py
│   │   ├── requirements.txt
│   │   └── ...
│   └── playlist/
│       ├── Dockerfile
│       ├── playlist_server.rb
│       ├── Gemfile
│       └── ...
```
**Motivo:** Organização clara dos serviços por linguagem e protocolo.
- 500: Erro interno

## Funcionalidades Mantidas

Todas as funcionalidades da versão gRPC foram mantidas na versão REST:

✅ Gerenciamento completo de playlists (CRUD)
✅ Gerenciamento completo de vídeos (CRD)
✅ Integração entre Service A e Service B
✅ Extração de metadados de vídeos do YouTube
✅ Download de vídeos com progresso em tempo real
✅ Validação de dados
✅ Tratamento de erros
✅ Persistência em SQLite3
✅ IDs únicos (ULID)
✅ Constraints de unicidade (nome de playlist, URL de vídeo por playlist)

## Requisitos do Sistema

### Para versão gRPC
- Ruby 2.7+
- Python 3.8+
- FFmpeg
- Bundler
- Protocol Buffers compiler

### Para versão REST
- Ruby 2.7+
- Python 3.8+
- FFmpeg
- Bundler
- build-essential (para compilar extensões nativas do Ruby)

## Troubleshooting

### Porta já em uso
```bash
# Matar processo na porta 5001
lsof -ti:5001 | xargs kill -9

# Matar processo na porta 5002
lsof -ti:5002 | xargs kill -9
```

### Service B não responde
Verifique se está rodando:
```bash
curl http://localhost:5002/health
```

### Erro ao instalar gems Ruby
```bash
sudo apt install build-essential ruby-dev
```

### Erro ao extrair metadados de vídeo
Verifique se a URL é válida e o vídeo está acessível.

## Documentação Adicional

- [Service Playlist (gRPC) README](playlist/gpc_service/README.md)
- [Service Download (gRPC) README](download/grpc_services/README.md)
- [Service Playlist (REST) README](playlist/rest_service/README.md)
- [Service Download (REST) README](download/grpc_service/README.md)
