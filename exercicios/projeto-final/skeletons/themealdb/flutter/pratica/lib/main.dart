import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'api/themealdb_api.dart';
import 'screens/favorites_screen.dart';
import 'screens/list_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'state/favorites_controller.dart';
import 'state/meal_list_controller.dart';
import 'state/shopping_list_controller.dart';
import 'state/translation_controller.dart';
import 'storage/favorites_store.dart';
import 'storage/meals_cache.dart';
import 'storage/shopping_list_store.dart';
import 'translation/mlkit_recipe_translator.dart';
import 'translation/recipe_translator.dart';
import 'ui/theme.dart';

void main() {
  runApp(
    TheMealDbFinalApp(
      api: TheMealDbApi(),
      favoritesStore: FavoritesStore(),
      mealsCache: MealsCache(),
      shoppingListStore: ShoppingListStore(),
      translator: MlKitRecipeTranslator(),
    ),
  );
}

/// Raiz: monta as dependências (dados → estado) e entrega para a UI.
/// Os testes passam uma API falsa por aqui.
class TheMealDbFinalApp extends StatelessWidget {
  final TheMealDbApi api;
  final FavoritesStore favoritesStore;
  final MealsCache? mealsCache;
  final ShoppingListStore? shoppingListStore;

  /// Tradutor do conteúdo da API. Sem ele (testes), o app mostra o original.
  final RecipeTranslator? translator;

  const TheMealDbFinalApp({
    super.key,
    required this.api,
    required this.favoritesStore,
    this.mealsCache,
    this.shoppingListStore,
    this.translator,
  });

  @override
  Widget build(BuildContext context) {
    final cache = mealsCache ?? MealsCache();
    return MultiProvider(
      providers: [
        Provider<TheMealDbApi>.value(value: api),
        Provider<MealsCache>.value(value: cache),
        ChangeNotifierProvider(
          create: (_) =>
              TranslationController(translator ?? const NoRecipeTranslation())
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesController(favoritesStore)..load(),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final translation = context.read<TranslationController>();
            return MealListController(
              api,
              cache: cache,
              // Busca em português: a API recebe o texto em inglês, e a busca
              // local também compara com o nome traduzido.
              queryToApiLanguage: translation.toEnglish,
              displayName: translation.peek,
            )..load();
          },
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ShoppingListController(shoppingListStore ?? ShoppingListStore())
                ..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Receitas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        // Textos do próprio Flutter (voltar, colar, datas…) em português.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final favoritesCount = context.select<FavoritesController, int>(
      (c) => c.items.length,
    );

    return Scaffold(
      // IndexedStack mantém busca/categoria/rolagem ao trocar de aba.
      body: IndexedStack(
        index: _selectedIndex,
        children: const [ListScreen(), FavoritesScreen(), ShoppingListScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ),
          NavigationDestination(
            icon: Semantics(
              identifier: 'tab-favorites',
              child: Badge(
                isLabelVisible: favoritesCount > 0,
                label: Text('$favoritesCount'),
                child: const Icon(Icons.favorite_border),
              ),
            ),
            selectedIcon: Badge(
              isLabelVisible: favoritesCount > 0,
              label: Text('$favoritesCount'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favoritos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket),
            label: 'Compras',
          ),
        ],
      ),
    );
  }
}
