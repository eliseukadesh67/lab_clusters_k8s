import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';  
import grpc from '@grpc/grpc-js';
import protoLoader from '@grpc/proto-loader';

import path from 'path';
import { fileURLToPath } from 'url';

// 1. Pega a URL do arquivo atual
const __filename = fileURLToPath(import.meta.url);

// 2. Pega o diretório a partir do caminho do arquivo
const __dirname = path.dirname(__filename);

const protoDirFromEnv = process.env.PROTO_DIR;

// 2. Se a variável não estiver definida, calcula o caminho padrão para o modo local.
//    '../proto' sobe um nível a partir de 'gateway/' e entra em 'proto/'.
const defaultProtoDir = path.join(__dirname, '..', 'proto');

// 3. Usa o caminho do ambiente se existir, senão, usa o padrão local.
const protoDir = protoDirFromEnv || defaultProtoDir;

const PROTO_PATH = path.join(protoDir, 'hello.proto');
const GRPC_HOST = process.env.GRPC_HOST || 'localhost';
const GRPC_PORT = 50051;

const packageDefinition = protoLoader.loadSync(
    PROTO_PATH,
    {
      keepCase: true,
      longs: String,
      enums: String,
      defaults: true,
      oneofs: true
    });

const hello_proto = grpc.loadPackageDefinition(packageDefinition).helloworld;

// Configurar Express
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Middleware para logging de requisições gRPC
const grpcLogger = (serviceName) => (req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${serviceName} API: ${req.method} ${req.path}`);
    next();
};

const grpcTarget = `${GRPC_HOST}:${GRPC_PORT}`;

const client = new hello_proto.Greeter(grpcTarget, grpc.credentials.createInsecure());

app.post('/hello', grpcLogger('Main'), (req, res) => {
  const { name } = req.body;
  
  client.sayHello({ name }, (err, response) => {
    if (err) {
      console.error('Erro na chamada gRPC:', err.details || err.message);
      return res.status(500).send('Error on Server A.');
    }

    // --- CORREÇÃO 2: Mover a lógica para dentro do callback ---
    console.log('Greeting:', response.message);
    // Agora 'response' existe e podemos enviar a mensagem para o cliente HTTP
    res.send(response.message);
  });
  
  // A linha res.send() foi removida daqui, pois agora está no lugar certo.
});

// Iniciar servidor
const server = app.listen(PORT, () => {
    console.log(`🚀 Gateway server running on port ${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received.');
  server.close(() => {
    console.log('Closed out remaining connections');
    console.log('Shutting down server...');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received.');
  server.close(() => {
    console.log('Closed out remaining connections');
    console.log('Shutting down server...');
    process.exit(0);
  });
});