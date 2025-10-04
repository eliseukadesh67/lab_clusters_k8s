import config from '../../config.js';

const grpcClient = config.clients.playlists.grpc;

const promisifyGrpc = (method) => (payload) => {
    return new Promise((resolve, reject) => {
        method.bind(grpcClient)(payload, (error, response) => {
            if (error) {
                return reject(error);
            }
            return resolve(response);
        });
    });
};

export default {
    create: promisifyGrpc(grpcClient.PostPlaylists),
    list: promisifyGrpc(grpcClient.GetPlaylists),
    getById: promisifyGrpc(grpcClient.GetPlaylistsById),
    updateById: promisifyGrpc(grpcClient.PatchPlaylists),
    deleteById: promisifyGrpc(grpcClient.DeletePlaylist),
    addVideo: promisifyGrpc(grpcClient.PostVideos),
    getVideo: promisifyGrpc(grpcClient.GetVideosById),
    deleteVideo: promisifyGrpc(grpcClient.DeleteVideos),
};