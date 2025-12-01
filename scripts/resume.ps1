param(
  [switch]$Rebuild = $false,
  [switch]$PortForward = $true,
  [switch]$Validate = $true
)

$ErrorActionPreference = "Stop"

function Write-Step($text) { Write-Host $text -ForegroundColor Cyan }
function Write-Ok($text) { Write-Host $text -ForegroundColor Green }
function Write-Warn($text) { Write-Host $text -ForegroundColor Yellow }
function Write-Err($text) { Write-Host $text -ForegroundColor Red }

function Test-Cmd($name) {
  try { Get-Command $name -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

Write-Step "[1/7] Verificando ferramentas (kubectl, docker)..."
if (-not (Test-Cmd kubectl)) { Write-Err "kubectl não encontrado no PATH"; exit 1 }
if (-not (Test-Cmd docker)) { Write-Warn "docker não encontrado no PATH (rebuild será ignorado)"; $Rebuild = $false }

Write-Step "[2/7] Verificando Kubernetes..."
$maxAttempts = 20
$ready = $false
for ($i=1; $i -le $maxAttempts; $i++) {
  try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($LASTEXITCODE -eq 0 -and $nodes) { $ready = $true; break }
  } catch {}
  Start-Sleep -Seconds 3
}
if (-not $ready) { Write-Err "Kubernetes não está pronto. Abra o Docker Desktop e aguarde o Kubernetes subir."; exit 1 }
Write-Ok "Kubernetes OK."

Write-Step "[3/7] Namespaces e pods principais..."
kubectl get ns microservices,observability | Out-String | Write-Host
kubectl get pods -n microservices | Out-String | Write-Host
kubectl get pods -n observability | Out-String | Write-Host

if ($Rebuild) {
  Write-Step "[4/7] Rebuild + push imagens e restart deployments (gRPC)..."
  & "$PSScriptRoot\redeploy-grpc.ps1"
}
else {
  Write-Warn "Pulando rebuild. Use -Rebuild para reconstruir e publicar imagens."
}

Write-Step "[5/7] Iniciando port-forwards (opcional)..."
if ($PortForward) {
  # Grafana 3000->80
  Start-Job -Name "pf-grafana" -ScriptBlock {
    kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80
  } | Out-Null
  # Prometheus 9090->9090
  Start-Job -Name "pf-prom" -ScriptBlock {
    kubectl -n observability port-forward svc/kube-prometheus-stack-prometheus 9090:9090
  } | Out-Null
  # Métricas gRPC (serviços)
  Start-Job -Name "pf-grpc-download" -ScriptBlock {
    kubectl -n microservices port-forward svc/grpc-download-service 19464:9464
  } | Out-Null
  Start-Job -Name "pf-grpc-playlist" -ScriptBlock {
    kubectl -n microservices port-forward svc/grpc-playlist-service 29464:9464
  } | Out-Null

  Write-Ok "Port-forwards iniciados (jobs: pf-grafana, pf-prom, pf-grpc-download, pf-grpc-playlist)."
  Write-Warn "Para parar: Get-Job | Stop-Job -Force; Remove-Job *"
}
else {
  Write-Warn "Pulando port-forward. Use -PortForward para habilitar."
}

Write-Step "[6/7] Validação básica (opcional)..."
if ($Validate) {
  Start-Sleep -Seconds 3
  # Testar métricas gRPC locais
  try {
    $d = Invoke-WebRequest -Uri 'http://localhost:19464/metrics' -TimeoutSec 4
    Write-Ok ("grpc-download metrics: HTTP {0} ({1} bytes)" -f $d.StatusCode, $d.Content.Length)
  } catch { Write-Err ("grpc-download metrics falhou: {0}" -f $_.Exception.Message) }
  try {
    $p = Invoke-WebRequest -Uri 'http://localhost:29464/metrics' -TimeoutSec 4
    Write-Ok ("grpc-playlist metrics: HTTP {0} ({1} bytes)" -f $p.StatusCode, $p.Content.Length)
  } catch { Write-Err ("grpc-playlist metrics falhou: {0}" -f $_.Exception.Message) }

  # Testar API de targets do Prometheus
  try {
    $targets = Invoke-RestMethod -Uri 'http://localhost:9090/api/v1/targets?state=any' -TimeoutSec 4
    $all = $targets.data.activeTargets + $targets.data.droppedTargets | Where-Object { $_ }
    $jobs = $all | Where-Object { $_.labels.job -match 'grpc-(download|playlist)-service' } | Select-Object labels, health, scrapePool, lastError
    Write-Host "Targets gRPC no Prometheus:" -ForegroundColor Magenta
    $jobs | Format-Table -AutoSize | Out-String | Write-Host
  } catch { Write-Err ("Prometheus API falhou: {0}" -f $_.Exception.Message) }
}
else {
  Write-Warn "Pulando validação. Use -Validate para habilitar."
}

Write-Step "[7/7] Pronto! Acesse:" 
Write-Host "- Grafana:     http://localhost:3000" -ForegroundColor White
Write-Host "- Prometheus:  http://localhost:9090" -ForegroundColor White
Write-Host "- gRPC metrics: http://localhost:19464/metrics (download)" -ForegroundColor White
Write-Host "- gRPC metrics: http://localhost:29464/metrics (playlist)" -ForegroundColor White

Write-Ok "Finalizado."
