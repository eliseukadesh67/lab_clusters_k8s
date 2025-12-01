import { Counter, Histogram, collectDefaultMetrics, register } from 'prom-client';

collectDefaultMetrics({ register });

export const httpRequestDurationSeconds = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duração das requisições HTTP em segundos',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [
    0.005, 0.01, 0.025, 0.05, 0.1,
    0.25, 0.5, 1, 2.5, 5, 10
  ],
});

export const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total de requisições HTTP processadas',
  labelNames: ['method', 'route', 'status_code'],
});

function getRouteLabel(req) {
  try {
    if (req.route && req.route.path) {
      return (req.baseUrl || '') + req.route.path;
    }
    return req.baseUrl || req.path || req.originalUrl || 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

export function metricsMiddleware(req, res, next) {
  const method = req.method;
  const end = httpRequestDurationSeconds.startTimer({ method });

  res.on('finish', () => {
    const route = getRouteLabel(req);
    const status = String(res.statusCode);
    end({ route, status_code: status });
    httpRequestsTotal.inc({ method, route, status_code: status });
  });

  next();
}

export async function metricsHandler(req, res) {
  res.set('Content-Type', register.contentType);
  const body = await register.metrics();
  res.status(200).send(body);
}
