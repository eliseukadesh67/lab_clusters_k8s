# Service A - Playlist REST API Server

Este é um servidor REST API em Ruby/Sinatra que gerencia playlists e vídeos, integrando-se com o Service B para obter metadados dos vídeos.

## Funcionalidades

### Gerenciamento de Playlists
- **Criar playlist** - Cria uma nova playlist com nome único
- **Buscar playlist** - Obtém detalhes de uma playlist específica
- **Listar playlists** - Lista todas as playlists existentes
- **Editar playlist** - Modifica o nome de uma playlist
- **Deletar playlist** - Remove uma playlist do sistema

### Gerenciamento de Vídeos
- **Adicionar vídeo** - Adiciona um vídeo à playlist (requer Service B)
- **Buscar vídeo** - Obtém detalhes de um vídeo específico
- **Deletar vídeo** - Remove um vídeo da playlist

## Integração com Service B

O Service A se comunica com o Service B (Downloader) via REST API para obter metadados dos vídeos:
- **Título** do vídeo
- **Duração** em segundos
- **URL da thumbnail**

## Pré-requisitos

- Ruby 2.7+
- Bundler
- **Service B** rodando em `http://localhost:5002` (para funcionalidade de vídeos)

## Instalação

1. Instale as dependências localmente:
```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

## Execução

### Dependências de Serviços

1. **Primeiro, inicie o Service B (Downloader):**
```bash
# Em um terminal separado
cd ../server_b
source venv/bin/activate
python3 download_rest_server.py
```

2. **Depois, inicie o Service A (Playlist):**
```bash
ruby playlist_rest_server.rb
```

**📡 Status de Conexão:**
- Service A roda em `http://localhost:5001`
- Service B deve rodar em `http://localhost:5002`
- Comunicação via REST API entre os serviços

### Saída esperada:
```
============================================================
Service A - Playlist REST API Server
============================================================
Servidor iniciado em http://localhost:5001

Endpoints disponíveis:
  GET    /playlists        - Listar todas as playlists
  GET    /playlists/:id    - Buscar playlist por ID
  POST   /playlists        - Criar nova playlist
  PATCH  /playlists/:id    - Editar playlist
  DELETE /playlists/:id    - Deletar playlist
  GET    /videos/:id       - Buscar vídeo por ID
  POST   /videos           - Adicionar vídeo à playlist
  DELETE /videos/:id       - Deletar vídeo
  GET    /health           - Health check
============================================================

IMPORTANTE: Certifique-se de que o Service B está rodando em http://localhost:5002
============================================================
```

## API Endpoints

### Playlists

#### 1. Listar todas as playlists
```bash
GET /playlists
```

**Response (200 OK):**
```json
{
  "items": [
    {
      "id": "01HQXYZ...",
      "name": "Minha Playlist",
      "videos": [
        {
          "id": "01HQXYZ...",
          "url": "https://youtube.com/watch?v=...",
          "title": "Título do Vídeo",
          "duration": 300,
          "thumbnail_url": "https://...",
          "playlist_id": "01HQXYZ..."
        }
      ]
    }
  ]
}
```

#### 2. Buscar playlist por ID
```bash
GET /playlists/{id}
```

**Response (200 OK):**
```json
{
  "id": "01HQXYZ...",
  "name": "Minha Playlist",
  "videos": [...]
}
```

**Response (404 Not Found):**
```json
{
  "error": "Playlist com ID '01HQXYZ...' não encontrada."
}
```

#### 3. Criar nova playlist
```bash
POST /playlists
Content-Type: application/json

{
  "name": "Nova Playlist"
}
```

**Response (201 Created):**
```json
{
  "id": "01HQXYZ..."
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Nome da playlist é obrigatório."
}
```

**Response (409 Conflict):**
```json
{
  "error": "Playlist com nome 'Nova Playlist' já existe."
}
```

#### 4. Editar playlist
```bash
PATCH /playlists/{id}
Content-Type: application/json

{
  "name": "Nome Atualizado"
}
```

**Response (200 OK):**
```json
{
  "id": "01HQXYZ..."
}
```

**Response (404 Not Found):**
```json
{
  "error": "Playlist com ID '01HQXYZ...' não encontrada."
}
```

#### 5. Deletar playlist
```bash
DELETE /playlists/{id}
```

**Response (204 No Content):**
```
(corpo vazio)
```

**Response (404 Not Found):**
```json
{
  "error": "Playlist com ID '01HQXYZ...' não encontrada."
}
```

### Vídeos

#### 6. Buscar vídeo por ID
```bash
GET /videos/{id}
```

**Response (200 OK):**
```json
{
  "id": "01HQXYZ...",
  "url": "https://youtube.com/watch?v=...",
  "title": "Título do Vídeo",
  "duration": 300,
  "thumbnail_url": "https://...",
  "playlist_id": "01HQXYZ..."
}
```

**Response (404 Not Found):**
```json
{
  "error": "Vídeo com ID '01HQXYZ...' não encontrado."
}
```

#### 7. Adicionar vídeo à playlist
```bash
POST /videos
Content-Type: application/json

{
  "playlist_id": "01HQXYZ...",
  "url": "https://youtube.com/watch?v=..."
}
```

**Response (201 Created):**
```json
{
  "id": "01HQXYZ..."
}
```

**Response (404 Not Found):**
```json
{
  "error": "Playlist com ID '01HQXYZ...' não encontrada."
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Erro ao obter metadados do vídeo: ..."
}
```

**Response (409 Conflict):**
```json
{
  "error": "Vídeo com URL '...' já existe na playlist."
}
```

#### 8. Deletar vídeo
```bash
DELETE /videos/{id}
```

**Response (204 No Content):**
```
(corpo vazio)
```

**Response (404 Not Found):**
```json
{
  "error": "Vídeo não encontrado na playlist."
}
```

## Testando a API

### Usando o script de teste
```bash
./test_playlist_api.sh
```

### Usando curl manualmente

#### Criar playlist:
```bash
curl -X POST http://localhost:5001/playlists \
  -H "Content-Type: application/json" \
  -d '{"name": "Minha Playlist"}'
```

#### Listar playlists:
```bash
curl http://localhost:5001/playlists
```

#### Adicionar vídeo:
```bash
curl -X POST http://localhost:5001/videos \
  -H "Content-Type: application/json" \
  -d '{"playlist_id": "01HQXYZ...", "url": "https://www.youtube.com/watch?v=njC24ts24Pg"}'
```

## Estrutura do Projeto

```
server_a/
├── vendor/                    # Gems instaladas localmente (ignorado pelo Git)
├── Gemfile                    # Dependências Ruby
├── Gemfile.lock               # Versões fixas das dependências
├── playlist_rest_server.rb    # Implementação do servidor REST
├── playlist_repository.rb     # Camada de acesso ao banco de dados
├── test_playlist_api.sh       # Script de testes
├── playlists.db               # Banco de dados SQLite (criado automaticamente)
└── README.md                  # Esta documentação
```

## Banco de Dados

O sistema usa SQLite3 para armazenamento:

### Tabela `playlists`
- `id` (TEXT PRIMARY KEY) - ULID único
- `name` (TEXT NOT NULL UNIQUE) - Nome da playlist

### Tabela `videos`
- `id` (TEXT PRIMARY KEY) - ULID único
- `url` (TEXT NOT NULL) - URL do vídeo
- `title` (TEXT NOT NULL) - Título do vídeo
- `duration` (INTEGER NOT NULL) - Duração em segundos
- `thumbnail_url` (TEXT NOT NULL) - URL da thumbnail
- `playlist_id` (TEXT NOT NULL) - Referência à playlist
- UNIQUE(playlist_id, url) - Um vídeo não pode ser adicionado duas vezes à mesma playlist

## Diferenças em relação ao gRPC

### Comunicação
- **gRPC**: Usa Protocol Buffers e HTTP/2
- **REST**: Usa JSON e HTTP/1.1

### Endpoints
- **gRPC**: RPCs definidos em `.proto`
  - `GetPlaylists(Empty) returns (Playlists)`
  - `PostPlaylists(PlaylistInfo) returns (PlaylistId)`
- **REST**: Endpoints HTTP
  - `GET /playlists`
  - `POST /playlists`

### Integração entre Serviços
- **gRPC**: Chamadas gRPC diretas com stubs
  ```ruby
  metadata = @download_stub.get_video_metadata(Download::DownloadRequest.new(video_url: url))
  ```
- **REST**: Chamadas HTTP com JSON
  ```ruby
  uri = URI('http://localhost:5002/metadata')
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = { video_url: url }.to_json
  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  ```

### Códigos de Status
- **gRPC**: Status codes específicos (OK, NOT_FOUND, INVALID_ARGUMENT, ALREADY_EXISTS, etc.)
- **REST**: Códigos HTTP padrão (200, 201, 204, 400, 404, 409, 500, etc.)

### Tratamento de Erros
- **gRPC**: Exceções específicas (`GRPC::NotFound`, `GRPC::InvalidArgument`, etc.)
- **REST**: Respostas JSON com campo `error` e códigos HTTP apropriados

## Comunicação com Service B

Service A faz chamadas HTTP REST para Service B:

```ruby
def get_video_metadata_from_service_b(video_url)
  uri = URI("http://localhost:5002/metadata")
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = { video_url: video_url }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  if response.code == '200'
    JSON.parse(response.body, symbolize_names: true)
  else
    error_data = JSON.parse(response.body, symbolize_names: true)
    raise "Erro ao obter metadados do vídeo: #{error_data[:error]}"
  end
end
```

## Troubleshooting

### Erro: "Service B may not be running"
Certifique-se de que o Service B está rodando:
```bash
curl http://localhost:5002/health
```

### Erro: "Port 5001 already in use"
Mate o processo que está usando a porta:
```bash
lsof -ti:5001 | xargs kill -9
```

### Erro ao instalar gems
Tente limpar o cache e reinstalar:
```bash
bundle clean --force
bundle install
```
