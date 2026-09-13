# Plano: gerar `API_GATEWAY_PLAN.md`

## Context

O frontend React (`penny`) consome um backend que já vive atrás de um API Gateway
(`https://mkjmiykj5c.execute-api.us-east-2.amazonaws.com/dev`), mas nada dessa infra está
versionado. Antes de escrever Terraform, é preciso um inventário confiável de: quais chamadas
HTTP existem de fato no código, quais telas ainda são 100% mock/hardcoded, e qual contrato de API
essas telas exigiriam. O entregável desta etapa é **apenas o documento** `API_GATEWAY_PLAN.md` na
raiz do projeto (`penny/API_GATEWAY_PLAN.md`) — nenhum `.tf`, nenhuma alteração em `src/`.

Decisões confirmadas com o usuário, a serem adotadas no documento:
- **API Gateway HTTP API (v2)** — `aws_apigatewayv2_*`.
- **Integração Lambda proxy (`AWS_PROXY`)**, uma Lambda por domínio.
- **Apenas o ambiente `dev`** (multi-ambiente fica como evolução futura/pendência).

## Achados da análise (base factual do documento)

### Configuração e clientes HTTP
- Base URL única e **hardcoded** em [settings.ts:2](src/config/dev/settings.ts#L2). Não há `.env`
  nem `REACT_APP_*` em lugar nenhum (confirmado por grep em `src/`).
- Dois clientes coexistem: `fetch` puro em todos os services reais, e um axios em
  [base.ts](src/services/base.ts) que é **código morto** — nenhum arquivo o importa, e seu
  `baseURL` está errado (`.../dev/auth`) enquanto seu interceptor lê a chave `token`, que nunca é
  gravada (o `AuthContext` grava `@app:token`).

### Chamadas HTTP encontradas no código (5 endpoints, 1 base URL)
| Método | Path | Service | Chamado por |
|---|---|---|---|
| POST | `/auth` | [auth.ts](src/services/auth.ts) `post_auth` | [SignIn.tsx:26](src/pages/SignIn/SignIn.tsx#L26) |
| POST | `/cards` | [card.ts](src/services/card.ts) `post_card` | [NewCard.tsx:51](src/pages/NewCard/NewCard.tsx#L51) |
| GET | `/cards/{idUser}` | [card.ts](src/services/card.ts) `get_cards` | [Cards.tsx:39](src/pages/Cards/Cards.tsx#L39), [Expenses.tsx:98](src/pages/Expenses/Expenses.tsx#L98) |
| POST | `/expenses` | [expense.ts](src/services/expense.ts) `post_expense` | [Expenses.tsx:85](src/pages/Expenses/Expenses.tsx#L85) |
| POST | `/incomes` | [income.ts](src/services/income.ts) `post_income` | [Incomes.tsx:52](src/pages/Incomes/Incomes.tsx#L52) |
| GET | `/transactions?…` | [transactions.ts](src/services/transactions.ts) `get_transactions` | [Transactions.tsx:52](src/pages/Transactions/Transactions.tsx#L52) |

`/transactions` usa query string com `id_user`, `dt_end`, `limit`, `cursor`,
`de_type_transaction`, `id_transaction` (paginação por cursor; o frontend faz um loop fixo de 5
páginas). [user.ts](src/services/user.ts) tem um `post_user` stub que retorna `{}` — sem HTTP.

Contratos de request/response estão tipados em `src/services/types/{requests,responses}/` e devem
ser transcritos **literalmente** no documento (incluindo o bug de tipo
`de_expense_subcategory: number` em [post-expense-response.ts](src/services/types/responses/post-expense-response.ts)).

### Autenticação (inconsistente — ponto de atenção central)
- `/auth` não envia `Authorization`; devolve `response.authorization`, salvo em `localStorage`
  como `@app:token` por [AuthContext.tsx:31](src/context/AuthContext.tsx#L31).
- Os demais services enviam `Authorization: ${localStorage.getItem("@app:token")}` — **sem o
  prefixo `Bearer`** (auth.ts, card.ts, expense.ts, income.ts, transactions.ts).
- `AuthProvider` **não está montado** em [App.tsx](src/App.tsx) nem em
  [Router.tsx](src/router/Router.tsx); `useAuth()` em [SignIn.tsx:19](src/pages/SignIn/SignIn.tsx#L19)
  lançaria erro. As telas contornam lendo `localStorage` diretamente.
- Não há rota protegida, nem refresh token, nem tratamento de 401.

### Tratamento de erros
Idêntico em todos os services: `if (!response.ok) throw new Error(...)` — sem distinguir status
code, sem ler o corpo do erro. Mensagem copiada/colada ("Erro ao autenticar usuário") mesmo em
card.ts, expense.ts e income.ts. Nas telas, o `catch` só faz `console.error`, e o `finally` navega
para a próxima tela **mesmo em caso de falha** (NewCard, Incomes, Expenses).

### Inventário de telas (17 rotas em Router.tsx) e classificação
- `API IMPLEMENTADA`: SignIn (`/`), Cards (`/cartoes`), NewCard (`/novo-cartao`).
- `API PARCIALMENTE IMPLEMENTADA`: Transactions (`/transacoes` — lista vem da API, mas os totais
  "R$ 6.310,67 / 9.450,30 / 3.139,63" são hardcoded); Incomes (`/faturamentos` — POST existe, mas
  dropdowns vêm de JSON local e `id_income_category` é fixo em `1`); Expenses (`/gastos` — POST
  existe, mas `id_payment_type: 3`, `id_expense: 0`, `id_user_bank_account: 6` são hardcoded em
  [Expenses.tsx:77-82](src/pages/Expenses/Expenses.tsx#L77-L82)).
- `API NÃO IMPLEMENTADA`: Dashboard (`/dashboard`), MyWallet (`/minha-carteira`), Budget
  (`/orcamentos`), Categories (`/categorias`), MyProfile (`/minha-conta`), BillingDetails
  (`/detalhes-cobranca`), PasswordReset (`/password-reset`).
- `SEM NECESSIDADE DE API`: ChooseTransaction (`/escolher-transacao` — só roteia), Settings
  (`/configuracoes` — menu estático de `settings.json`), Theme (`/tema` — vazio), Terms
  (componente vazio, **não roteado**).

Fontes de dados mock a citar: `mock_dashboard.json`, `mock_my_wallet.json`, `mock_my_cards.json`,
`cards.json`, `flags_card.json`, `spent_categories.json`, `income_categories.json`,
`expense_type.json`, `income_type.json`, `payment_type.json`, `nav.json`, `settings.json`,
`src/mocks/transactions_mock.ts`.

## Estrutura do documento a produzir

Seguir exatamente as 16 seções exigidas no pedido. Diretrizes por seção:

1. **Objetivo** — escopo (só planejamento), decisões travadas (HTTP API v2, Lambda proxy, dev).
2. **Arquitetura atual encontrada** — base URL única, `fetch` + service layer, axios morto,
   token em `localStorage`, ausência de `.env`, build CRA.
3. **Inventário de telas** — tabela com as 17 rotas + classificação acima; por tela: rota,
   arquivo, funcionalidade, APIs chamadas, dados carregados, dados enviados, operações.
4. **APIs existentes** — a tabela consolidada de 14 colunas exigida (Tela, Serviço, Método, Path,
   Path/Query params, Headers, Auth, Request, Response, Status Codes, Origem `arquivo:linha`,
   Status, Observações). Status Codes tratados hoje = apenas `ok`/`!ok` → marcar os específicos
   como `UNKNOWN` com justificativa.
5. **APIs propostas** — marcadas `PROPOSTA`, com path/method/headers/params/body/response/status
   e **justificativa ligada ao elemento de UI**. Os contratos completos estão no **Apêndice A**
   deste plano e devem ser transcritos para o documento sem alteração.
6. **Inventário de endpoints** — tabela de propostas (10 colunas, incluindo Confiança).
7. **Detalhamento de Requests** — JSON de cada request, existente (dos types) e proposto.
8. **Detalhamento de Responses** — idem, preservando o envelope `{ message, response }` observado.
9. **Autenticação e Headers** — o que existe, a inconsistência do `Bearer` ausente, e a
   recomendação (padronizar `Bearer`, mover `id_user` do path/query para o claim do token).
10. **Organização das Rotas** — árvore por domínio marcando `EXISTENTE` / `PROPOSTA`.
11. **Proposta de Arquitetura do API Gateway** — por rota: route key `METHOD /path`, integração
    `AWS_PROXY` (payload format 2.0), Lambda responsável, authorizer (Lambda authorizer simples
    vs JWT/Cognito — deixar como pendência), CORS (`allow_origins`, `allow_headers` incl.
    `Authorization`), throttling, access logs para CloudWatch. Registrar que HTTP API **não tem**
    mapping templates — transformação de payload fica na Lambda.
12. **Proposta de Estrutura Terraform** — `infra/` com módulo `modules/http_api` reutilizável,
    `modules/lambda_function`, e `environments/dev/`. Rotas declaradas como um `map` de objetos
    consumido por `for_each` (evita duplicação); recursos: `aws_apigatewayv2_api`, `_stage`,
    `_route`, `_integration`, `_authorizer`, `aws_lambda_permission`,
    `aws_cloudwatch_log_group`, `aws_iam_role`/`_policy`. Listar variáveis e outputs
    (`api_endpoint`, `api_id`, `stage_name`) e o backend de state remoto como pendência.
13. **Problemas e Pontos de Atenção** — subdividido em `Confirmado pelo código` / `Inferência` /
    `Precisa ser validado`, cobrindo: URL hardcoded, axios morto com baseURL e chave de token
    erradas, `AuthProvider` não montado, `Bearer` ausente, `id_user` vindo do cliente
    (risco de IDOR), IDs hardcoded em Expenses/Incomes, navegação em caso de erro, loop fixo de
    5 páginas + `sleep(2000)` em Transactions, `useEffect` sem `idUser` nas deps,
    `/cards/{id}` sendo por usuário e não por cartão (path ambíguo), envelope de resposta
    inconsistente (`response` é array em cards, objeto em transactions), `Terms` não roteada,
    duplicação de `PostCardRequest` e `PostUserBankCardRequest` (tipos idênticos),
    `PostUserBankCardResponse` declarado mas não usado (`post_card` retorna `any`).
14. **Pendências para Implementação** — conta AWS/região (`us-east-2` evidenciado), origem do
    gateway atual (foi criado à mão? importar ou recriar?), tipo do authorizer, ARNs das Lambdas,
    domínio custom, origens de CORS, state remoto, throttling, logs/métricas, e validação com o
    backend de todas as propostas.
15. **Matriz Final de Endpoints** — tabela única com TODAS as rotas (existentes + propostas):
    Método, Path, Tela, Tipo, Status, Backend, Auth. É o inventário que a etapa Terraform vai ler.
16. **Próximos Passos** — ordem sugerida: validar contratos com backend → confirmar tipo/origem do
    gateway → definir authorizer → implementar módulo Terraform → migrar base URL do frontend para
    variável de ambiente.

## Regras de redação

- Documento em português, com blocos de código para paths, headers, JSON e status codes.
- Toda API não evidenciada por uma chamada HTTP real recebe o selo `PROPOSTA`.
- Toda informação indeterminável recebe `UNKNOWN` **com o motivo**.
- Toda afirmação sobre código existente cita `arquivo:linha` em link markdown relativo.
- Separar sempre fato / inferência / a validar.

## Verificação

Ao final, revisar o documento contra:
1. `grep -rn "fetch(" src/services` — as 6 chamadas estão todas na seção 4 e na matriz final.
2. As 17 `<Route>` de [Router.tsx](src/router/Router.tsx) + `Terms` estão todas na seção 3.
3. Toda tela classificada como `API NÃO IMPLEMENTADA` ou `PARCIALMENTE` tem ao menos uma linha
   correspondente na seção 5/6.
4. A matriz da seção 15 é superconjunto das seções 4 e 6 (nenhuma rota órfã).
5. Nenhum arquivo além de `API_GATEWAY_PLAN.md` foi criado ou modificado (`git status`).
