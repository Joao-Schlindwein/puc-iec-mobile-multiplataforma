import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/themealdb_api.dart';
import 'screens/favorites_screen.dart';
import 'screens/list_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'state/favorites_controller.dart';
import 'state/meal_list_controller.dart';
import 'state/shopping_list_controller.dart';
import 'storage/favorites_store.dart';
import 'storage/shopping_list_store.dart';
import 'ui/theme.dart';

void main() {
  runApp(
    TheMealDbFinalApp(
      api: TheMealDbApi(),
      favoritesStore: FavoritesStore(),
      shoppingListStore: ShoppingListStore(),
    ),
  );
}

/// Raiz: monta as dependências (dados → estado) e entrega para a UI.
/// Os testes passam uma API falsa por aqui.
class TheMealDbFinalApp extends StatelessWidget {
  final TheMealDbApi api;
  final FavoritesStore favoritesStore;
  final ShoppingListStore? shoppingListStore;

  const TheMealDbFinalApp({
    super.key,
    required this.api,
    required this.favoritesStore,
    this.shoppingListStore,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TheMealDbApi>.value(value: api),
        ChangeNotifierProvider(
          create: (_) => FavoritesController(favoritesStore)..load(),
        ),
        ChangeNotifierProvider(create: (_) => MealListController(api)..load()),
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
