# Respostas · Avaliação Prática de Docker · ViaSerra Transportes (Turma C)

Nome: Brenda Silva Tsutake

Matrícula: 26174720

Usuário do GitHub: BrendaTsutake

Usuário do Docker Hub: brendatsutake

Responda com as suas palavras e com o que aconteceu na SUA máquina. Resposta curta e certa vale mais
do que texto longo copiado. Resposta que contradiz o seu próprio Dockerfile vale zero.

## Parte 1 · Dockerfile do portal

1. Qual imagem base você usou e qual o tamanho final da imagem do portal (saída de `docker images`)?
Usei a imagem base nginx:1.27-alpine. O tamanho final exibido pelo comando docker images foi 73,6 MB.

2. Em qual pasta do container o Nginx procura os arquivos do site? Mostre o comando que você usou para
conferir que o `index.html` está lá dentro.

O Nginx procura os arquivos do site em /usr/share/nginx/html.



Comando utilizado:

docker exec avaliacao-docker-viaserra-portal-1 ls /usr/share/nginx/html



## Parte 2 · Docker Hub

3. Nome completo da imagem publicada e link público do repositório no Docker Hub.

Imagem: brendatsutake/viaserra-portal:1.0-26174720

Repositório público: brendatsutake/viaserra-portal



3. Se você mudar o HTML, quais comandos precisa rodar para que a versão nova chegue ao Docker Hub?

É necessário reconstruir a imagem e depois enviá-la novamente ao Docker Hub:



docker build -t brendatsutake/viaserra-portal:1.0-26174720 ./portal

docker push brendatsutake/viaserra-portal:1.0-26174720





## Parte 3 · Página de manutenção

5. Preencha uma linha por defeito encontrado. Defeito inexistente listado aqui desconta pontos.

|#|Instrução|O que estava errado|O que você viu acontecer|Como corrigiu|
|-|-|-|-|-|
|1 |COPY pagina/ .|A pasta pagina não existia. A pasta correta era site.|O build falhou mostrando "/pagina": not found.|Alterei para COPY site/ ..|
|2|Inicialização do Nginx|O container não permanecia em execução.|O docker ps -a mostrou o container como Exited (0).|Adicionei CMD \["nginx", "-g", "daemon off;"].|
|3|WORKDIR /usr/share/nginx|Os arquivos foram copiados fora da pasta padrão servida pelo Nginx|Ao acessar localhost:7020, apareceu Welcome to nginx!.|Alterei para WORKDIR /usr/share/nginx/html.|

6. Qual a diferença entre `-p 7042:80` e `-p 80:7042` no `docker run`? Qual dos dois números é a porta do container?

No docker run, o formato é -p PORTA\_DO\_HOST:PORTA\_DO\_CONTAINER.



Em -p 7042:80, a porta 7042 é a porta do computador (host) e a porta 80 é a porta do container.



Em -p 80:7042, a porta 80 é a porta do computador (host) e a porta 7042 é a porta do container.



Portanto, o segundo número é a porta do container.



## Parte 4 · Primeiro docker-compose

7. Escreva os dois comandos `docker run` que fariam o mesmo que o seu `docker-compose.yml`.

docker run -d --name portal -p 8020:80 --restart unless-stopped brendatsutake/viaserra-portal:1.0-26174720



docker run -d --name manutencao -p 7020:80 --restart unless-stopped manutencao:26174720



7. Qual comando derruba os dois containers de uma vez?

docker compose down

## Verificador

9. Código de conclusão impresso pelo verificador:

VIASERRA-26174720-D190E321 Resultado: 9/9 verificações

