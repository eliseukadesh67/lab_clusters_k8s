## Inicializando o Web Client

#### Instale as Dependências

Execute o comando abaixo para instalar todas as dependências listadas no arquivo package.json:

```bash
npm install
```

#### Configure as Variáveis de Ambiente


Crie um arquivo chamado .env na raiz do projeto. Dentro deste arquivo, adicione a seguinte linha, substituindo pela URL real da sua API:

```bash
API_URL=http://endereco-da-sua-api.com
```

#### Inicie o Servidor

Com tudo configurado, inicie o servidor com o seguinte comando:

```bash
node app.js
```

Como alternativa, você pode adicionar um script start ao seu package.json e usar npm start.

#### Acesse a Aplicação

Com o servidor em execução, abra seu navegador de internet e acesse a seguinte URL:

http://localhost:3000