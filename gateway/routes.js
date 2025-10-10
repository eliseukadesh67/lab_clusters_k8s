import PlaylistController from './controllers/playlists.controller.js';
import DownloadController from './controllers/downloads.controller.js';

const setupRoutes = (app) => {
  console.log('🔗 Configurando as rotas da aplicação...');

  // --- Rotas de Playlists (nível raiz) ---
  app.post('/api/playlists', PlaylistController.createPlaylist);
  app.get('/api/playlists', PlaylistController.listPlaylists);
  app.get('/api/playlists/:id', PlaylistController.getPlaylistById);
  app.patch('/api/playlists/:id', PlaylistController.updatePlaylistById);
  app.delete('/api/playlists/:id', PlaylistController.deletePlaylistById);
  
  // --- Rotas para Vídeos dentro de uma Playlist ---
  app.post('/api/playlists/videos/:playlist_id', PlaylistController.addVideoToPlaylist);
  app.get('/api/playlists/videos/:video_id', PlaylistController.getVideoFromPlaylist);
  app.delete('/api/playlists/videos/:video_id', PlaylistController.deleteVideoFromPlaylist);

  // --- Rotas de Downloads ---
  app.get('/api/downloads/metadata', DownloadController.getVideoMetadata);
  app.get('/api/downloads', DownloadController.downloadVideo);
  app.get('/api/downloads/file/:file_id', DownloadController.serveDownloadedVideo);

  console.log('✅ Rotas configuradas.');
};

export default setupRoutes;