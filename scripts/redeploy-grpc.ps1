$ErrorActionPreference = "Stop"

Write-Host "[1/6] Verificando Docker..." -ForegroundColor Cyan
docker version | Out-Null

Write-Host "[2/6] Build grpc-download-service (Python)..." -ForegroundColor Cyan
docker build `
  -t zenildavieira/grpc-download-service:latest `
  -f services/grpc/download/Dockerfile `
  services/grpc/download

Write-Host "[3/6] Push grpc-download-service..." -ForegroundColor Cyan
docker push zenildavieira/grpc-download-service:latest

Write-Host "[4/6] Build grpc-playlist-service (Ruby)..." -ForegroundColor Cyan
docker build `
  -t zenildavieira/grpc-playlist-service:latest `
  -f services/grpc/playlist/Dockerfile `
  services/grpc/playlist

Write-Host "[5/6] Push grpc-playlist-service..." -ForegroundColor Cyan
docker push zenildavieira/grpc-playlist-service:latest

Write-Host "[6/6] Reiniciando deployments no cluster..." -ForegroundColor Cyan
kubectl rollout restart deployment/grpc-download-deployment -n microservices
kubectl rollout restart deployment/grpc-playlist-deployment -n microservices

Write-Host "Aguardando rollouts..." -ForegroundColor Yellow
kubectl rollout status deployment/grpc-download-deployment -n microservices
kubectl rollout status deployment/grpc-playlist-deployment -n microservices

Write-Host "Concluído. Agora teste as métricas com port-forward:" -ForegroundColor Green
Write-Host "  kubectl port-forward -n microservices pod/$(kubectl get pod -n microservices -l app=grpc-download-service -o jsonpath='{.items[0].metadata.name}') 9464:9464"
Write-Host "  curl http://localhost:9464/metrics"
Write-Host "E para o playlist:" -ForegroundColor Green
Write-Host "  kubectl port-forward -n microservices pod/$(kubectl get pod -n microservices -l app=grpc-playlist-service -o jsonpath='{.items[0].metadata.name}') 9464:9464"
Write-Host "  curl http://localhost:9464/metrics"
