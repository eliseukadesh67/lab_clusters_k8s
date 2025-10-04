import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import setupRoutes from './routes.js';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

setupRoutes(app);

app.use((req, res, next) => {
  res.status(404).json({ error: 'Not Found', message: 'A rota solicitada não existe.' });
});

app.use((err, req, res, next) => {
  console.error('Ocorreu um erro inesperado:', err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});


const server = app.listen(PORT, () => {
  console.log(`🚀 Gateway server running on port ${PORT}`);
});

// Graceful Shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received.');
  server.close(() => {
    console.log('HTTP server closed.');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received.');
  server.close(() => {
    console.log('HTTP server closed.');
    process.exit(0);
  });
});