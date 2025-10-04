require('dotenv').config();
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

const API_URL = process.env.API_URL;

app.set('view engine', 'ejs');

app.use(express.static('public')); // Para servir arquivos CSS e JS estáticos
app.use(express.urlencoded({ extended: true })); // Para conseguir ler dados de formulários (req.body)

app.get('/', (req, res) => {
    res.render('index', { videoUrl: null, error: null });
});

app.post('/download-url', (req, res) => {
    const { url } = req.body;

    if (url) {
        const downloadApiUrl = `${API_URL}/downloads/${encodeURIComponent(url)}`;
        console.log(`Redirecionando para: ${downloadApiUrl}`);
        res.redirect(downloadApiUrl);
    } else {
        res.render('index', { videoUrl: null, error: 'URL inválida.' });
    }
});

app.get('/playlists', async (req, res) => {
    try {
        const response = await axios.get(`${API_URL}/playlists`);

        const playlistsParaTemplate = { items: response.data };
        
        res.render('playlists', { playlists: playlistsParaTemplate });
    } catch (error) {
        console.error(error);
        res.render('playlists', { playlists: { items: [] } });
    }
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

// Função original
// app.get('/playlists/:id', async (req, res) => {
//     try {
//         const playlistId = req.params.id;

//         const response = await axios.get(`${API_URL}/playlists/${playlistId}?_embed=videos`);

//         res.render('playlist-detalhe', { playlist: response.data });
//     } catch (error) {
//         console.error(error);
//         res.redirect('/playlists');
//     }
// });

app.get('/playlists/:id', async (req, res) => {
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
});

app.post('/videos/:id_playlist', async (req, res) => {
    try {
        const { id_playlist } = req.params;
        const { video_url } = req.body;
        await axios.post(`${API_URL}/videos/${id_playlist}`, { url: video_url });
        res.redirect(`/playlists/${id_playlist}`);
    } catch (error) {
        console.error(error);
        res.redirect(`/playlists/${req.params.id_playlist}`);
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

app.post('/videos/delete/:id', async (req, res) => {
    const videoId = req.params.id;
    const { playlistId } = req.body;
    try {
        await axios.delete(`${API_URL}/videos/${videoId}`);
        res.redirect(`/playlists/${playlistId}`);
    } catch (error) {
        console.error(error);
        res.redirect(`/playlists/${playlistId}`);
    }
});

// Inicia o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});