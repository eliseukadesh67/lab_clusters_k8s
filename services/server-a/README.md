# Serviço A - Playlist gRPC Server

Este é um servidor gRPC em Ruby que gerencia playlists e vídeos.

## Funcionalidades

### Gerenciamento de Playlists
- **Criar playlist** - Cria uma nova playlist com nome único
- **Buscar playlist** - Obtém detalhes de uma playlist específica
- **Listar playlists** - Lista todas as playlists existentes
- **Editar playlist** - Modifica o nome de uma playlist
- **Deletar playlist** - Remove uma playlist do sistema

### Gerenciamento de Vídeos
- **Adicionar vídeo** - Adiciona um vídeo à playlist
- **Buscar vídeo** - Obtém detalhes de um vídeo específico
- **Listar vídeos** - Lista todos os vídeos de uma playlist
- **Deletar vídeo** - Remove um vídeo da playlist

## Pré-requisitos

- Ruby 2.7+
- Bundler

## Instalação

1. Instale as dependências:
```bash
bundle install
```

2. Na pasta `services/server-a` gere os arquivos proto:
```bash
bundle exec grpc_tools_ruby_protoc -I ../../proto --ruby_out=. --grpc_out=. ../../proto/playlist.proto
```

## Execução

### Servidor
```bash
bundle exec ruby -I . playlist_server.rb
```
O servidor será iniciado na porta `50051`.

### Cliente


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

# Adicionar vídeo
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
├── Gemfile                 # Dependências Ruby
├── Gemfile.lock            # Versões fixas das dependências
├── playlist_server.rb      # Implementação do servidor gRPC
├── playlist_client.rb      # Cliente para testes
├── playlist_pb.rb          # Arquivos gerados do protobuf
├── playlist_services_pb.rb # Serviços gRPC gerados
└── README.md               # Esta documentação
```

## Protocolo gRPC

### Serviços
- `PlaylistService` - Serviço principal com todos os RPCs

### Mensagens
- Requests: `CreatePlaylistRequest`, `GetPlaylistRequest`, etc.
- Responses: `PlaylistResponse`, `VideoResponse`, etc.
