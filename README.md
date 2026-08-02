# Fluxo de Caixa — Quitandas da Badia

Sistema de gestão de fluxo de caixa (entradas/saídas, contas a pagar/receber,
projeções, dashboards) para a **Quitandas da Badia**.

## Stack
- **Backend:** .NET 10 (ASP.NET Core Web API) — arquitetura em camadas
  (Domain / Application / Infrastructure / Api), EF Core + PostgreSQL, Identity + JWT.
- **Frontend:** Flutter Web (Riverpod, go_router, dio, fl_chart).
- **Banco:** PostgreSQL 17 via Docker.

## Pré-requisitos
- .NET SDK 10, Flutter 3.44+, Docker.

## Como rodar (desenvolvimento)

### 1. Banco de dados
```bash
docker compose up -d postgres
# opcional: pgAdmin em http://localhost:5050
# docker compose --profile tools up -d
```

### 2. Backend (API)
```bash
cd backend/FluxoCaixa.Api
dotnet run --urls http://localhost:5080
```
- As migrations são aplicadas e o seed é executado automaticamente no startup.
- Swagger: http://localhost:5080/swagger
- Health: http://localhost:5080/health

### 3. Frontend (Flutter Web)
```bash
cd frontend/fluxo_caixa_app
flutter run -d chrome --dart-define=API_URL=http://localhost:5080
```

## Acesso inicial (seed)
- **E-mail:** junior322222@gmail.com
- **Senha:** 123456
- Perfis: **Admin** (tudo), **Operador** (lança dados), **Visualizador** (leitura).

> Troque a chave JWT e a senha do admin em produção (ver `appsettings.json` / seção `Seed` e `Jwt`).

## Estrutura
```
backend/    solução .NET (FluxoCaixa.slnx)
frontend/   app Flutter (fluxo_caixa_app)
docker-compose.yml
```

## Status por fase
- [x] Fase 0 — Fundação/infra (Docker, solução, EF, Swagger, tema)
- [x] Fase 1 — Autenticação e usuários (JWT, perfis, gestão de usuários)
- [x] Fase 2 — Cadastros base (contas, categorias, contrapartes, formas de pagamento)
- [x] Fase 3 — Transações e saldos (lançamentos, efetivar, agenda, recorrências, KPIs)
- [x] Fase 4 — Dashboards e relatórios (gráficos, DRE, KPIs avançados, export PDF/Excel)
- [x] Fase 5 — Projeções e simulações (projeção 7/13/30/90 dias, simulador "e se", capital de giro)
- [x] Fase 6 — Estoque (produtos, movimentação compra/venda/ajuste, custo médio, integração com o caixa)
- [x] Fase 7 — Automações e extras (alertas, auditoria, backup, importação/conciliação CSV, multi-moeda no modelo)

**Projeto completo — todas as fases do guia entregues. ✅**
