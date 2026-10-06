#!/usr/bin/env bash
# Verificador · Avaliação Prática de Docker · ViaSerra Transportes (Turma C)
# Rode da RAIZ do projeto, com o docker compose no ar:   bash scripts/verificar.sh
# Funciona no Linux, no macOS e no Git Bash do Windows. Não precisa de Python.
# O verificador aponta o que está errado, não como consertar.

TURMA="C"
PREFIXO="viaserra"
SAL="DEVOPS-DOCKER-2026"

cd "$(dirname "$0")/.." || exit 2
OK=0; TOTAL=0

checar() {  # checar CODIGO "descrição" resultado(0=ok) "dica"
  TOTAL=$((TOTAL+1))
  if [ "$3" -eq 0 ]; then OK=$((OK+1)); echo "[ OK ] $1 $2"
  else echo "[FALHA] $1 $2"; [ -n "$4" ] && echo "         -> $4"; fi
}
http() { curl -s -m 8 "$1" 2>/dev/null; }
cid() { docker compose ps -q "$1" 2>/dev/null | head -n1; }
insp() { [ -n "$1" ] && docker inspect -f "$2" "$1" 2>/dev/null; }

echo "================================================================"
echo " Verificador · Avaliação Prática de Docker · Turma $TURMA"
echo "================================================================"

[ -f docker-compose.yml ] || { echo "Rode na raiz do projeto (onde fica o docker-compose.yml)."; exit 2; }
[ -f .env ] || { echo "[FALHA] arquivo .env não encontrado. Copie o .env.example e preencha."; exit 2; }
val() { grep -E "^$1=" .env | head -n1 | cut -d= -f2- | tr -d '\r"'"'" | xargs; }
MAT=$(val MATRICULA); HUB=$(val DOCKERHUB_USER)
if ! echo "$MAT" | grep -Eq '^[0-9]{4,15}$'; then echo "[FALHA] MATRICULA ausente ou inválida no .env."; exit 2; fi
XX=$((10#${MAT: -2}))
P_PORTAL=$((8000+XX)); P_MANUT=$((7000+XX))
IMG="$HUB/$PREFIXO-portal:1.0-$MAT"
echo " Matrícula $MAT · portal $P_PORTAL · manutenção $P_MANUT"
echo

echo "A. Arquivos e Git"
DF=portal/Dockerfile; r=1; dica="portal/Dockerfile não encontrado"
if [ -f "$DF" ]; then
  FROM=$(grep -iE '^\s*FROM' "$DF" | head -n1 | awk '{print $2}')
  r=0; dica=""
  echo "$FROM" | grep -q ':' && ! echo "$FROM" | grep -q ':latest' || { r=1; dica="imagem base sem tag fixa (ou :latest). "; }
  grep -iqE '^\s*COPY' "$DF" || { r=1; dica="${dica}sem COPY. "; }
  grep -iqE '^\s*EXPOSE\s+80\b' "$DF" || { r=1; dica="${dica}sem EXPOSE 80. "; }
  grep -iqE '^\s*LABEL' "$DF" || { r=1; dica="${dica}sem LABEL. "; }
fi
checar A1 "portal/Dockerfile segue os requisitos" $r "$dica"

r=0
[ -n "$(git ls-files .env 2>/dev/null)" ] && r=1
grep -Eq '^\s*/?\.env\s*$' .gitignore 2>/dev/null || r=1
[ "$(git ls-files .env.example 2>/dev/null)" = ".env.example" ] || r=1
checar A2 ".env fora do Git e .env.example versionado" $r "confira o .gitignore e rode: git ls-files"

N=$(git rev-list --count HEAD 2>/dev/null || echo 0)
r=1; [ "$N" -ge 4 ] && git remote -v 2>/dev/null | grep -q github.com && r=0
checar A3 "4+ commits e remoto no GitHub (encontrados: $N)" $r "faça um commit por parte e configure o origin"

r=1; [ -n "$HUB" ] && [ "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "https://hub.docker.com/v2/repositories/$HUB/$PREFIXO-portal/tags/1.0-$MAT")" = "200" ] && r=0
checar A4 "imagem $IMG pública no Docker Hub" $r "não encontrada: repositório privado, tag fora da regra ou sem internet"

echo
echo "B. docker compose"
grep -q '____' docker-compose.yml && echo "         (ainda há lacunas ____ no docker-compose.yml)"
PORTAL=$(cid portal); MANUT=$(cid manutencao)
r=0; for c in "$PORTAL" "$MANUT"; do [ "$(insp "$c" '{{.State.Running}}')" = "true" ] || r=1; done
checar B1 "serviços portal e manutencao em execução" $r "rode docker compose up -d e confira com docker compose ps"

r=1; [ "$(insp "$PORTAL" '{{.Config.Image}}')" = "$IMG" ] && r=0
checar B2 "portal roda a imagem publicada" $r "imagem em uso: $(insp "$PORTAL" '{{.Config.Image}}')"

r=1
docker compose port portal 80 2>/dev/null | grep -q ":$P_PORTAL$" && docker compose port manutencao 80 2>/dev/null | grep -q ":$P_MANUT$" && r=0
checar B3 "portas: portal em $P_PORTAL e manutenção em $P_MANUT" $r "portal=$(docker compose port portal 80 2>/dev/null) manutencao=$(docker compose port manutencao 80 2>/dev/null)"

echo
echo "C. Conteúdo"
PAG=$(http "http://localhost:$P_PORTAL/")
r=1; echo "$PAG" | grep -q "$MAT" && ! echo "$PAG" | grep -q "SEU NOME AQUI" && r=0
checar C1 "portal mostra seu nome e sua matrícula" $r "edite o rodapé do index.html, reconstrua, publique e recrie o container"

r=1; http "http://localhost:$P_MANUT/" | grep -q "PAGINA-MANUTENCAO-OK" && r=0
checar C2 "página de manutenção servindo o aviso \"Voltamos em breve\"" $r "o container responde, mas não com a página de manutenção (ou não responde)"

echo
echo "================================================================"
echo " Resultado: $OK/$TOTAL verificações"
if [ "$OK" -eq "$TOTAL" ]; then
  if command -v sha256sum >/dev/null 2>&1; then H=$(printf '%s' "$TURMA:$MAT:$SAL" | sha256sum | cut -c1-8)
  else H=$(printf '%s' "$TURMA:$MAT:$SAL" | shasum -a 256 | cut -c1-8); fi
  echo " Código de conclusão: $(echo "$PREFIXO" | tr a-z A-Z)-$MAT-$(echo "$H" | tr a-f A-F)"
  echo " Copie o código para o respostas.md, tire o print desta tela e faça o commit final."
else
  echo " Ainda há falhas. Corrija e rode de novo."
fi
echo "================================================================"
[ "$OK" -eq "$TOTAL" ]
