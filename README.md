# Portal ViaSerra Transportes

Avaliação prática de Docker · DevOps e Cloud Computing · Turma C
Individual · 2 horas. O enunciado completo está no guia em Word; este README é só o mapa do pacote.

## O que vem no pacote

```
portal/html/          site institucional (você edita só o rodapé do index.html)
manutencao/
  Dockerfile          herdado do fornecedor anterior, com defeitos
  site/index.html     página "Voltamos em breve"
docker-compose.yml    modelo com 4 lacunas para completar na Parte 4
scripts/
  verificar.sh        verificador para Linux, macOS e Git Bash
  verificar.ps1       verificador para Windows PowerShell
.env.example          modelo das variáveis de ambiente
respostas.md          suas respostas (vai para o Git)
```

## O que você cria

`portal/Dockerfile`, `.gitignore` e `.env` (este fica fora do Git). Você também corrige
`manutencao/Dockerfile` e completa o `docker-compose.yml`.

## Suas portas

Use os dois últimos dígitos da matrícula (XX). Matrícula terminada em 42:

| Serviço | Regra | Exemplo |
|---|---|---|
| Portal | 8000 + XX | 8042 |
| Página de manutenção | 7000 + XX | 7042 |
