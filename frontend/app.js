require('dotenv').config();

const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;

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
        await axios.post(`${API_URL}/api/playlists`, { name: name });
        res.redirect('/playlists');
    } catch (error) {
        console.error(error);
        res.redirect('/playlists'); 
    }
});

app.get('/playlists', async (req, res) => {
    try {
        const response = await axios.get(`${API_URL}/api/playlists`);
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
        const response = await axios.get(`${API_URL}/api/playlists/${playlistId}`)
        res.render('playlist-detalhe', { playlist: response.data.data });
    } catch (error) {
        console.error(error);
        res.redirect('/playlists');
    }
});

// PATCH /playlists/:name
app.post('/playlists/edit/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name } = req.body;

        await axios.patch(`${API_URL}/api/playlists/${id}`, { name: name });

        // Redireciona de volta para a PRÓPRIA página de detalhes
        res.redirect(`/playlists/${id}`);
    } catch (error) {
        console.error("Erro ao atualizar a playlist:", error.message);
        res.redirect('/playlists'); // Em caso de erro, volta para a lista
    }
});

app.post('/playlists/delete/:id', async (req, res) => {
    try {
        await axios.delete(`${API_URL}/api/playlists/${req.params.id}`);
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
        await axios.post(`${API_URL}/api/playlists/videos/${id_playlist}`, { url: video_url });
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
        await axios.delete(`${API_URL}/api/playlists/videos/${videoId}`);
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

async function downloadCompleted(fileId) {
    console.log('Download do vídeo concluído no backend. Iniciando download no cliente...');
    console.log('File ID para download:', fileId);
    
    // Esconde o card de progresso e mostra o de sucesso
    document.getElementById('progressCard').classList.add('d-none');
    document.getElementById('successCard').classList.remove('d-none');

    // Chama a função de download no cliente
    await baixarArquivoCliente(`${window.location.origin}/downloads/file/${fileId}`, fileId);
    // Observação: `window.location.origin` assume que o seu gateway de downloads está no mesmo domínio e porta que o seu frontend.
    // Se o seu gateway estiver em outro domínio/porta, substitua por `http://seu-gateway.com/downloads/file/${fileId}`
    
    // Fecha a conexão SSE após o download
    if (eventSource) {
        eventSource.close();
        eventSource = null;
    }
    
    // Re-habilita o botão de download após um pequeno atraso ou interação do usuário, se necessário
    // document.getElementById('downloadBtn').disabled = false;
    // document.getElementById('downloadBtn').innerHTML = '<i class="fas fa-download me-2"></i>Baixar';
}

// Função para exibir erros
function showError(message) {
    document.getElementById('progressCard').classList.add('d-none');
    document.getElementById('successCard').classList.add('d-none');
    document.getElementById('errorCard').classList.remove('d-none');
    document.getElementById('errorMessage').textContent = message;
    document.getElementById('downloadBtn').disabled = false;
    document.getElementById('downloadBtn').innerHTML = '<i class="fas fa-download me-2"></i>Baixar';
    if (eventSource) {
        eventSource.close();
        eventSource = null;
    }
}

// --- FUNÇÃO PARA BAIXAR O ARQUIVO NO CLIENTE (INTEGRADA) ---
/**
 * Função para baixar um arquivo de uma URL de API no cliente.
 * Esta função DEVE ser chamada quando o backend já preparou o arquivo
 * e está pronto para enviá-lo com o cabeçalho Content-Disposition: attachment.
 * @param {string} url - A URL completa para o arquivo no seu gateway.
 * @param {string} suggestedFilename - O nome que o arquivo terá ao ser salvo.
 */
async function baixarArquivoCliente(url, suggestedFilename) {
    try {
        console.log("Iniciando download do arquivo final de:", url);
        
        const response = await fetch(url, {
            method: 'GET',
        });

        if (!response.ok) {
            throw new Error(`Erro na requisição final de download: ${response.status} ${response.statusText}`);
        }

        const blob = await response.blob();
        const downloadUrl = window.URL.createObjectURL(blob);
        
        const link = document.createElement('a');
        link.href = downloadUrl;
        link.download = suggestedFilename; // Usa o nome sugerido para o arquivo
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        window.URL.revokeObjectURL(downloadUrl);
        
        console.log("Download do arquivo final solicitado com sucesso!");

    } catch (error) {
        console.error("Falha ao baixar o arquivo final:", error);
        showError(`Erro ao iniciar o download: ${error.message}`);
    }
}


// function handleDownload(videoUrl) {
//     if (!videoUrl) {
//         return res.status(400).send('URL do vídeo não fornecida.');
//     }

//     // Configura cabeçalhos para SSE
//     res.setHeader('Content-Type', 'text/event-stream');
//     res.setHeader('Cache-Control', 'no-cache');
//     res.setHeader('Connection', 'keep-alive');
//     res.setHeader('Access-Control-Allow-Origin', '*');

//     try {
//         const downloadApiUrl = `${API_URL}/api/downloads/?url=${encodeURIComponent(videoUrl)}`;
        
//         const response = await axios({
//             method: 'GET',
//             url: downloadApiUrl,
//             responseType: 'stream'
//         });

//         // Ouve os dados chegando da API
//         response.data.on('data', (chunk) => {
//             const dataString = chunk.toString();
//             const lines = dataString.split('\n');

//             lines.forEach(line => {
//                 if (line.startsWith('data:')) {
//                     try {
//                         // Parse do JSON para verificar o tipo
//                         const jsonData = JSON.parse(line.substring(5)); // Remove 'data:'
                        
//                         if (jsonData.type === 'completed' && jsonData.downloadUrl) {
//                             // Converte URL local para URL da API externa
//                             const externalUrl = `${API_URL}\/${jsonData.downloadUrl}`;
//                             const modifiedData = { ...jsonData, downloadUrl: externalUrl };
//                             console.log('baixando arquivo');

//                             baixarArquivoCliente(url, suggestedFilename)

//                             // axios.get(`${API_URL}\/${jsonData.downloadUrl}`);
//                             // res.write(`data: ${JSON.stringify(modifiedData)}\n\n`);
//                         } else {
//                             // Repassa mensagens de progresso normalmente
//                             res.write(`${line}\n\n`);
//                         }
//                     } catch (parseError) {
//                         // Se não conseguir fazer parse, repassa a linha original
//                         res.write(`${line}\n\n`);
//                     }
//                 }
//             });
//         });

//         response.data.on('end', () => {
//             console.log('Stream da API finalizado.');
//             res.end();
//         });

//         response.data.on('error', (err) => {
//             console.error('Erro no stream da API:', err);
//             res.write(`data: {"type":"error", "message": "Erro no stream da API"}\n\n`);
//             res.end();
//         });

//     } catch (error) {
//         console.error('Erro ao conectar com a API de download:', error.message);
//         res.write(`data: {"type":"error", "message": "Falha ao iniciar o processo na API."}\n\n`);
//         res.end();
//     }

//     // Se o cliente fechar a aba, paramos de ouvir a API
//     req.on('close', () => {
//         console.log('Cliente desconectou. Fechando stream.');
//         res.end();
//     });
// };

// app.get('/downloads/status', async (req, res) => {
//     const videoUrl = req.query.url;

//     if (!videoUrl) {
//         return res.status(400).send('URL do vídeo não fornecida.');
//     }

//     // Configura cabeçalhos para SSE
//     res.setHeader('Content-Type', 'text/event-stream');
//     res.setHeader('Cache-Control', 'no-cache');
//     res.setHeader('Connection', 'keep-alive');
//     res.setHeader('Access-Control-Allow-Origin', '*');

//     try {
//         const downloadApiUrl = `${API_URL}/api/downloads/?url=${encodeURIComponent(videoUrl)}`;
        
//         const response = await axios({
//             method: 'GET',
//             url: downloadApiUrl,
//             responseType: 'stream'
//         });

//         // Ouve os dados chegando da API
//         response.data.on('data', (chunk) => {
//             const dataString = chunk.toString();
//             const lines = dataString.split('\n');

//             lines.forEach(line => {
//                 if (line.startsWith('data:')) {
//                     try {
//                         // Parse do JSON para verificar o tipo
//                         const jsonData = JSON.parse(line.substring(5)); // Remove 'data:'
                        
//                         if (jsonData.type === 'completed' && jsonData.downloadUrl) {
//                             // Converte URL local para URL da API externa
//                             const externalUrl = `${API_URL}\/${jsonData.downloadUrl}`;
//                             const modifiedData = { ...jsonData, downloadUrl: externalUrl };
//                             console.log('baixando arquivo');

//                             baixarArquivoCliente(url, suggestedFilename)

//                             // axios.get(`${API_URL}\/${jsonData.downloadUrl}`);
//                             // res.write(`data: ${JSON.stringify(modifiedData)}\n\n`);
//                         } else {
//                             // Repassa mensagens de progresso normalmente
//                             res.write(`${line}\n\n`);
//                         }
//                     } catch (parseError) {
//                         // Se não conseguir fazer parse, repassa a linha original
//                         res.write(`${line}\n\n`);
//                     }
//                 }
//             });
//         });

//         response.data.on('end', () => {
//             console.log('Stream da API finalizado.');
//             res.end();
//         });

//         response.data.on('error', (err) => {
//             console.error('Erro no stream da API:', err);
//             res.write(`data: {"type":"error", "message": "Erro no stream da API"}\n\n`);
//             res.end();
//         });

//     } catch (error) {
//         console.error('Erro ao conectar com a API de download:', error.message);
//         res.write(`data: {"type":"error", "message": "Falha ao iniciar o processo na API."}\n\n`);
//         res.end();
//     }

//     // Se o cliente fechar a aba, paramos de ouvir a API
//     req.on('close', () => {
//         console.log('Cliente desconectou. Fechando stream.');
//         res.end();
//     });
// });

// Inicia o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});