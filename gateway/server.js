import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import morgan from 'morgan';
import setupRoutes from './routes.js';
import errorHandler from './middlewares/errorHandler.js';
import { metricsMiddleware, metricsHandler } from './metrics.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(pinoHttp({
  transport: process.env.NODE_ENV !== 'production' 
    ? { 
        target: 'pino-pretty', 
        options: { 
          colorize: true,
          
          // --- ADICIONE ESTAS DUAS OPÇÕES ---

          // 1. Formata a mensagem principal do log usando dados do JSON
          messageFormat: '{req.method} {req.url} {res.statusCode} - {responseTime}ms',
          
          // 2. Esconde campos que não queremos ver nos logs de acesso
          ignore: 'pid,hostname,req.id,req.headers,res.headers',
        } 
      } 
    : undefined,
}));

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(metricsMiddleware);

setupRoutes(app);

// Endpoint de métricas Prometheus
app.get('/metrics', metricsHandler);

app.use((req, res, next) => {
  res.status(404).json({ error: 'Not Found', message: 'A rota solicitada não existe.' });
});

app.use(errorHandler);


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