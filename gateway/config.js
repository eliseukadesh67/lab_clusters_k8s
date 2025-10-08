import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';
import axios from 'axios';
import grpc from '@grpc/grpc-js';
import protoLoader from '@grpc/proto-loader';

// --- Helper para o caminho do arquivo em ES Modules ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PROTO_DIR = process.env.PROTO_DIR || path.join(__dirname, '..', 'proto');

// --- Função Auxiliar para criar Clientes gRPC ---
// Isso evita repetir o código de carregar o .proto para cada serviço
const createGrpcClient = (protoFileName, packageName, serviceName, grpcUrl) => {
    const PROTO_PATH = path.join(PROTO_DIR, protoFileName);
    
    const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
        keepCase: true, longs: String, enums: String, defaults: true, oneofs: true,
    });

    const protoDescriptor = grpc.loadPackageDefinition(packageDefinition);
    const service_proto = protoDescriptor[packageName];

    const client = new service_proto[serviceName](grpcUrl, grpc.credentials.createInsecure());
    console.log(`[gRPC Client ${serviceName}] Conectado a ${grpcUrl}`);
    return client;
};


const config = {
    server: {
        port: process.env.PORT || 3000,
    },
  
    clients: {
        playlists: {
            // Cliente REST (Axios) pré-configurado
            rest: axios.create({
                baseURL: process.env.PLAYLISTS_REST_URL,
                timeout: 5000,
            }),
            // Cliente gRPC pré-configurado
            grpc: createGrpcClient(
                'playlist.proto',
                'playlist',
                'PlaylistService',
                process.env.PLAYLISTS_GRPC_URL
            ),
        },
        downloads: {
            rest: axios.create({
                baseURL: process.env.DOWNLOADS_REST_URL,
                timeout: 10000,
            }),
            grpc: createGrpcClient(
                'download.proto',
                'download',
                'DownloadService',
                process.env.DOWNLOADS_GRPC_URL
            ),
        }
    }
};

console.log(`[REST Client Download Service ] Conectado a ${process.env.DOWNLOADS_REST_URL}`);
console.log(`[REST Client Playlists Service ] Conectado a ${process.env.PLAYLISTS_REST_URL}`);

export default config;