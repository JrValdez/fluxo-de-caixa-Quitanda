# Deploy — Fluxo de Caixa (VPS grupof2.tech, caminho /quitanda)

Stack em Docker (PostgreSQL + API .NET + Flutter Web/nginx), exposta sob
`https://grupof2.tech/quitanda/` via reverse proxy do nginx do host.

## Estrutura no servidor
- Projeto em `/opt/fluxocaixa`
- Compose de produção: `/opt/fluxocaixa/deploy/docker-compose.prod.yml`
- Segredos: `/opt/fluxocaixa/deploy/.env` (fora do Git)
- Container web publicado em `127.0.0.1:8091` (host), proxied pelo nginx.

## 1. Enviar o código (a partir da máquina local)
```bash
git archive --format=tar.gz --prefix=fluxocaixa/ -o fluxocaixa.tar.gz HEAD
scp fluxocaixa.tar.gz root@179.197.78.125:/tmp/
ssh root@179.197.78.125 "rm -rf /opt/fluxocaixa && mkdir -p /opt/fluxocaixa && tar xzf /tmp/fluxocaixa.tar.gz -C /opt --strip-components=0"
```

## 2. Criar o .env de produção (no servidor, uma vez)
```bash
cd /opt/fluxocaixa/deploy
cp .env.example .env
# edite POSTGRES_PASSWORD e JWT_KEY com valores fortes (openssl rand -base64 48)
```

## 3. Subir a stack
```bash
cd /opt/fluxocaixa/deploy
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
```

## 4. nginx do host (uma vez)
Adicione os blocos de `nginx-host-quitanda.conf.example` no server block HTTPS
do `/etc/nginx/sites-enabled/grupof2.tech` (antes do `location /`), então:
```bash
nginx -t && systemctl reload nginx
```

## Atualizações futuras
Repita os passos 1 e 3 (o `--build` reconstrói as imagens). O `.env` e o volume
`fluxocaixa_pgdata` (dados) são preservados.

## Acesso
- App: https://grupof2.tech/quitanda/
- Login inicial: junior322222@gmail.com / 123456
