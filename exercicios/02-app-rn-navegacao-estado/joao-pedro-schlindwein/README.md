# README — Atividade 2 — João Pedro Schlindwein

## Identificação

- **Aluno:** João Pedro Schlindwein
- **Opção Reanimated escolhida:** A — Heart pop (escala spring 1 → 1.4 → 1.0 + rotação leve)
- **Bonus implementado:**
  - Bottom Tabs com aba Favoritos (+2pt)
  - Segunda opção Reanimated: C — shared element simplificado, poster entra com spring de escala/opacidade (+1pt)
  - Paginação infinita com `useInfiniteQuery` + `onEndReached`
- **Repo (seu fork):** https://github.com/Joao-Schlindwein/puc-iec-mobile-multiplataforma

## Como rodar

```bash
npm install
cp .env.example .env  # editar com TMDB API Read Access Token (eyJhbGc...)
npx expo start
```

> ⚠️ MMKV não roda em web. Use simulador iOS (`i`) ou Android (`a`) pra validar a persistência de verdade. Em modo web, `src/storage/mmkv.ts` cai no polyfill `localStorage`.

## O que o app faz

Lista os filmes populares da TMDB (`usePopularMoviesInfinite`, com scroll infinito via `onEndReached`), permitindo favoritar cada filme pelo botão ❤️ (`useFavoritesStore`, Zustand). Favoritos são persistidos de forma síncrona com MMKV e sobrevivem a reloads do app. Uma aba separada "Favoritos" lista os filmes favoritados. O toque no ❤️ dispara uma animação Reanimated (escala + rotação, worklet puro na UI thread), e a tela de detalhe anima a entrada do poster com spring.

## Arquitetura

```
src/
├── routes/
│   └── RootStack.tsx          ← Bottom Tabs (Filmes/Favoritos), cada um com stack próprio
├── screens/
│   ├── MovieList.tsx          ← FlatList + paginação infinita
│   ├── MovieDetail.tsx
│   └── FavoritesList.tsx      ← aba de favoritos (bônus)
├── components/
│   ├── MovieCard.tsx
│   ├── HeartButton.tsx        ← animação Reanimated opção A
│   └── AnimatedPoster.tsx     ← animação Reanimated opção C (bônus)
├── store/
│   ├── counterStore.ts
│   └── favoritesStore.ts      ← Zustand + persist manual via subscribe + MMKV
├── queries/movies/
│   ├── get-popular-movies.ts  ← useQuery + useInfiniteQuery (bônus)
│   ├── get-movie-by-id.ts
│   └── search-movies.ts
├── services/
│   └── api.ts
└── storage/
    └── mmkv.ts                ← MMKV nativo + polyfill localStorage em web
```

## Decisões técnicas

Escolhi a opção A (heart pop) como animação principal por ser a mais direta de verificar visualmente e por cobrir bem o requisito de worklet puro (`useSharedValue` + `useAnimatedStyle` + `withSequence`/`withSpring`, sem `Animated` legado). Para o bônus de uma segunda animação, optei pela opção C em vez da B (card swipe): a B exigiria instalar e configurar `react-native-gesture-handler` (API `useAnimatedGestureHandler` está depreciada em favor de `Gesture.Pan()`), o que adicionaria uma dependência nova e risco de setup sem ganho proporcional, enquanto a C usa só Reanimated (já instalado) para produzir o efeito "cresce ao entrar" na tela de detalhe.

Persistência via `subscribe` manual (não `persist` middleware do Zustand) porque o middleware de devtools usa `import.meta.env` (estilo Vite), que quebra no bundler Metro em web — abordagem adotada diretamente do comentário já presente no starter.

Paginação infinita trocou `usePopularMovies` por uma nova função `usePopularMoviesInfinite` (em vez de modificar a assinatura existente), preservando compatibilidade com qualquer uso anterior da query simples.

## Referência

- React Native Reanimated — Worklets e `useAnimatedStyle`: https://docs.swmansion.com/react-native-reanimated/
- React Native MMKV: https://github.com/mrousavy/react-native-mmkv
- TanStack Query — Infinite Queries: https://tanstack.com/query/latest/docs/framework/react/guides/infinite-queries
