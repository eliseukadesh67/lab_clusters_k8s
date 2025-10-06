# Usa uma versão LTS (Long Term Support) estável
FROM node:20-alpine

WORKDIR /app

ENV GATEWAY_PATH=gateway

# Copia os arquivos de dependência a partir da subpasta 'gateway' do contexto de build
COPY $GATEWAY_PATH/package*.json ./

# Instala as dependências de produção
RUN npm install

# Copia o resto do código da aplicação a partir da subpasta 'gateway'
COPY $GATEWAY_PATH .

# Copia a pasta de protos da raiz do contexto para uma pasta 'proto' na imagem
COPY proto/ ./proto/


RUN mkdir /app/temp_downloads

# 2. Dá a posse do diretório para o usuário 'node'
RUN chown node:node /app/temp_downloads

# Define o usuário para maior segurança
USER node

EXPOSE 3000

# O comando para iniciar o servidor
CMD [ "node", "server.js" ]