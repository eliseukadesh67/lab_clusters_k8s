import gRpcPlaylistClient from '../clients/playlistClient/grpc.client.js';

// Função auxiliar para escolher o cliente
const getClient = (req) => gRpcPlaylistClient;

const createPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { name } = req.body;
        const result = await client.create({ name });
        res.status(201).json({ message: "Playlist criada!", data: result });
    } catch (error) {
        next(error);
    }
};

const listPlaylists = async (req, res, next) => {
    try {
        const client = getClient(req);
        const result = await client.list({});
        res.status(200).json({ data: result });
    } catch (error) {
        next(error);
    }
};

const getPlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        const result = await client.getById({ id });
        res.status(200).json({ data: result });
    } catch (error) {
        next(error);
    }
};

const updatePlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        const { name } = req.body;
        const result = await client.updateById({ id, name });
        res.status(200).json({ message: "Playlist editada!", data: result});
    } catch (error) {
        next(error);
    }
};

const deletePlaylistById = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { id } = req.params;
        await client.deleteById({ id });
        res.status(200).json({ message: "Playlist excluida!" });
    } catch (error) {
        next(error);
    }
};


// --- Funções de Vídeo ---

const addVideoToPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { playlist_id } = req.params;
        const { url } = req.body;
        const result = await client.addVideo({ playlist_id, url });
        res.status(201).json({ message: "Video adicionado a playlist!", data: result });
    } catch (error) {
        next(error);
    }
};

const getVideoFromPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { video_id } = req.params;
        const result = await client.getVideo({ id: video_id });
        res.status(200).json({data: result});
    } catch (error) {
        next(error);
    }
};

const deleteVideoFromPlaylist = async (req, res, next) => {
    try {
        const client = getClient(req);
        const { video_id } = req.params;
        await client.deleteVideo({ id: video_id });
        res.status(200).json({data: "Video removido da playlist!"});
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
    getVideoFromPlaylist,
    deleteVideoFromPlaylist,
};