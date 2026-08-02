# Handoff — Fluxo de Caixa (Quitandas da Badia)

> **PROJETO COMPLETO** — todas as 8 fases (0–7) do guia entregues e validadas (2026-08-02).

## Situação geral
Projeto **.NET 10 + Flutter Web + PostgreSQL (Docker)**. Progresso:

- ✅ **Fase 0** — Fundação/infra (Docker Postgres, solução .NET, EF, Swagger, tema)
- ✅ **Fase 1** — Auth JWT + perfis (Admin/Operador/Visualizador) + gestão de usuários
- ✅ **Fase 2** — Cadastros (contas, categorias+subcategorias, contrapartes, formas de pagamento)
- ✅ **Fase 3** — Transações, saldos, agenda, efetivar, recorrências (+ serviço em background)
- ✅ **Fase 4** — Dashboards & relatórios (gráficos linha+barra, DRE, KPIs, export PDF/Excel)
- ✅ **Fase 5** — Projeções & simulações (projeção 7/13/30/90 dias, simulador "e se", capital de giro)
- ✅ **Fase 6** — Estoque (produtos, movimentação compra/venda/ajuste, custo médio, integração com o caixa)
- ✅ **Fase 7** — Automações & extras (alertas + sino, auditoria de alterações, backup JSON, importação/conciliação CSV; multi-moeda no modelo de dados)

Plano completo: `~/.claude/plans/bright-launching-bunny.md`.

## Fase 7 — notas
- **Alertas**: `GET /api/alertas` (atrasos, vencimentos próximos, saldo projetado negativo, estoque baixo); sino com contador na barra superior + página `/alertas`.
- **Auditoria**: `AppDbContext.SaveChangesAsync` intercepta mudanças e grava em `AuditLog` (usuário via `ICurrentUser`/HttpContext); página `/auditoria` (Admin) + botão de backup.
- **Backup**: `GET /api/admin/backup` exporta JSON de todas as tabelas de negócio (Admin).
- **Conciliação**: `POST /api/conciliacao/importar` (CSV `data;descrição;valor`, negativo=saída) casa com previstas; `POST /api/conciliacao/conciliar` efetiva a correspondente ou cria nova. Validado via API. (OFX pode ser adicionado como parser futuro.)
- **Multi-moeda**: campos `Moeda` em Conta/Transação já existem; conversão cambial (FX) não implementada — melhoria futura.

---

## ✅ Fase 4 concluída (validada no navegador em 2026-08-01)

- KPIs do dashboard (Saldo, Entradas, Saídas, Resultado, A receber, A pagar) ✅
- Gráfico de **linha** "Saldo ao longo do mês" (CustomPaint próprio) ✅
- Gráfico de **barras** "Movimentação por categoria" ✅ (bug do EF Core no `GroupBy` já corrigido —
  `RelatoriosController.PorCategoria` agora agrupa em memória)
- Página **Relatórios**: KPIs (ticket médio, PMR, PMP, inadimplência, liquidez), DRE simplificado ✅
- **Exportação** Excel (transações) e PDF (DRE) — gera `.xlsx` (PK/zip) e `.pdf` (%PDF) ✅

> Observação de modelagem: o total por categoria soma todas as transações da categoria.
> Como cada categoria tem um Tipo (Receita/Despesa), a barra fica verde ou vermelha conforme o tipo.

---

## Como rodar (dev)

### 1. PostgreSQL (Docker)
```bash
cd "C:/Users/josee/projeto/Fluxo de Caixa"
docker compose up -d postgres
```

### 2. Backend (.NET) — porta 5080
```bash
cd "C:/Users/josee/projeto/Fluxo de Caixa/backend/FluxoCaixa.Api"
dotnet run --urls http://localhost:5080
```
- Migrations + seed rodam no startup. Swagger: http://localhost:5080/swagger
- Login seed: **admin@quitandasdabadia.com / Badia@2026**

### 3. Frontend (Flutter Web)
Modo dev normal:
```bash
cd "C:/Users/josee/projeto/Fluxo de Caixa/frontend/fluxo_caixa_app"
flutter run -d chrome --dart-define=API_URL=http://localhost:5080
```

---

## Aprendizados / armadilhas importantes (LER antes de validar no navegador)

1. **O "congelamento" da tela NÃO era bug do código.** Era o **navegador sobrecarregado**
   por ter ~10 abas abertas rodando o app Flutter (cada uma consome CPU/GPU com CanvasKit).
   Sintoma: `CDP captureScreenshot timed out`. **Solução: manter só 1 aba do app aberta.**
2. Para validação visual confiável, o **build release servido estaticamente** foi muito mais
   estável que o `flutter run -d web-server` (DDC/DWDS ficou instável após muitos restarts):
   ```bash
   cd frontend/fluxo_caixa_app
   flutter build web --release
   cd build/web
   py -m http.server 8090 --bind 127.0.0.1   # usar 'py', não 'python' (venv do hermes falha)
   ```
   Abrir http://127.0.0.1:8090 (novo origin = precisa logar de novo).
3. Ao recompilar o backend, **pare a API antes** (o processo trava os DLLs → erro MSB3027).
4. A solução usa **`FluxoCaixa.slnx`** (não `.sln`). Build: `dotnet build FluxoCaixa.slnx`.
5. Enums são serializados como **string** no JSON (`JsonStringEnumConverter` no Program.cs);
   o front espelha isso (mapas de labels em `cadastro_models.dart` / `transacao_models.dart`).
6. `fl_chart` foi **removido**; os gráficos usam `CustomPaint` próprio em
   `frontend/.../features/relatorios/presentation/widgets/graficos.dart` (line + bar).
7. Download de arquivo no web: `frontend/.../core/utils/download_web.dart` (usa `package:web` + `dart:js_interop`).

---

## Estado dos serviços neste momento
- Docker Postgres: rodando (container `fluxocaixa-postgres`, porta 5432).
- API .NET: rodando em http://localhost:5080 (background).
- Servidor estático do build release: http://127.0.0.1:8090 (background, `py -m http.server`).
- Vários `flutter run` de debug foram encerrados durante a depuração.

> Ao retomar, pode ser mais simples **encerrar os processos em background** e subir tudo do zero
> pelos comandos da seção "Como rodar".

---

## Passe de UI/UX (ui-ux-pro-max, 2026-08-02)
Estilo validado: **"Nature Distilled"** (terracota/creme/artesanal — coerente com a marca). Aplicado:
- **Contraste WCAG AA**: `AppColors.alerta` escurecido de `#E0A106` → `#A16207` (~5:1 em fundo claro);
  tom claro preservado em `alertaFundo` para tints/fundos.
- **Sombras naturais suaves** (`AppColors.sombraCard`) em todos os cards de KPI/indicadores + `CardTheme`.
- **Skeleton loading** (`Esqueleto`, `EsqueletoKpi`, `EsqueletoLista` em `core/widgets/estados.dart`)
  substituindo spinners no dashboard, transações, estoque e contas — respeita `disableAnimations`.
- **Empty states** (`EstadoVazio`: ícone + título + mensagem + CTA) em transações, estoque, contas e agenda.
- **DataTable theme global**: cabeçalhos com hierarquia, hover nas linhas (cremeClaro) e
  **números tabulares** (`FontFeature.tabularFigures`) para colunas de valores.
- **Login**: `autofillHints` (username/email/password).
- **Passe estendido a TODAS as telas** (2ª rodada): categorias, clientes/fornecedores, formas de
  pagamento, recorrências, usuários, auditoria, alertas, projeções (projeção + capital de giro +
  simulador), relatórios (KPIs + DRE) e conciliação — todos com skeleton no loading e
  `EstadoVazio` (com CTA quando o usuário pode editar) no vazio. Nenhum spinner de página restante.

## Correção da TELA BRANCA (2026-08-02) — bug crítico resolvido
**Sintoma:** alguns cliques em botões deixavam o app em tela branca permanente.
**Causa raiz** (encontrada via reprodução em modo debug): **duplo pop de navegação**. Os botões
dos diálogos chamavam `Navigator.pop(context)`; com clique duplo rápido (ou clique durante a
animação de fechamento), o 2º pop removia a própria página da pilha do go_router
("You have popped the last page off of the stack") → navigator corrompido → cena vazia →
o engine removia o canvas → tela branca sem erro no console.
**Correções aplicadas:**
1. `lib/core/utils/dialogos.dart` — helper `fecharDialogo(context, [resultado])` que só faz pop
   se `ModalRoute.of(context).isCurrent` (ignora o 2º toque). **Todos os 27 pontos de
   `Navigator.pop` em diálogos foram trocados** por ele; os 3 diálogos inline que usavam o
   context da página (confirmarExclusao, subcategoria, redefinir senha) passaram a usar o
   context do próprio builder (`dctx`).
2. `web/index.html` — **watchdog**: se a superfície de render do Flutter sumir por >3s,
   recarrega a página automaticamente (rota preservada pelo hash; login preservado).
   Rede de segurança para qualquer falha de render futura.
**Validação:** sequência letal reproduzida antes/depois (fechar diálogo + abrir dropdown em
rajada; triplo clique em Cancelar em vários diálogos) — sem tela branca, sem reload, app segue vivo.
**Regra para novos diálogos:** sempre fechar com `fecharDialogo(...)` (nunca `Navigator.pop` direto)
e usar o context do builder do diálogo, não o da página.

## Marca no navbar + tela de carregamento (2026-08-02)
- **Splash screen** com a marca em `web/index.html`: fundo terracota, logo em anel branco,
  "Fluxo de Caixa / Quitandas da Badia" e spinner. Some no evento `flutter-first-frame`.
  O logo foi copiado para `web/logo.jpg` (acessível antes do Flutter carregar) e também virou o **favicon**.
- **Logo na barra superior** (`_TopBar`): avatar circular + "Fluxo de Caixa · Quitandas da Badia".
- **Logo no menu lateral** destacado com anel branco e sombra.
- **Campos de moeda com auto-formato** (cada dígito = centavo, formata pt-BR ao vivo) em
  `core/utils/moeda_input.dart` (`MoedaInputFormatter` + `parseMoeda` + `moedaInicial`).
  Aplicado em TODOS os campos monetários: produto (preço/custo), transação (valor), movimentação
  de estoque (custo unitário/valor no caixa), simulação (valor), recorrência (valor) e conta (saldo inicial).
  Regra p/ novos campos R$: `inputFormatters: [MoedaInputFormatter()]`, salvar com `parseMoeda(ctrl.text)`,
  valor inicial com `moedaInicial(valor)`. Quantidades (kg/un) continuam com parse decimal normal.

## Melhorias futuras (opcionais — fora do escopo do guia)
- Parser OFX (hoje a conciliação aceita CSV).
- Conversão cambial (FX) para multi-moeda (campos de moeda já existem).
- Backup agendado/automático (hoje é download JSON sob demanda).
- Paginação nas listagens grandes; testes automatizados de UI.

## Dados de teste já cadastrados
- Conta: "Caixa da Loja" (saldo inicial R$ 1.500)
- Categoria: "Vendas de quitandas" (Receita/Operacional)
- Transações: 1 entrada R$ 250,50 (realizada) e 1 saída R$ 80,00 (realizada)
- Saldo atual: R$ 1.670,50
