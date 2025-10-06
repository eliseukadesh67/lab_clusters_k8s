# Lab gRPC - Services

Este diretório contém as implementações dos serviços A e B em duas versões: **gRPC** (original) e **REST** (convertida).

## Estrutura do Projeto

```
services/
├── grpc/
│   ├── server_a/          # Service A - Playlist (gRPC) em Ruby
│   └── server_b/          # Service B - Download (gRPC) em Python
└── rest/
    ├── server_a/          # Service A - Playlist (REST) em Ruby/Sinatra
    └── server_b/          # Service B - Download (REST) em Python/Flask
```

## Visão Geral dos Serviços

### Service A - Playlist Service
Gerencia playlists e vídeos, armazenando informações em banco de dados SQLite3.

**Funcionalidades:**
- Criar, listar, buscar, editar e deletar playlists
- Adicionar, buscar e deletar vídeos em playlists
- Integração com Service B para obter metadados de vídeos

**Tecnologias:**
- **gRPC**: Ruby + Protocol Buffers
- **REST**: Ruby + Sinatra + JSON

### Service B - Download Service
Extrai metadados e faz download de vídeos do YouTube.

**Funcionalidades:**
- Extrair metadados de vídeos (título, duração, thumbnail)
- Download de vídeos com progresso em tempo real

**Tecnologias:**
- **gRPC**: Python + Protocol Buffers + yt-dlp
- **REST**: Python + Flask + yt-dlp + Server-Sent Events

## Comparação: gRPC vs REST

| Aspecto | gRPC | REST |
|---------|------|------|
| **Protocolo** | HTTP/2 | HTTP/1.1 |
| **Formato de dados** | Protocol Buffers (binário) | JSON (texto) |
| **Definição de API** | Arquivos `.proto` | Endpoints HTTP |
| **Streaming** | Nativo (4 tipos) | SSE (Server-Sent Events) |
| **Códigos de status** | gRPC status codes | HTTP status codes |
| **Performance** | Mais rápido (binário) | Mais lento (texto) |
| **Legibilidade** | Menos legível | Mais legível |
| **Ferramentas** | Requer ferramentas específicas | curl, Postman, navegadores |
| **Compatibilidade** | Requer suporte HTTP/2 | Universal |

## Como Executar

### Versão gRPC

#### Service B (Python)
```bash
cd grpc/server_b
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python download_server.py
```

#### Service A (Ruby)
```bash
cd grpc/server_a
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby playlist_server.rb
```

### Versão REST

#### Service B (Python/Flask)
```bash
cd rest/server_b
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 download_rest_server.py
```

#### Service A (Ruby/Sinatra)
```bash
cd rest/server_a
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby playlist_rest_server.rb
```

## Portas Utilizadas

| Serviço | gRPC | REST |
|---------|------|------|
| Service A (Playlist) | 50051 | 5001 |
| Service B (Download) | 50052 | 5002 |

## Testes

### Testar versão REST

#### Service B
```bash
cd rest/server_b
./test_download_api.sh
```

#### Service A
```bash
cd rest/server_a
./test_playlist_api.sh
```

### Testar versão gRPC

Consulte os READMEs específicos em cada diretório `grpc/server_a` e `grpc/server_b`.

## Comunicação entre Serviços

### gRPC
Service A faz chamadas gRPC para Service B usando stubs:
```ruby
@download_stub = Download::DownloadService::Stub.new('localhost:50052', :this_channel_is_insecure)
metadata = @download_stub.get_video_metadata(Download::DownloadRequest.new(video_url: url))
```

### REST
Service A faz chamadas HTTP para Service B:
```ruby
uri = URI('http://localhost:5002/metadata')
request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
request.body = { video_url: url }.to_json
response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
```

## Mapeamento de Endpoints

### Service A - Playlist

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

### Service B - Download

| gRPC RPC | REST Endpoint | Método HTTP |
|----------|---------------|-------------|
| GetVideoMetadata | /metadata | POST |
| DownloadVideo | /download | POST (SSE) |

## Mapeamento de Status Codes

| gRPC Status | HTTP Status | Uso |
|-------------|-------------|-----|
| OK | 200 OK | Operação bem-sucedida |
| OK (criação) | 201 Created | Recurso criado |
| OK (deleção) | 204 No Content | Recurso deletado |
| INVALID_ARGUMENT | 400 Bad Request | Dados inválidos |
| NOT_FOUND | 404 Not Found | Recurso não encontrado |
| ALREADY_EXISTS | 409 Conflict | Recurso já existe |
| INTERNAL | 500 Internal Server Error | Erro interno |

## Decisões de Design

### 1. Framework REST para Ruby
**Escolha:** Sinatra
**Motivo:** Leve, simples e adequado para APIs REST. Alternativa ao Rails que seria muito pesado para este caso de uso.

### 2. Framework REST para Python
**Escolha:** Flask
**Motivo:** Leve, bem documentado e com suporte nativo para Server-Sent Events via generators.

### 3. Streaming de Progresso
**gRPC:** Server-side streaming nativo
**REST:** Server-Sent Events (SSE)
**Motivo:** SSE é o padrão mais simples para streaming unidirecional em REST, alternativa ao WebSocket que seria mais complexo.

### 4. Estrutura de Diretórios
```
services/
  grpc/
    server_a/
    server_b/
  rest/
    server_a/
    server_b/
```
**Motivo:** Mantém as duas versões separadas e organizadas, facilitando comparação e manutenção.

### 5. Nomenclatura de Endpoints REST
Seguimos convenções RESTful:
- Recursos como substantivos no plural: `/playlists`, `/videos`
- Métodos HTTP semânticos: GET (leitura), POST (criação), PATCH (atualização parcial), DELETE (remoção)
- IDs na URL: `/playlists/:id`, `/videos/:id`

### 6. Formato de Resposta de Erro
```json
{
  "error": "Mensagem de erro descritiva"
}
```
**Motivo:** Simples, consistente e fácil de processar no cliente.

### 7. Códigos de Status HTTP
Usamos códigos semânticos apropriados:
- 200: Sucesso (GET, PATCH)
- 201: Criado (POST)
- 204: Sem conteúdo (DELETE)
- 400: Requisição inválida
- 404: Não encontrado
- 409: Conflito (duplicação)
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

- [Service A (gRPC) README](grpc/server_a/README.md)
- [Service B (gRPC) README](grpc/server_b/README.md)
- [Service A (REST) README](rest/server_a/README.md)
- [Service B (REST) README](rest/server_b/README.md)
