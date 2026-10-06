# Verificador · Avaliação Prática de Docker · ViaSerra Transportes (Turma C)
# Rode da RAIZ do projeto, com o docker compose no ar:
#   powershell -ExecutionPolicy Bypass -File scripts\verificar.ps1
# Não precisa de Python. O verificador aponta o que está errado, não como consertar.

$TURMA = "C"
$PREFIXO = "viaserra"
$SAL = "DEVOPS-DOCKER-2026"

Set-Location (Join-Path $PSScriptRoot "..")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"
$script:NumOk = 0; $script:NumTotal = 0

function Checar($codigo, $descricao, [bool]$passou, $dica) {
  $script:NumTotal++
  if ($passou) { $script:NumOk++; Write-Host "[ OK ] $codigo $descricao" -ForegroundColor Green }
  else { Write-Host "[FALHA] $codigo $descricao" -ForegroundColor Red; if ($dica) { Write-Host "         -> $dica" } }
}
function Http($url) {
  try {
    $c = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8).Content
    if ($c -is [byte[]]) { $c = [System.Text.Encoding]::UTF8.GetString($c) }
    return [string]$c
  } catch { return "" }
}
function Status($url) {
  try { return (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10).StatusCode } catch { return 0 }
}
function Cid($svc) { $r = docker compose ps -q $svc 2>$null; if ($r) { return ($r | Select-Object -First 1).Trim() } return "" }
function Insp($id, $fmt) { if (-not $id) { return "" }; $r = docker inspect -f $fmt $id 2>$null; return ($r -join " ").Trim() }

Write-Host "================================================================"
Write-Host " Verificador · Avaliação Prática de Docker · Turma $TURMA"
Write-Host "================================================================"

if (-not (Test-Path docker-compose.yml)) { Write-Host "Rode na raiz do projeto (onde fica o docker-compose.yml)."; exit 2 }
if (-not (Test-Path .env)) { Write-Host "[FALHA] arquivo .env não encontrado. Copie o .env.example e preencha."; exit 2 }
$envs = @{}
Get-Content .env | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_]+)\s*=\s*(.*)$') { $envs[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'") }
}
$MAT = $envs["MATRICULA"]; $HUB = $envs["DOCKERHUB_USER"]
if (-not ($MAT -match '^\d{4,15}$')) { Write-Host "[FALHA] MATRICULA ausente ou inválida no .env."; exit 2 }
$XX = [int]$MAT.Substring($MAT.Length - 2)
$P_PORTAL = 8000 + $XX; $P_MANUT = 7000 + $XX
$IMG = "$HUB/$PREFIXO-portal:1.0-$MAT"
Write-Host " Matrícula $MAT · portal $P_PORTAL · manutenção $P_MANUT`n"

Write-Host "A. Arquivos e Git"
$DF = "portal/Dockerfile"; $passou = $false; $dica = "portal/Dockerfile não encontrado"
if (Test-Path $DF) {
  $linhas = Get-Content $DF
  $from = ($linhas | Where-Object { $_ -match '^\s*FROM\s+' } | Select-Object -First 1) -replace '^\s*FROM\s+', ''
  $from = ($from -split '\s+')[0]
  $passou = $true; $dica = ""
  if (-not ($from -match ':') -or $from -match ':latest') { $passou = $false; $dica += "imagem base sem tag fixa (ou :latest). " }
  if (-not ($linhas -match '^\s*COPY\s')) { $passou = $false; $dica += "sem COPY. " }
  if (-not ($linhas -match '^\s*EXPOSE\s+80\b')) { $passou = $false; $dica += "sem EXPOSE 80. " }
  if (-not ($linhas -match '^\s*LABEL\s')) { $passou = $false; $dica += "sem LABEL. " }
}
Checar "A1" "portal/Dockerfile segue os requisitos" $passou $dica

$tracked = git ls-files .env 2>$null
$gi = if (Test-Path .gitignore) { Get-Content .gitignore } else { @() }
$ex = git ls-files .env.example 2>$null
$passou = (-not $tracked) -and [bool]($gi -match '^\s*/?\.env\s*$') -and ($ex -eq ".env.example")
Checar "A2" ".env fora do Git e .env.example versionado" $passou "confira o .gitignore e rode: git ls-files"

$N = 0; $c = git rev-list --count HEAD 2>$null; if ($c) { $N = [int]$c }
$rem = (git remote -v 2>$null) -join " "
Checar "A3" "4+ commits e remoto no GitHub (encontrados: $N)" (($N -ge 4) -and ($rem -match "github.com")) "faça um commit por parte e configure o origin"

$passou = $false
if ($HUB) { $passou = (Status "https://hub.docker.com/v2/repositories/$HUB/$PREFIXO-portal/tags/1.0-$MAT") -eq 200 }
Checar "A4" "imagem $IMG pública no Docker Hub" $passou "não encontrada: repositório privado, tag fora da regra ou sem internet"

Write-Host "`nB. docker compose"
if (Select-String -Path docker-compose.yml -Pattern '____' -SimpleMatch -Quiet) { Write-Host "         (ainda há lacunas ____ no docker-compose.yml)" }
$PORTAL = Cid "portal"; $MANUT = Cid "manutencao"
$passou = $true; foreach ($x in @($PORTAL, $MANUT)) { if ((Insp $x "{{.State.Running}}") -ne "true") { $passou = $false } }
Checar "B1" "serviços portal e manutencao em execução" $passou "rode docker compose up -d e confira com docker compose ps"

$imgUso = Insp $PORTAL "{{.Config.Image}}"
Checar "B2" "portal roda a imagem publicada" ($imgUso -eq $IMG) "imagem em uso: $imgUso"

$pp = (docker compose port portal 80 2>$null) -join " "; $pm = (docker compose port manutencao 80 2>$null) -join " "
Checar "B3" "portas: portal em $P_PORTAL e manutenção em $P_MANUT" (($pp -match ":$P_PORTAL\b") -and ($pm -match ":$P_MANUT\b")) "portal=$pp manutencao=$pm"

Write-Host "`nC. Conteúdo"
$pag = Http "http://localhost:$P_PORTAL/"
Checar "C1" "portal mostra seu nome e sua matrícula" (($pag -match $MAT) -and ($pag -notmatch "SEU NOME AQUI")) "edite o rodapé do index.html, reconstrua, publique e recrie o container"

$man = Http "http://localhost:$P_MANUT/"
Checar "C2" "página de manutenção servindo o aviso `"Voltamos em breve`"" ($man -match "PAGINA-MANUTENCAO-OK") "o container responde, mas não com a página de manutenção (ou não responde)"

Write-Host "`n================================================================"
Write-Host " Resultado: $($script:NumOk)/$($script:NumTotal) verificações"
if ($script:NumOk -eq $script:NumTotal) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("${TURMA}:${MAT}:$SAL"))
  $h = (($bytes | ForEach-Object { $_.ToString("x2") }) -join "").Substring(0, 8).ToUpper()
  Write-Host " Código de conclusão: $($PREFIXO.ToUpper())-$MAT-$h" -ForegroundColor Cyan
  Write-Host " Copie o código para o respostas.md, tire o print desta tela e faça o commit final."
} else { Write-Host " Ainda há falhas. Corrija e rode de novo." }
Write-Host "================================================================"
if ($script:NumOk -eq $script:NumTotal) { exit 0 } else { exit 1 }
