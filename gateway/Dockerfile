# gateway/Dockerfile (CORRIGIDO)

FROM node:24-alpine

WORKDIR /app

# CORREÇÃO: Especifique o caminho a partir da raiz do contexto.
# Copie os arquivos de 'gateway/' para o diretório de trabalho atual '/app'
COPY gateway/package*.json ./

# CORREÇÃO: Copie a pasta 'proto' para uma subpasta 'proto' dentro de '/app'
COPY proto ./proto/

# Update npm version
RUN npm install -g npm@11.6.1

RUN npm install

COPY gateway/ ./

# Mudar propriedade dos arquivos
RUN chown -R node:node /app

USER node

# Expor porta
EXPOSE 3000

# Comando para executar a aplicação
CMD ["npm", "start"]