# ENTREGA — Atividade 4 (PWA)

> Preencha e faça commit junto com o código. Esta parte vale 3 pts (avaliação manual no Canvas).

**Nome:** João Pedro Schlindwein · **GitHub:** Joao-Schlindwein

---

## 1. Site comum × PWA — o que EU vi (3 diferenças)

Comparei `https://pwa-tmdb-aula4.vercel.app` com `https://www.themoviedb.org/movie` no Chrome (viewport de celular): visitei cada um online, recarreguei, depois cortei a rede e recarreguei de novo.

| # | Site comum (themoviedb.org) | PWA (pwa-tmdb-aula4) | Print/evidência |
|---|---|---|---|
| 1 | **Sem rede, não abre:** o reload mostra a página do dinossauro do Chrome (`ERR_INTERNET_DISCONNECTED`). | **Sem rede, abre normalmente:** o reload mostra a lista de filmes com pôsteres, servida pelo Service Worker. | [`10-site-offline.png`](evidencias/10-site-offline.png) × [`10-pwa-offline.png`](evidencias/10-pwa-offline.png) |
| 2 | **Nenhum Service Worker registrado** (`navigator.serviceWorker.getRegistration()` → vazio), nada no Cache Storage. Curiosidade: o TMDB até tem `manifest.json` com `display: standalone`, mas sem SW ele não funciona offline. | **Service Worker registrado** com precache do app (HTML/JS/CSS/ícones) + caches de runtime `tmdb-api` e `tmdb-images`. | [`08-cache-storage.png`](evidencias/08-cache-storage.png) |
| 3 | **Atualização implícita:** cada reload busca a versão mais nova do servidor; o usuário não tem escolha. | **Atualização controlada (no meu build, `registerType: 'prompt'`):** a versão nova fica esperando e o app avisa "Nova versão disponível"; só troca quando eu clico em Atualizar. | [`06-nova-versao.png`](evidencias/06-nova-versao.png) → [`07-depois-de-atualizar.png`](evidencias/07-depois-de-atualizar.png) |

Prints online para referência: [`09-site-online.png`](evidencias/09-site-online.png), [`09-pwa-online.png`](evidencias/09-pwa-online.png).

## 2. Prova do offline no SEU build

Build local: `npm run build && npm run preview` (http://localhost:4173), visitado duas vezes para o SW passar a controlar a página.

- [x] **Cache Storage** com `tmdb-api` (1 item: `/movie/popular`) e `tmdb-images` (11 pôsteres de `image.tmdb.org`), além do precache do Workbox → [`08-cache-storage.png`](evidencias/08-cache-storage.png)
  - Obs.: a tabela foi gerada lendo `window.caches` na origem do app (mesmo conteúdo de DevTools → Application → Cache Storage).
- [x] **App em modo avião carregando a lista** (rede do navegador desligada, inclusive para o SW) → [`04-offline-lista.png`](evidencias/04-offline-lista.png) e aba Favoritos com o banner **"📡 Offline — exibindo dados do cache"** → [`05-offline-favoritos-banner.png`](evidencias/05-offline-favoritos-banner.png)
  - Obs.: o botão "🌐 Online" no topo é o simulador de rede do próprio app (dev tool), não o estado real da conexão; quem reflete a conexão real é o banner laranja (`navigator.onLine`).
- [x] **Aviso "Nova versão disponível"** → [`06-nova-versao.png`](evidencias/06-nova-versao.png). Como reproduzi: com o preview aberto, mudei o título temporariamente para "Filmes Populares (v2)", rodei `npm run build`, forcei `registration.update()`; apareceu o aviso, cliquei **Atualizar** e a página recarregou com o título novo → [`07-depois-de-atualizar.png`](evidencias/07-depois-de-atualizar.png). Depois desfiz a mudança.

Outros prints: aviso "App pronto para uso offline" na 1ª visita → [`01-offline-ready.png`](evidencias/01-offline-ready.png); lista online → [`02-lista-online.png`](evidencias/02-lista-online.png); aba Favoritos com 2 filmes → [`03-aba-favoritos.png`](evidencias/03-aba-favoritos.png).

## 3. Reflexão (5–8 linhas)

Para um app de **checkout** eu escolheria **`prompt`**. Com `autoUpdate` o novo Service Worker assume e a página pode recarregar no meio do pagamento, perdendo carrinho, formulário ou o passo do fluxo, ou misturando JS antigo com uma API já nova. Com `prompt` o usuário termina a compra e atualiza quando quiser. O risco é ele ficar dias na versão antiga ("Depois" para sempre); por isso o backend precisa aceitar versões antigas por um tempo, e uma correção crítica pode exigir forçar a atualização.
Para um app de **notícias** eu escolheria **`autoUpdate`**: não há transação em andamento, e o que importa é o usuário ver layout e correções novas sem precisar clicar em nada. O risco é um reload inesperado no meio da leitura e, se sair uma versão com bug, ela chega a todos na hora, sem o usuário poder adiar.

## 4. Declaração de uso de IA

Sim. Usei o Claude Code (Anthropic) como assistente para implementar os TODOs 1–5 (`tmdb.ts`, `vite.config.ts`, `UpdatePrompt.tsx`, `HomeScreen.tsx`, `useOfflineStatus.ts`), rodar testes, build e o validador, e capturar os prints de `evidencias/` com um script Playwright no Chrome (incluindo a simulação de offline e o fluxo de "Nova versão"). Revisei o código e os resultados; o rascunho desta ENTREGA também foi feito com a IA e revisado por mim.
