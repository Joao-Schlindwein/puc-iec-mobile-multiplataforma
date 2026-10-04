# Roteiro de Tasks — Hands-on Aula 2 + Atividade 2

10 tasks sequenciais. Cada task tem TODOs no código com a tag `[TASK N]`.

```bash
# Listar todas tasks pendentes:
grep -rn "TODO \[TASK" src/ __tests__/

# Quantas faltam por task:
grep -rn "TODO \[TASK" src/ __tests__/ | sed 's/.*TASK /TASK /' | cut -d']' -f1 | sort | uniq -c
```

---

## 🎓 Hands-on da aula (em sala, ~45min) — TASKs 1 a 4

### ✅ Setup (pronto, sem TODO)
- App Expo + TS + React Navigation v7 + QueryClientProvider configurados
- Service TMDB (`src/services/api.ts`) + 3 queries (`src/queries/movies/`)
- `npm install` + criar `.env` com TMDB token (ver README)

### 📝 TASK 1 — Zustand counter store
📁 `src/store/counterStore.ts`
- Declarar tipos `increment`, `decrement`, `reset` em `CounterState`
- Implementar actions com `create<CounterState>((set) => ({...}))`

### 📝 TASK 2 — TanStack Query `usePopularMovies`
📁 `src/queries/movies/get-popular-movies.ts`
- Substituir stub por `useQuery` real (queryKey, queryFn, staleTime 5min)

### 📝 TASK 3 — FlatList + MovieCard
📁 `src/screens/MovieList.tsx`
- Trocar placeholder por `<FlatList data={data?.results} renderItem={...} />`
- Descomentar import de `MovieCard`

### 📝 TASK 4 — Testes com IA (counter)
📁 `__tests__/counterStore.test.ts`
- Usar IA pra gerar testes `decrement`, `reset`, edge cases
- Mínimo 3 testes verdes pra counter

---

## 📦 Atividade 2 — assíncrona (ver Canvas, 15 pts, ~2h) — TASKs 5 a 9

### 📝 TASK 5 — Zustand favorites store
📁 `src/store/favoritesStore.ts`
- Declarar tipos `add`, `remove`, `clear`
- Implementar `toggle` (add se não existe, remove se existe)

### 📝 TASK 6 — Integrar favorites em MovieCard
📁 `src/components/MovieCard.tsx`
- Importar `useFavoritesStore`
- Ler `isFavorite(movie.id)` + chamar `toggle(movie.id)` no Pressable do ❤️

### 📝 TASK 7 — Persistência MMKV
📁 `src/storage/mmkv.ts` + atualizar `src/store/favoritesStore.ts`
- Criar instância MMKV + adapter `mmkvStorage`
- Envolver `create()` do favoritesStore com `persist({ name, storage })`

### 📝 TASK 8 — HeartButton Reanimated (escolha A/B/C)
📁 criar `src/components/HeartButton.tsx` + integrar em `MovieCard.tsx` e `MovieDetail.tsx`
- **A — Heart pop:** `withSequence(withTiming(1.4), withSpring(1))`
- **B — Card swipe:** `useAnimatedGestureHandler` com threshold
- **C — Shared element:** poster cresce com `withSpring` ao navegar

### 📝 TASK 9 — Testes com IA (favorites)
📁 `__tests__/favoritesStore.test.ts`
- 3+ testes verdes pra `toggle`, `isFavorite`, `clear`
- Total CI: **≥ 6 testes verdes** (3 counter TASK 4 + 3 favorites TASK 9)

### 🎁 TASK 10 (bônus, não vale ponto) — Paginação infinita
📁 `src/queries/movies/get-popular-movies.ts` + `src/screens/MovieList.tsx`
- TMDB já devolve `page`/`total_pages` na resposta — `usePopularMovies` já aceita `page` como argumento
- Troque por `useInfiniteQuery` (ou incremente `page` manualmente) + `onEndReached` no `FlatList` pra carregar mais filmes ao chegar no fim da lista
- Não obrigatório, não afeta a nota mínima — conta em arredondamento (ver "Bonus" no `enunciado.md`)

### 📦 Entrega
Push pro fork → abre PR → CI valida automático (sem README/screencast obrigatório — o autograder já lê o código).

---

## Verificação rápida

```bash
# App rodando:
npx expo start

# Testes verdes:
npm test

# Quantas tasks faltam:
grep -c "TODO \[TASK" src/**/*.ts src/**/*.tsx __tests__/*.ts

# Lista detalhada:
grep -rn "TODO \[TASK" src/ __tests__/
```

CI workflow (`.github/workflows/test.yml`) valida no push do fork:
- `numPassedTests >= 6` → CI verde
- Senão → CI vermelho, perde pontos
