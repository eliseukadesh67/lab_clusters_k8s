require('dotenv').config();
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 8080;

const PROTOCOL= process.env.PROTOCOL
const API_URL = process.env.API_URL;

app.set('view engine', 'ejs');

app.use(express.static('public')); // Para servir arquivos CSS e JS estáticos
app.use(express.urlencoded({ extended: true })); // Para conseguir ler dados de formulários (req.body)

axios.defaults.headers.common['x-communication-protocol'] = PROTOCOL;

app.get('/', (req, res) => {
    res.render('index', { videoUrl: null, error: null });
});

app.post('/playlists', async (req, res) => {
    try {
        const { name } = req.body;
        await axios.post(`${API_URL}/playlists`, { name: name });
        res.redirect('/playlists');
    } catch (error) {
        console.error(error);
        res.redirect('/playlists'); 
    }
});

app.get('/playlists', async (req, res) => {
    try {
        const response = await axios.get(`${API_URL}/playlists`);
        const playlistsParaTemplate = { items: response.data.data.items };
        
        res.render('playlists', { playlists: playlistsParaTemplate });
    } catch (error) {
        console.error(error);
        res.render('playlists', { playlists: { items: [] } });
    }
});

// Versão correta como documentado
app.get('/playlists/:id', async (req, res) => {
    try {
        const playlistId = req.params.id
        const response = await axios.get(`${API_URL}/playlists/${playlistId}`)
        res.render('playlist-detalhe', { playlist: response.data.data });
    } catch (error) {
        console.error(error);
        res.redirect('/playlists');
    }
});

// Versão de teste para execução local do frontend
/* app.get('/playlists/:id', async (req, res) => {
    try {
        const playlistId = req.params.id;

        console.log(`Buscando dados para a playlist: ${playlistId}`);

        // --- INÍCIO DA SOLUÇÃO TEMPORÁRIA ---

        const [playlistResponse, videosResponse] = await Promise.all([
            // Chamada 1: Pega os dados básicos da playlist
            axios.get(`${API_URL}/playlists/${playlistId}`),
            // Chamada 2: Filtra e pega somente os vídeos com o playlist_id correspondente
            axios.get(`${API_URL}/videos?playlist_id=${playlistId}`)
        ]);

        const playlist = playlistResponse.data;
        const videos = videosResponse.data;

        playlist.videos = videos;
        
        // --- FIM DA SOLUÇÃO TEMPORÁRIA ---
        
        res.render('playlist-detalhe', { playlist: playlist });

    } catch (error) {
        console.error("Ocorreu um erro ao buscar os detalhes da playlist:", error.message);
        res.redirect('/playlists');
    }
});  */

// PATCH /playlists/:name
app.post('/playlists/edit/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;

        await axios.patch(`${API_URL}/playlists/${id}`, { name: name });

        // Redireciona de volta para a PRÓPRIA página de detalhes
        res.redirect(`/playlists/${id}`);
    } catch (error) {
        console.error("Erro ao atualizar a playlist:", error.message);
        res.redirect('/playlists'); // Em caso de erro, volta para a lista
    }
});

app.post('/playlists/delete/:id', async (req, res) => {
    try {
        await axios.delete(`${API_URL}/playlists/${req.params.id}`);
        res.redirect('/playlists');
    } catch (error) {
        console.error(error);
        res.redirect('/playlists');
    }
});

app.post('/videos/:id_playlist', async (req, res) => {
    try {
        const { id_playlist } = req.params;
        const { video_url } = req.body;
        await axios.post(`${API_URL}/playlists/videos/${id_playlist}`, { url: video_url });
        res.redirect(`/playlists/${id_playlist}`);
    } catch (error) {
        console.error(error);
        res.redirect(`/playlists/${req.params.id_playlist}`);
    }
});

app.post('/videos/delete/:id', async (req, res) => {
    const videoId = req.params.id;
    const { playlistId } = req.body;
    try {
        await axios.delete(`${API_URL}/playlists/videos/${videoId}`);
        res.redirect(`/playlists/${playlistId}`);
    } catch (error) {
        console.error(error);
        res.redirect(`/playlists/${playlistId}`);
    }
});

// TODO: GET /playlists/videos/:id
app.post('/playlists/videos/:id', async (req, res) => {
    // ...
});

// TODO: GET /downloads/video/:id
app.post('/downloads/video/:id', async (req, res) => {
    // ...
});

// TODO: GET /downloads/playlist/:id 
app.post('/downloads/playlist/:id', async (req, res) => {
    // ...
});

app.post('/downloads', (req, res) => {
    const { url } = req.body;

    if (url) {
        const downloadApiUrl = `${API_URL}/downloads/?url=${encodeURIComponent(url)}`;
        console.log(`Redirecionando para: ${downloadApiUrl}`);
        res.redirect(downloadApiUrl);
    } else {
        res.render('index', { videoUrl: null, error: 'URL inválida.' });
    }
});

// Inicia o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});