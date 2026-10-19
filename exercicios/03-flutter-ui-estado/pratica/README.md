# Filmes (Flutter) — pratica/ da Atividade 3

App de catálogo de filmes em **Flutter**. Já roda; você completa os scaffolds (UI, estado, Firebase e offline-first) até `flutter test` ficar **verde**.

## Rodar
```bash
cd exercicios/03-flutter-ui-estado/pratica   # confirme: ls lib
flutter pub get
flutter run -d chrome --web-port 5300   # PORTA FIXA (o cache offline fica no navegador, por porta)
# 💡 Atalho no VS Code: aperte F5 (o .vscode/launch.json já fixa a porta 5300)
#    ou Ctrl/Cmd+Shift+B (terminal integrado: r = hot reload) · ./rodar.sh (Mac/Linux) · rodar.bat (Windows)
```

## Testar (é o seu checklist)
```bash
flutter test                         # tudo: Ex1–Ex3 (UI/estado) + offline (TASKs 11–15) + checklist
flutter test test/offline_test.dart  # só offline-first — cada grupo = 1 TASK
flutter analyze                      # precisa ficar limpo
```
Comece com os testes **vermelhos**; deixe-os **verdes**. `test/checklist_test.dart` e `test/offline_test.dart` são a **spec** (não edite).

## O que completar (🧑‍🏫 aula · 🧑‍💻 casa)
| TASK | Arquivo | O quê | |
|---|---|---|---|
| 1 | `lib/widgets/movie_card.dart` | compor o card (título + ⭐ nota + ano) | 🧑‍🏫 |
| 2 | `lib/state/favorites.dart` | `favoritesProvider` (`toggle` + `clear`) | 🧑‍🏫 |
| 3 | `lib/main.dart` | projeto Firebase + `flutterfire configure` | 🧑‍🏫 |
| 10 | `lib/main.dart` | persistência offline do Firestore (1 linha) | 🧑‍🏫 fácil |
| 4 | `lib/widgets/movie_card.dart` | coração favoritando (`ConsumerWidget` + `ref`) | 🧑‍💻 |
| 5 | `lib/screens/home_screen.dart` | contador `♥ N` no header | 🧑‍💻 |
| 6 | `lib/screens/home_screen.dart` | botão **limpar** favoritos | 🧑‍💻 |
| 7 | `lib/state/favorites.dart` | persistir favoritos no **Firestore** | 🧑‍💻 médio |
| 8 | `lib/services/remote_config.dart` + home | ⏸ **ADIADA** (Remote Config) — não faz parte desta atividade, pule | — |
| 9 | `test/favorites_test.dart` | **você escreve** um teste do provider | 🧑‍💻 |
| 11 | `lib/widgets/offline_banner.dart` | aviso "você está offline" | 🧑‍💻 fácil |
| 12 | `lib/models/movie.dart` | `toJson` / `fromJson` | 🧑‍💻 fácil |
| 13 | `lib/data/movie_repository.dart` | repositório **cache-first** | 🧑‍💻 médio |
| 14 | `lib/data/movie_repository.dart` | validade do cache (**TTL**) | 🧑‍💻 médio |
| 15 | `lib/data/sync_queue.dart` | **fila de sincronização** (conflitos + flush) | 🧑‍💻 🔴 difícil |

✈️ O botão de **avião** na barra do topo simula o modo offline. Veja o `guia-passo-a-passo.md` e o `enunciado.md` (rubrica).

## Entrega
Fork + PR no repo público; link no Canvas. O **J.A.R.V.I.S.** lê o seu código (estrutural) e posta uma nota **mínima**; a final sai no Canvas.
- ✏️ **Edite os arquivos dentro de `exercicios/03-flutter-ui-estado/pratica/` (no lugar)** — **não crie subpasta** `aluno-.../`.

> **CI no seu fork (opcional):** habilite o *Actions* do fork — o workflow *Flutter test — Atividade 3* roda `flutter analyze` + `flutter test` a cada push.
> **Versões:** precisa de Flutter **3.27+** (o `pubspec` já avisa se for mais antigo).

> **Não comite** `.dart_tool/`, `build/`, `pubspec.lock` (já no `.gitignore`).

## Dados reais do TMDB (opcional)

Sem chave, o app usa a lista simulada (5 filmes). Para filmes reais: copie `.env.local.example` → `.env.local`,
cole sua chave do TMDB (`TMDB_KEY=...`) e rode `./rodar.sh` / `rodar.bat` (ou F5 → "dados reais TMDB").
O `.env.local` não vai pro git. Os testes (`flutter test`) nunca usam a chave.

---

## Entrega — João Pedro Schlindwein

**Status:** `flutter analyze` limpo · `flutter test` 28/28 verdes (inclui TASKs 1–7, 9–15; TASK 8/Remote
Config adiada conforme enunciado) · projeto Firebase pessoal (`atividade3-filmes-flutter`, plano Spark)
com Firestore (modo teste) configurado e funcionando.

### Local vs. cloud vs. offline-first (trade-offs)

O app combina três camadas de estado, cada uma resolvendo um problema diferente. **Local** (o
`favoritesProvider` em memória, Ex2) é instantâneo e não depende de rede, mas morre a cada reload e
não sincroniza entre dispositivos. **Cloud** (Firestore, Ex4) resolve isso — o mesmo documento
`favorites/meus-favoritos` é lido por qualquer cliente, então o favorito sobrevive ao F5 e sincroniza
entre abas — ao custo de depender de rede/latência; por isso a escrita é **otimista** (o `state` local
muda na hora, e a gravação remota acontece em paralelo, silenciosamente, com fallback se falhar).
**Offline-first** (Ex6: `MovieRepository` cache-first + TTL + `SyncQueue`) é a camada que faz as duas
coexistirem na prática: a tela sempre mostra o que já está salvo no aparelho primeiro (nunca espera a
rede para renderizar), revalida em segundo plano quando a rede permite, e só busca de novo se o cache
expirou (TTL) — evitando chamadas desnecessárias. Operações feitas offline (favoritar/desfavoritar)
entram numa fila que resolve conflitos (ex: favoritar e desfavoritar o mesmo filme offline se cancelam
mutuamente, sem gerar tráfego à toa) e só é esvaziada quando a rede volta, na ordem, persistindo a cada
sucesso — se o app fechar no meio do envio, nada é perdido nem reenviado.

### Evidências

**Favoritos sobrevivendo a um F5 completo** (prova do Firestore — Ex4):

![Matrix e Inception favoritados, contador ♥ 2, após refresh completo da página](./screenshot-favoritos-persistidos.jpg)

**Modo offline** (banner + lista servida do cache — Ex6 / TASK 11+13):

![Banner laranja "Você está offline — mostrando dados salvos" com a lista de filmes e favoritos intactos](./screenshot-offline.jpg)
