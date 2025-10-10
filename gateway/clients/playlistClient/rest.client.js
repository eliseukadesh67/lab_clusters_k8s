import config from '../../config.js';

const apiClient = config.clients.playlists.rest;

export default {
    create: (payload) => apiClient.post('/playlists', { name: payload.name }),
    list: () => apiClient.get('/playlists'),
    getById: (payload) => apiClient.get(`/playlists/${payload.playlist_id}`),
    updateById: (payload) => apiClient.patch(`/playlists/${payload.playlist_id}`, { name: payload.name }),
    deleteById: (payload) => apiClient.delete(`/playlists/${payload.playlist_id}`),
    addVideo: (payload) => apiClient.post(`/playlists/${payload.playlist_id}/videos`, { url: payload.url }),
    listVideos: (payload) => apiClient.get(`/playlists/${payload.playlist_id}/videos`),
    getVideo: (payload) => apiClient.get(`/playlists/${payload.playlist_id}/videos/${payload.video_id}`),
    deleteVideo: (payload) => apiClient.delete(`/playlists/${payload.playlist_id}/videos/${payload.video_id}`),
};