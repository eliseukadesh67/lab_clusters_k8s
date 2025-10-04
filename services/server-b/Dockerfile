FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements e instalar dependências Python
COPY services/server-b/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código da aplicação
COPY services/server-b/ .

# Expor porta do gRPC
EXPOSE 50052

# Comando para executar o servidor
CMD ["python", "download_server.py"]
