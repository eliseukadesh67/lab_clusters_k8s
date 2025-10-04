# Etapa 1: Escolha da Imagem Base
# Usamos uma imagem oficial do Ruby. A versão 'slim' é menor, ideal para produção.
FROM ruby:3.2-slim

# Define variáveis de ambiente úteis
ENV APP_HOME=/usr/src/app
ENV BUNDLE_PATH=/bundle

# Cria o diretório da aplicação
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# Etapa 2: Instalação das Dependências (Gems)
# Copia apenas os arquivos de dependência primeiro. Isso aproveita o cache do Docker.
# Se o Gemfile não mudar, o Docker não reinstalará as gems em builds futuros.
COPY services/server-a/Gemfile services/server-a/Gemfile.lock ./

RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    bundle install --jobs=4 --retry=3 && \
    apt-get purge -y --auto-remove build-essential && \
    rm -rf /var/lib/apt/lists/*

# Etapa 3: Cópia do Código da Aplicação
# Com as dependências já instaladas, agora copiamos o restante do código.
COPY . .

# Etapa 4: Exposição da Porta
# Expõe a porta em que o seu servidor gRPC irá escutar.
# 50051 é uma porta comumente usada para serviços gRPC.
EXPOSE 50051

# Etapa 5: Comando de Execução
# Define o comando que será executado quando o contêiner iniciar.
CMD ["ruby", "playlist_server.rb"]