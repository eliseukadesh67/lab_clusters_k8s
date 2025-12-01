# Este Dockerfile assume que o build será executado de DENTRO da pasta services/playlist
FROM ruby:3.2-slim

ENV APP_HOME=/usr/src/app

ENV RUBYLIB=$APP_HOME

WORKDIR $APP_HOME

# Instala ferramentas de build
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential

# Copia os arquivos de dependência do diretório atual (.)
COPY Gemfile ./

RUN bundle config set --local path 'vendor/bundle'

RUN bundle install --jobs=4 --retry=3

# Copia todo o resto do código do diretório atual (.)
COPY . .

# Expõe as portas
EXPOSE 50051
EXPOSE 5001
EXPOSE 9464

CMD ["bundle", "exec" , "ruby", "-I", "." ,"playlist_rest_server.rb"]