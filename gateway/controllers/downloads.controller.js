import gRpcDownloadClient from '../clients/downloadClient/grpc.client.js';
import restDownloadClient from '../clients/downloadClient/rest.client.js';

const getClient = (req) => (req.headers['x-communication-protocol'] === 'grpc' ? gRpcDownloadClient : restDownloadClient);

// GET /downloads/metadata?url=...
const getVideoMetadata = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { url } = req.query;
        if (!url) {
            return res.status(400).json({ error: 'Query parameter "url" é obrigatório.' });
        }
        // Chamada unária simples para obter metadados
        const result = await client.getMetadata({ video_url: url });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

// GET /downloads/initiate?url=...
const downloadVideo = (req, res, next) => {
    // ⭐ Nota: Esta função não é `async` porque ela lida com um stream contínuo.
    const { url } = req.query;
    if (!url) {
        return res.status(400).json({ error: 'Query parameter "url" é obrigatório.' });
    }

    try {
        // Apenas o cliente gRPC suporta o streaming definido no proto
        const stream = gRpcDownloadClient.download({ url });

        // 1. Configura os headers para Server-Sent Events (SSE)
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');
        res.flushHeaders(); // Envia os headers imediatamente

        // 2. Escuta os dados chegando do stream gRPC
        stream.on('data', (status) => {
            // Formata a mensagem no padrão SSE e envia para o cliente
            res.write(`data: ${JSON.stringify(status)}\n\n`);
        });

        // 3. Escuta o fim do stream
        stream.on('end', () => {
            console.log('Stream de download finalizado.');
            res.end(); // Fecha a conexão HTTP
        });

        // 4. Escuta erros no stream
        stream.on('error', (err) => {
            console.error('Erro no stream gRPC:', err);
            // É difícil enviar um status de erro aqui, pois a conexão já está aberta
            // mas podemos tentar enviar uma mensagem de erro antes de fechar
            res.write(`data: ${JSON.stringify({ error_message: 'Erro no servidor' })}\n\n`);
            res.end();
        });

        // 5. Se o cliente HTTP fechar a conexão, cancelamos o stream gRPC
        req.on('close', () => {
            console.log('Cliente desconectou. Cancelando stream.');
            stream.cancel();
        });

    } catch (error) {
      console.error('--- ERRO SINCRONO AO INICIAR STREAM ---');
      console.error(error);
      req.log.error({ err: error }, 'Falha síncrona ao iniciar o stream de download');
      next(error);
    }
};

export default {
    getVideoMetadata,
    downloadVideo,
};