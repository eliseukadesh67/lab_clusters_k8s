# Serviço B - Download gRPC Server

Este é um servidor gRPC em Python que gerencia o download de vídeos do YouTube com rastreamento de progresso em tempo real.

## Funcionalidades

### Download de Vídeos
- **Obter metadados** - Extrai informações do vídeo (título, duração, thumbnail) sem fazer download
- **Download com progresso** - Baixa vídeos com streaming de progresso em tempo real
- **Suporte a múltiplos formatos** - MP4, WebM, e outros formatos disponíveis
- **Qualidade otimizada** - Seleciona automaticamente a melhor qualidade disponível

### Recursos Técnicos
- **Streaming gRPC** - Progresso em tempo real via server-side streaming
- **Threading** - Downloads assíncronos sem bloquear o servidor
- **Tratamento de erros** - Respostas estruturadas para diferentes tipos de erro
- **FFmpeg integrado** - Conversão e merge automático de áudio/vídeo

## Pré-requisitos

- Python 3.8+
- FFmpeg instalado no sistema


## Instalação

1. Instale o FFmpeg
``` bash
sudo apt install ffmpeg
```
1. Crie um ambiente virtual:
```bash
python -m venv venv
source venv/bin/activate
```

1. Instale as dependências:
```bash
pip install -r requirements.txt
```

1. Na pasta `services/server-b` gere os arquivos proto:
```bash
python -m grpc_tools.protoc -I ../../proto --python_out=. --grpc_python_out=. ../../proto/downloader.proto
```

## Execução

### Servidor
```bash
python download_server.py
```
O servidor será iniciado na porta `50052`.

### Cliente

#### Obter metadados de um vídeo
```bash
python download_client.py metadata "https://www.youtube.com/watch?v=njC24ts24Pg"
```

**Saída esperada:**
```
--- Metadados do Vídeo ---
Título: gRPC in 5 minutes | Eric Anderson & Ivy Zhuang, Google
Duração: 05:00
URL da Capa: https://i.ytimg.com/vi_webp/njC24ts24Pg/maxresdefault.webp
--------------------------
```

#### Baixar vídeo com progresso
```bash
python download_client.py download "https://www.youtube.com/watch?v=gnchfOojMk4&t=5s"
```

**Saída esperada:**
```
Progresso:   0%|                                                         | 0.0/100
Progresso:  45%|████████████████████████                                 | 45.0/100
Progresso: 100%|█████████████████████████████████████████████████████████| 100.0/100
Sucesso: Download de 'https://www.youtube.com/watch?v=gnchfOojMk4&t=5s' concluído com sucesso.
```

## Estrutura do Projeto

```
server-b/
├── venv/                      # Ambiente virtual Python
├── downloads/                 # Diretório onde os vídeos são salvos
├── requirements.txt           # Dependências Python
├── download_server.py       # Implementação do servidor gRPC
├── download_client.py       # Cliente para testes
├── download_pb2.py          # Arquivos gerados do protobuf
├── download_pb2_grpc.py     # Serviços gRPC gerados
├── .gitignore                 # Arquivos ignorados pelo Git
└── README.md                  # Esta documentação
```

## Protocolo gRPC

O serviço utiliza o arquivo `download.proto` localizado em `../../proto/` que define:

### Serviços
- `DownloadService` - Serviço principal para download de vídeos

### RPCs
- `GetVideoMetadata` - Unary RPC que retorna metadados do vídeo
- `DownloadVideo` - Server-side streaming RPC que envia progresso em tempo real

### Mensagens
- **Requests**: `DownloadRequest`
- **Responses**: `VideoMetadataResponse`, `DownloadStatusResponse`

## Fluxo de Download

1. **Cliente envia URL** via `DownloadRequest`
2. **Servidor inicia download** em thread separada
3. **Progress streaming** - servidor envia atualizações de progresso (0-100%)
4. **Finalização** - servidor envia mensagem de sucesso ou erro

