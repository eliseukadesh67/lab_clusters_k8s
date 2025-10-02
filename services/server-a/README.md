# Serviço A - Playlist gRPC Server

Este é um servidor gRPC em Ruby que gerencia playlists e vídeos, integrando-se com o Serviço B para obter metadados dos vídeos.

## Funcionalidades

### Gerenciamento de Playlists
- **Criar playlist** - Cria uma nova playlist com nome único
- **Buscar playlist** - Obtém detalhes de uma playlist específica
- **Listar playlists** - Lista todas as playlists existentes
- **Editar playlist** - Modifica o nome de uma playlist
- **Deletar playlist** - Remove uma playlist do sistema

### Gerenciamento de Vídeos
- **Adicionar vídeo** - Adiciona um vídeo à playlist (requer Serviço B)
- **Buscar vídeo** - Obtém detalhes de um vídeo específico
- **Listar vídeos** - Lista todos os vídeos de uma playlist
- **Deletar vídeo** - Remove um vídeo da playlist

## Integração com Serviço B

O Serviço A se comunica com o Serviço B (Downloader) para obter metadados dos vídeos:
- **Título** do vídeo
- **Duração** em segundos
- **URL da thumbnail**

## Pré-requisitos

- Ruby 2.7+
- Bundler
- **Serviço B** rodando na porta 50052 (para funcionalidade de vídeos)


## Instalação

1. Instale as dependências localmente, na pasta `services/server-a`:
```bash
# Arquivos para playlist
bundle exec grpc_tools_ruby_protoc -I ../../proto --ruby_out=. --grpc_out=. ../../proto/playlist.proto

# Arquivos para comunicação com Serviço B
bundle exec grpc_tools_ruby_protoc -I ../../proto --ruby_out=. --grpc_out=. ../../proto/download.proto
```

## Execução

### Dependências de Serviços

1. **Primeiro, inicie o Serviço B (Downloader):**
```bash
# Em um terminal separado
cd ../server-b
source venv/bin/activate
python download_server.py
```

2. **Depois, inicie o Serviço A (Playlist):**
```bash
bundle exec ruby -I . playlist_server.rb
```

**📡 Status de Conexão:**
- Serviço A roda na porta `50051`
- Serviço B deve rodar na porta `50052`
- Comunicação via gRPC entre os serviços

### Cliente

#### Operações de Playlist (sem dependência do Serviço B)
```bash
# Criar playlist
bundle exec ruby -I . playlist_client.rb create "Minha Playlist"

# Listar playlists
bundle exec ruby -I . playlist_client.rb list

# Buscar playlist
bundle exec ruby -I . playlist_client.rb get <playlist_id>

# Editar playlist
bundle exec ruby -I . playlist_client.rb edit <playlist_id> "Novo Nome"

# Deletar playlist
bundle exec ruby -I . playlist_client.rb delete <playlist_id>
```

#### Operações de Vídeo (requer Serviço B rodando)
```bash
# Adicionar vídeo (requer metadados do Serviço B)
bundle exec ruby -I . playlist_client.rb add_video <playlist_id> "https://youtube.com/watch?v=123"

# Listar vídeos
bundle exec ruby -I . playlist_client.rb list_videos <playlist_id>

# Buscar vídeo
bundle exec ruby -I . playlist_client.rb get_video <playlist_id> <video_id>

# Deletar vídeo
bundle exec ruby -I . playlist_client.rb delete_video <playlist_id> <video_id>
```

## Estrutura do Projeto

```
server-a/
├── vendor/                 # Gems instaladas localmente (ignorado pelo Git)
├── Gemfile                 # Dependências Ruby
├── Gemfile.lock            # Versões fixas das dependências
├── playlist_server.rb      # Implementação do servidor gRPC
├── playlist_client.rb      # Cliente para testes
├── playlist_pb.rb          # Arquivos gerados do protobuf (playlist)
├── playlist_services_pb.rb # Serviços gRPC gerados (playlist)
├── download_pb.rb          # Arquivos gerados do protobuf (download)
├── download_services_pb.rb # Serviços gRPC gerados (download)
└── README.md               # Esta documentação
```

## Protocolo gRPC

### Comunicação Interna
O Serviço A faz chamadas gRPC para o Serviço B:

```ruby
# Exemplo de comunicação entre serviços
metadata_request = Download::DownloadRequest.new(video_url: request.url)
metadata_response = download_stub.GetVideoMetadata(metadata_request)
```

### Serviços Expostos
- `PlaylistService` - Serviço principal com todos os RPCs

### RPCs Disponíveis
- `CreatePlaylist` - Cria uma nova playlist
- `GetPlaylist` - Obtém detalhes de uma playlist
- `ListPlaylists` - Lista todas as playlists
- `EditPlaylist` - Edita o nome de uma playlist
- `DeletePlaylist` - Remove uma playlist
- `AddVideo` - Adiciona vídeo à playlist (comunica com Serviço B)
- `GetVideo` - Obtém detalhes de um vídeo
- `ListVideos` - Lista vídeos de uma playlist
- `DeleteVideo` - Remove vídeo da playlist

### Mensagens
- **Requests**: `CreatePlaylistRequest`, `GetPlaylistRequest`, `AddVideoRequest`, etc.
- **Responses**: `PlaylistResponse`, `VideoResponse`, `ListPlaylistsResponse`, etc.
