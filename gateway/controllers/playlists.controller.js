import gRpcPlaylistClient from '../clients/playlistClient/grpc.client.js';
import restPlaylistClient from '../clients/playlistClient/rest.client.js';

// Função auxiliar para escolher o cliente com base no header
const getClient = (req) => (req.headers['x-communication-protocol'] === 'grpc' ? gRpcPlaylistClient : restPlaylistClient);

const createPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { name } = req.body;
        const result = await client.create({ name });
        res.status(201).json(result);
    } catch (error) {
        next(error);
    }
};

const listPlaylists = async (req, res, next) => {
    try {
        const client = getClient(req);
        const result = await client.list({});
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

const getPlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        const result = await client.getById({ playlist_id: id });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

const updatePlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        const { name } = req.body;
        const result = await client.updateById({ playlist_id: id, name });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

const deletePlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        const result = await client.deleteById({ playlist_id: id });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};


// --- Funções de Vídeo ---

const addVideoToPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { playlistId } = req.params;
        const { url } = req.body;
        const result = await client.addVideo({ playlist_id: playlistId, url });
        res.status(201).json(result);
    } catch (error) {
        next(error);
    }
};

const listVideosInPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { playlistId } = req.params;
        const result = await client.listVideos({ playlist_id: playlistId });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

const getVideoFromPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { playlistId, videoId } = req.params;
        const result = await client.getVideo({ playlist_id: playlistId, video_id: videoId });
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};

const deleteVideoFromPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { playlistId, videoId } = req.params;
        // O proto especifica que esta RPC retorna a lista de vídeos atualizada.
        const result = await client.deleteVideo({ playlist_id: playlistId, video_id: videoId });
        // Portanto, o status HTTP correto é 200 OK com o corpo da resposta.
        res.status(200).json(result);
    } catch (error) {
        next(error);
    }
};


export default {
    createPlaylist,
    listPlaylists,
    getPlaylistById,
    updatePlaylistById,
    deletePlaylistById,
    addVideoToPlaylist,
    listVideosInPlaylist,
    getVideoFromPlaylist,
    deleteVideoFromPlaylist,
};