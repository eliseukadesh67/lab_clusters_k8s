require('dotenv').config();
const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

// Configura a URL base da API a partir do arquivo .env
const API_URL = process.env.API_URL;

// Configurar o View Engine para EJS
app.set('view engine', 'ejs');

// Middlewares
app.use(express.static('public')); // Para servir arquivos CSS e JS estáticos
app.use(express.urlencoded({ extended: true })); // Para conseguir ler dados de formulários (req.body)

// --- ROTAS PRINCIPAIS ---

app.get('/', (req, res) => {
    res.render('index', { videoUrl: null, error: null });
});

// Rota que recebe a URL do formulário para download
app.post('/download-url', (req, res) => {
    const { url } = req.body;
    // A API GET /downloads/:url parece ser a ideal aqui.
    // A forma mais simples de "fazer o download" é redirecionar o usuário
    // para a URL da API que força o download.
    if (url) {
        const downloadApiUrl = `${API_URL}/downloads/${encodeURIComponent(url)}`;
        console.log(`Redirecionando para: ${downloadApiUrl}`);
        res.redirect(downloadApiUrl);
    } else {
        res.render('index', { videoUrl: null, error: 'URL inválida.' });
    }
});


// --- ROTAS DE PLAYLISTS (CRUD) ---

// 1. Listar todas as playlists e formulário para criar uma nova
app.get('/playlists', async (req, res) => {
    try {
        const response = await axios.get(`${API_URL}/playlists`);
        res.render('playlists', { playlists: response.data });
    } catch (error) {
        console.error(error);
        res.render('playlists', { playlists: [] });
    }
});

// 2. Criar uma nova playlist
app.post('/playlists', async (req, res) => {
    try {
        const { name } = req.body;
        await axios.post(`${API_URL}/playlists`, { name: name });
        res.redirect('/playlists');
    } catch (error) {
        console.error(error);
        res.redirect('/playlists'); // Adicionar tratamento de erro aqui
    }
});

// 3. Ver detalhes de uma playlist (e seus vídeos)
app.get('/playlists/:id', async (req, res) => {
    try {
        const playlistId = req.params.id;
        // Pega os detalhes da playlist
        const playlistResponse = await axios.get(`${API_URL}/playlists/${playlistId}`);
        // Supondo que a resposta da playlist já contenha os vídeos.
        // Se não, você precisaria fazer outra chamada para pegar os vídeos.
        res.render('playlist-detalhe', { playlist: playlistResponse.data });
    } catch (error) {
        console.error(error);
        res.redirect('/playlists');
    }
});

// 4. Adicionar um vídeo a uma playlist
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

// 5. Deletar uma playlist
app.post('/playlists/delete/:id', async (req, res) => {
    try {
        await axios.delete(`${API_URL}/playlists/${req.params.id}`);
        res.redirect('/playlists');
    } catch (error) {
        console.error(error);
        res.redirect('/playlists');
    }
});

// 6. Deletar um vídeo de uma playlist
app.post('/videos/delete/:id', async (req, res) => {
    const videoId = req.params.id;
    // Importante: Precisamos saber para qual playlist voltar.
    // Isso deve ser passado no formulário.
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