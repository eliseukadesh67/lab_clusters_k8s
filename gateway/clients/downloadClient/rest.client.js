import config from '../../config.js';

const apiClient = config.clients.downloads.rest;

export default {
  getMetadata: (payload) => apiClient.get('/downloads/metadata', { params: { url: payload.video_url } })
};