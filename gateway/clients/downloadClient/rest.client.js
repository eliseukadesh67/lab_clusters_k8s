import config from '../../config.js';

const apiClient = config.clients.downloads.rest;

export default {
  download: (payload) => apiClient.post('/downloads', { video_url: payload.url }),
  getMetadata: (payload) => apiClient.post('/downloads/metadata', { responseType: 'stream' }, { video_url: payload.url })
};