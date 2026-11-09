# Projeto Final — TheMealDB (receitas) em Flutter

Skeleton **opcional** de ponto de partida do **Projeto Final** (30 pts). A estrutura de telas e a lógica das
5 features básicas vêm marcadas com `// TODO 1` a `// TODO 5`. **O visual é básico de propósito**: persistência,
estados de loading/vazio/erro e todo o checklist de UI/UX (tema escuro, design tokens, responsividade,
acessibilidade, ícone/splash) são **trabalho do grupo** — veja o [`enunciado.md`](../../../../enunciado.md).

**API deste tema:** TheMealDB — receitas; filtro por categoria (`filter.php?c=`); id `String`.
O app também oferece busca por letra (`search.php?f=`) e mantém listas da API em cache
local para consulta offline. Ao ficar sem conexão, mostra os resultados salvos da lista,
categoria ou letra atual e permite tentar novamente ou puxar a tela para atualizar.
Endpoints exatos, fixtures dos testes e gotchas: [`temas/03-themealdb/README.md`](../../../../temas/03-themealdb/README.md).
Regras completas e rubrica: [`enunciado.md`](../../../../enunciado.md).

> ⚠️ Antes de codar: seu grupo **reservou** a combinação `themealdb + flutter` abrindo issue no
> repo da disciplina? Cada combinação tema+framework é de um grupo só.

## Como rodar

```bash
# a partir da raiz do SEU clone (do fork do grupo):
cd exercicios/projeto-final/skeletons/themealdb/flutter/pratica
ls flows   # confere que está no lugar certo: 01-list.yaml … 05-favorites.yaml

flutter pub get
flutter run          # com emulador Android aberto (ou dispositivo conectado)
```

## Onde estão os TODOs

| Feature | TODO | Arquivo |
|---|---|---|
| 1 — Lista consumindo a API | `TODO 1` | `lib/screens/list_screen.dart` |
| 2 — Navegação lista → detalhe | `TODO 2` | `lib/screens/detail_screen.dart` |
| 3 — Busca por texto | `TODO 3` | `lib/screens/list_screen.dart` |
| 4 — Categoria/filtro (parâmetro real da API) | `TODO 4` | `lib/screens/list_screen.dart` |
| 5 — Favoritos persistidos | `TODO 5` | `lib/screens/detail_screen.dart` + `lib/screens/favorites_screen.dart` |

## Estados tratados

Carregando, lista vazia, falha de rede sem cache, resultados em cache offline e atualização
manual por botão ou gesto de puxar. O catálogo pode ser explorado de A a Z; a busca por texto
filtra os resultados da letra ou categoria selecionada, e esses filtros são exclusivos.

Os testes das features adicionais ficam em `test/list_screen_features_test.dart`.

## Registro da contribuição — para atualizar a apresentação

Esta contribuição implementa as duas melhorias que aparecem como próximos passos no slide 16:

| Mudança | O que foi feito | Arquivos principais |
|---|---|---|
| Receitas offline | Persiste a lista inicial e os resultados de categoria/letra em `shared_preferences`. Se a API falhar por falta de conexão, a tela tenta carregar a cópia local, exibe o aviso “Sem internet — mostrando receitas salvas” e permite tentar novamente. Sem cópia, mostra erro com opção de nova tentativa. | `lib/storage/meals_cache.dart`, `lib/screens/list_screen.dart`, `lib/main.dart` |
| Explorar A–Z | Adiciona busca por letra via `search.php?f=<letra>`. A resposta `meals: null` é tratada como lista vazia. A busca por texto filtra os resultados carregados; selecionar letra ou categoria limpa o outro filtro. | `lib/api/themealdb_api.dart`, `lib/screens/list_screen.dart` |
| Testes | Cobre chamada por letra, resposta vazia, gravação do cache online, fallback offline da lista e da categoria, ausência de cache e combinação letra/busca/categoria. | `test/list_screen_features_test.dart` |

### Sugestões para os slides

- **Slide 3 (funcionalidades):** acrescentar “Acesso offline às últimas receitas carregadas” e “Exploração do catálogo por letra (A–Z)”.
- **Slide 4 (demo):** demonstrar escolher uma letra, filtrar pelo nome e alternar para uma categoria; depois abrir a lista com rede desligada para mostrar o aviso e o cache. O fallback offline só pode ser demonstrado depois de carregar receitas com conexão.
- **Slide 7 (arquitetura):** incluir `MealsCache` na camada de armazenamento. Atenção: esta cópia do skeleton não contém os controllers mostrados no slide; nestas alterações, a lógica de tela e as chamadas são coordenadas por `ListScreen`. Alinhar o desenho à versão que será apresentada ou refatorar para os controllers antes de afirmar essa separação.
- **Slide 14 (qualidade):** nesta cópia local, `flutter test --no-pub` passou com 8 testes no total, incluindo os novos casos. Recontar após integrar à versão do grupo, pois ela pode ter outros testes.
- **Slide 16 (limitações/próximos passos):** retirar “guardar a última lista para abrir offline” e “navegar o catálogo por letra” dos próximos passos. O cache cobre a lista inicial, categorias e letras consultadas; receitas ainda não carregadas não ficam disponíveis offline.

Validação do ambiente local: os testes passaram. O APK e a execução em emulador não foram verificados nesta máquina porque não há Android SDK instalado.

## Como se autoverificar (opcional)

Os flows Maestro em `flows/` **não são mais avaliados pelo CI** — servem para vocês conferirem
a mão que as 5 features funcionam. Para rodar localmente
([instalar Maestro](https://docs.maestro.dev/getting-started/installing-maestro)):

```bash
# com o app instalado e aberto no emulador:
maestro test flows/
```

Se mudarem a UI e um flow quebrar, tudo bem: ajustem o flow (ou ignorem) — o que vale é o app
funcionar bem e o checklist do enunciado.


## Antes de abrir/atualizar o PR

O build precisa passar — **critério eliminatório** (app que não builda não pode ser demonstrado e zera a Funcionalidade):

```bash
flutter build apk --debug
```

Entrega em grupo: **um repositório do grupo** (todos como *collaborators*), branches + PRs internos; a **URL do repo** vai no Canvas.
Adicionem `README.md` (com ≥ 3 screenshots) e `ADR.md` nesta pasta. Sem autograder: o professor clona, builda e avalia. Detalhes no
[`enunciado.md`](../../../../enunciado.md).
