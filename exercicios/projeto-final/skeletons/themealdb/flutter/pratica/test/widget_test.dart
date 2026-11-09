import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/main.dart';
import 'package:themeal_final/storage/favorites_store.dart';

import 'fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lista carrega, busca filtra e favoritar aparece na aba',
      (tester) async {
    await tester.pumpWidget(TheMealDbFinalApp(
      api: fakeApi(catalog: [mealJson('2', 'Sushi'), mealJson('3', 'Sushi Bowl')]),
      favoritesStore: FavoritesStore(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Burek'), findsOneWidget);
    expect(find.text('Sushi'), findsOneWidget);
    expect(find.text('Sobremesa'), findsOneWidget, reason: 'chip traduzido');

    await tester.enterText(find.byType(TextField), 'sus');
    await tester.pump();
    // Filtro local imediato, antes da API responder.
    expect(find.text('Burek'), findsNothing);
    expect(find.text('Sushi'), findsOneWidget);

    // Debounce de 400 ms + resposta da API: aparece o resultado do catálogo.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Sushi Bowl'), findsOneWidget);

    await tester.tap(find.byTooltip('Favoritar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos').last);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum favorito ainda'), findsNothing);
    expect(find.widgetWithText(Card, 'Sushi'), findsOneWidget);
  });

  testWidgets('sem internet mostra mensagem e botão de tentar de novo',
      (tester) async {
    await tester.pumpWidget(TheMealDbFinalApp(
      api: fakeApi(failWith: 'offline'),
      favoritesStore: FavoritesStore(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Você está sem internet'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
