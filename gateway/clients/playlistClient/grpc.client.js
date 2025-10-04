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
    create: promisifyGrpc(grpcClient.CreatePlaylist),
    list: promisifyGrpc(grpcClient.ListPlaylists),
    getById: promisifyGrpc(grpcClient.GetPlaylist),
    updateById: promisifyGrpc(grpcClient.EditPlaylist),
    deleteById: promisifyGrpc(grpcClient.DeletePlaylist),
    addVideo: promisifyGrpc(grpcClient.AddVideo),
    listVideos: promisifyGrpc(grpcClient.ListVideos),
    getVideo: promisifyGrpc(grpcClient.GetVideo),
    deleteVideo: promisifyGrpc(grpcClient.DeleteVideo),
};