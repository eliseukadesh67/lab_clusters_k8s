import config from '../../config.js';

// 1. Importa o cliente gRPC já configurado e conectado do arquivo central.
//    Toda a lógica de carregar o .proto e conectar ao servidor já foi feita.
const grpcClient = config.clients.downloads.grpc;

/**
 * Busca os metadados de um vídeo.
 * Esta é uma chamada gRPC unária (requisição-resposta simples).
 * Envolvemos a chamada baseada em callback em uma Promise para facilitar o uso
 * com async/await no controller.
 * @param {object} payload - Ex: { video_url: '...' }
 * @returns {Promise<object>} Os metadados do vídeo.
 */
const getMetadata = (payload) => {
    return new Promise((resolve, reject) => {
        grpcClient.GetVideoMetadata(payload, (error, response) => {
            if (error) {
                return reject(error);
            }
            return resolve(response);
        });
    });
};

/**
 * Inicia o download de um vídeo e retorna o stream de progresso.
 * Esta é uma chamada gRPC de server-streaming.
 * A função NÃO retorna uma Promise. Ela retorna o objeto 'call' (o stream) diretamente.
 * @param {object} payload - Ex: { video_url: '...' }
 * @returns {grpc.ClientReadableStream} O objeto de stream para escutar os eventos.
 */
const download = (payload) => {
    console.log('[gRPC Client Download] Iniciando stream de download...');
    const call = grpcClient.DownloadVideo(payload);
    return call;
};

// Exporta um objeto com os dois métodos prontos para serem usados pelo controller.
export default {
    getMetadata,
    download,
};