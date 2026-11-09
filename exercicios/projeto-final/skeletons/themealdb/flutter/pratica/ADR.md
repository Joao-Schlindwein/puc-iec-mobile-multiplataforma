# ADR-001 — Flutter + Provider/ChangeNotifier para o app de receitas (TheMealDB)

- **Status:** aceito
- **Data:** 2026-11-08
- **Grupo:** Henrique Miguel de Jesus, João Pedro Schlindwein, Rafael Correa Zart
- **Reserva:** [issue #269](https://github.com/jacksonsmith/puc-iec-mobile-multiplataforma/issues/269)

## Contexto

Precisamos entregar, em pouco tempo e com 3 pessoas, um app Android com 5 features (lista de dados
reais, detalhe, busca, filtro por categoria e favoritos que sobrevivem a fechar o app), estados de
carregando/vazio/erro, visual consistente e testes da lógica própria. O tema é a TheMealDB: API
pública, sem chave real, com fotos de pratos, 14 categorias e um endpoint de filtro (`filter.php?c=`).

## Decisão 1 — Framework: Flutter

Escolhemos **Flutter** porque:

- é o framework que a máquina de build do grupo já tinha validado (Atividade 3), e o skeleton do tema
  já vem em Flutter, com os `Semantics(identifier: …)` dos flows Maestro;
- os widgets Material 3 (`NavigationBar`, `ChoiceChip`, `SliverAppBar`) cobrem o visual que
  queríamos (grade de fotos, detalhe com imagem grande) sem biblioteca de UI extra;
- tema claro/escuro vem de um único `ColorScheme.fromSeed`, então cor, raio e espaçamento ficam em
  um arquivo só (`lib/ui/theme.dart`).

**Descartados:** React Native (TheMealDB + React Native já estava reservado por outro grupo, issue
#232) e KMP Compose (também viável, mas o grupo tem mais prática com Dart/Flutter, e o build de KMP
no Windows é mais lento e pesado em memória).

## Decisão 2 — Estado: `ChangeNotifier` + `provider`

Cada tela observa um controller com `ChangeNotifier`, entregue pela árvore com o pacote `provider`:

| Controller | Responsabilidade |
|---|---|
| `MealListController` | lista inicial, categorias, categoria escolhida (busca na API), texto da busca |
| `MealDetailController` | detalhe de uma receita (um por tela de detalhe) |
| `FavoritesController` | favoritos compartilhados por grade, detalhe e aba Favoritos |
| `ShoppingListController` | ingredientes e checkboxes compartilhados entre detalhe e aba Compras |

O `FavoritesController` é o caso que justifica um gerenciador de estado: o coração na grade, o
botão no detalhe e a aba Favoritos precisam mostrar o mesmo valor ao mesmo tempo. Com `setState`
dentro de cada tela (como o skeleton vinha), a aba Favoritos ficava desatualizada até recarregar.

**Descartados:**

- **`setState` nas telas** (ponto de partida do skeleton): mistura fetch com widget e não
  compartilha favoritos entre telas.
- **Riverpod:** resolve o mesmo problema com mais garantias (sem depender de `BuildContext`), mas
  traz conceitos novos (providers globais, `ref`, code generation opcional) que o grupo não usou em
  aula; para 3 controllers o ganho não paga a curva.
- **Bloc/Cubit:** separação ótima por eventos, mas exige mais código por tela (estados, eventos);
  o app é pequeno e o prazo é curto.

## Camadas

```
lib/
  api/        dados remotos: TheMealDbApi (HTTP + JSON → modelos, ApiException com mensagem)
  storage/    dados locais: FavoritesStore (shared_preferences)
  models/     MealSummary, MealDetail, Ingredient (parsing dos campos strIngredient1..20)
  state/      controllers (ChangeNotifier) — sem import de widgets
  ui/         tema/tokens e widgets reutilizáveis (MealCard, MealImage, StateMessage, Skeleton)
  screens/    telas: só leem estado e chamam ações do controller, nenhum fetch dentro do widget
```

A dependência vai sempre para baixo: `screens → state → api/storage → models`. O `http.Client` é
injetado em `TheMealDbApi`, então os testes usam `MockClient` sem internet.

## Outras decisões menores

- **Favoritos guardam o resumo (id, nome, foto), não só o id.** Assim a aba abre sem internet, e
  receitas favoritadas a partir de uma categoria (que não estão na lista inicial de 25) continuam
  aparecendo. Custo: se a API mudar o nome de uma receita, o favorito mostra o nome antigo até ser
  aberto e salvo de novo.
- **Filtro por categoria usa a própria API** (`filter.php?c=`) e devolve a categoria inteira, não só
  as receitas da lista inicial. A busca é feita no aparelho sobre o que está na tela.
- **Erros viram `ApiException` com texto para o usuário** e a flag `offline`, para a tela diferenciar
  "sem internet" de "o servidor falhou", sempre com botão "Tentar de novo".

## Consequências

A lista de compras segue a mesma separação: `ShoppingItem` é imutável,
`ShoppingListStore` salva JSON em chave própria do `shared_preferences`, e
`ShoppingListController` atualiza os listeners antes de persistir. As gravações são
serializadas para preservar a última mudança mesmo com toques rápidos. Os grupos
usam o id da receita, evitando misturar receitas com nomes iguais. Cada entrada
corrompida é ignorada individualmente ao recuperar a lista.

Compartilhamento e vídeo são ações de plataforma no detalhe, sem HTTP nos widgets.
`MealDetail` lê `strYoutube`/`strSource`, enquanto `shareText` monta o texto em
uma função pura. A fonte tem preferência no compartilhamento, com o vídeo como
alternativa; sem ambos, compartilhamos somente nome e ingredientes. Usamos
`share_plus` 11.x para manter compatibilidade com o AGP existente, e
`url_launcher` para abrir HTTPS externamente. Falhas dos plugins são convertidas
em `SnackBar`; os testes simulam os canais nativos sem abrir aplicativos reais.

- Positivo: lógica testável sem Flutter rodando (controllers e modelos), telas finas, um só lugar
  para o tema.
- Negativo: `provider` depende de `BuildContext` (`context.read/watch`); um erro de árvore só
  aparece em tempo de execução. Mitigamos com um teste de widget que monta o app inteiro.
- Se o app crescer (login, cache offline da lista, paginação), reavaliar Riverpod ou Bloc.
