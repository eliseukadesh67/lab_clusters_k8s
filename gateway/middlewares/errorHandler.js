// middlewares/errorHandler.js
import { status as GrpcStatus } from '@grpc/grpc-js';

// Mapeia códigos gRPC para status HTTP
const grpcToHttpStatus = {
  [GrpcStatus.NOT_FOUND]: 404,
  [GrpcStatus.INVALID_ARGUMENT]: 400,
  [GrpcStatus.ALREADY_EXISTS]: 409,
  [GrpcStatus.PERMISSION_DENIED]: 403,
  [GrpcStatus.UNAUTHENTICATED]: 401,
  // Adicione outros mapeamentos conforme necessário
};

const errorHandler = (err, req, res, next) => {
  const logger = req.log;
  let statusCode = 500;
  let message = 'Ocorreu um erro inesperado no servidor.';

  // --- Lógica de Detecção de Erro ---

  // 1. É um erro do gRPC? (Verifica se 'code' é um número)
  if (typeof err.code === 'number' && grpcToHttpStatus[err.code]) {
    statusCode = grpcToHttpStatus[err.code];
    message = err.details || 'Erro de comunicação com o serviço interno.';
  }
  // 2. É um erro do cliente REST (Axios)?
  else if (err.isAxiosError && err.response) {
    statusCode = err.response.status;
    message = err.response.data.message || 'Erro de comunicação com o serviço interno.';
  }

  // Loga o erro de forma estruturada, com o status HTTP correto
  logger.error(
    {
      error: {
        name: err.name,
        message: err.message,
        stack: err.stack,
        origin_code: err.code, // Código original do erro (gRPC ou outro)
      },
      statusCode,
    },
    'Request Error'
  );

  // Responde ao cliente com um formato padronizado
  res.status(statusCode).json({ message });
};

export default errorHandler;