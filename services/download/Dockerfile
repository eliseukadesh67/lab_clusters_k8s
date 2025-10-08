FROM python:3.11-slim

WORKDIR /app

# Atualiza os pacotes e instala o ffmpeg
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Copia o arquivo de dependências do Python a partir da subpasta 'playlist-service'
COPY requirements.txt .

# Instala as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do código da aplicação a partir da subpasta 'playlist-service'
COPY . .

# Expõe as portas gRPC e HTTP
EXPOSE 50052
EXPOSE 5002

CMD ["python", "main_server.py"]