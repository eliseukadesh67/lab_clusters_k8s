## Inicializando o Web Client

1. Instale as Dependências

Execute o comando abaixo para instalar todas as dependências listadas no arquivo package.json:
´´´Bash
npm install
´´´

3. Configure as Variáveis de Ambiente

A aplicação precisa saber o endereço da API que ela vai consumir.

    Crie um arquivo chamado .env na raiz do projeto.

    Dentro deste arquivo, adicione a seguinte linha, substituindo pela URL real da sua API:

´´´Bash
API_URL=http://endereco-da-sua-api.com
´´´

4. Inicie o Servidor

Com tudo configurado, inicie o servidor com o seguinte comando:
´´´Bash
node app.js
´´´

Como alternativa, você pode adicionar um script start ao seu package.json e usar npm start.

5. Acesse a Aplicação

Com o servidor em execução, abra seu navegador de internet e acesse a seguinte URL:

http://localhost:3000