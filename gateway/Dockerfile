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

# Instalar dependências (agora vai funcionar!)
RUN npm ci --omit=dev

# CORREÇÃO: Copie apenas o código da aplicação que está na pasta 'gateway'
# para o diretório de trabalho atual '/app'.
COPY gateway/ ./

ARG USERNAME=nodejs
ARG USERUID=1001
ARG USERGID=$USERUID

# Criar usuário não-root
RUN addgroup -g $USERGID -S $USERNAME
RUN adduser -S $USERNAME -u $USERUID

# Mudar propriedade dos arquivos
RUN chown -R $USERNAME:$USERNAME /app
USER node

# Expor porta
EXPOSE 3000

# Comando para executar a aplicação
CMD ["npm", "start"]