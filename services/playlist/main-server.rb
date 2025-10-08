protocol = ENV['PROTOCOL']

case protocol
when 'rest'
  puts "==> Iniciando servidor REST (Sinatra)..."
  require_relative 'rest_service/playlist_rest_server'

  puts "=" * 60
  puts "Service Playlist - REST API Server"
  puts "=" * 60
  puts "Servidor iniciado em http://localhost:5001"
  puts ""
  puts "Endpoints disponíveis:"
  puts "  GET    /playlists        - Listar todas as playlists"
  puts "  GET    /playlists/:id    - Buscar playlist por ID"
  puts "  POST   /playlists        - Criar nova playlist"
  puts "  PATCH  /playlists/:id    - Editar playlist"
  puts "  DELETE /playlists/:id    - Deletar playlist"
  puts "  GET    /videos/:id       - Buscar vídeo por ID"
  puts "  POST   /videos           - Adicionar vídeo à playlist"
  puts "  DELETE /videos/:id       - Deletar vídeo"
  puts "  GET    /health           - Health check"
  puts "=" * 60
  puts ""
  puts "IMPORTANTE: Certifique-se de que o Service Download está rodando em #{DOWNLOAD_SERVICE_URL}"
  puts "=" * 60

  PlaylistApp.run!

when 'grpc'
  puts "==> Iniciando servidor gRPC..."
  require_relative 'grpc_service/playlist_services'
  
  GrpcRunner.start

else
  puts "ERRO: Variável de ambiente 'protocol' não definida ou inválida."
  puts "Use 'rest' ou 'grpc'."
  exit 1 # Termina o script com um código de erro
end