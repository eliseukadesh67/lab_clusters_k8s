import PlaylistController from './controllers/playlists.controller.js';
import DownloadController from './controllers/downloads.controller.js';

const setupRoutes = (app) => {
  console.log('🔗 Configurando as rotas da aplicação...');

  // --- Rotas de Playlists (nível raiz) ---
  app.post('/playlists', PlaylistController.createPlaylist);
  app.get('/playlists', PlaylistController.listPlaylists);
  app.get('/playlists/:id', PlaylistController.getPlaylistById);
  app.patch('/playlists/:id', PlaylistController.updatePlaylistById);
  app.delete('/playlists/:id', PlaylistController.deletePlaylistById);
  
  // --- Rotas para Vídeos dentro de uma Playlist ---
  app.post('/playlists/videos/:playlist_id', PlaylistController.addVideoToPlaylist);
  app.get('/playlists/videos/:video_id', PlaylistController.getVideoFromPlaylist);
  app.delete('/playlists/videos/:video_id', PlaylistController.deleteVideoFromPlaylist);

  // --- Rotas de Downloads ---
  app.get('/downloads/metadata', DownloadController.getVideoMetadata);
  app.get('/downloads', DownloadController.downloadVideo);

  console.log('✅ Rotas configuradas.');
};

export default setupRoutes;