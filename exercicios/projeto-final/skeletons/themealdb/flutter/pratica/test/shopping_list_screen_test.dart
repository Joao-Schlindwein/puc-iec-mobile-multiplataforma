import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/api/themealdb_api.dart';
import 'package:themeal_final/main.dart';
import 'package:themeal_final/storage/favorites_store.dart';
import 'package:themeal_final/storage/shopping_list_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'detalhe adiciona e remove compras, aba marca e limpa ingredientes',
    (tester) async {
      final meal = {
        'idMeal': '1',
        'strMeal': 'Arroz',
        'strMealThumb': '',
        'strIngredient1': 'Arroz',
        'strMeasure1': '1 xícara',
        'strIngredient2': 'Água',
        'strMeasure2': '2 xícaras',
      };
      final api = TheMealDbApi(
        client: MockClient((request) async {
          final body = request.url.path.endsWith('categories.php')
              ? {'categories': []}
              : {
                  'meals': [meal],
                };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      await tester.pumpWidget(
        TheMealDbFinalApp(
          api: api,
          favoritesStore: FavoritesStore(),
          shoppingListStore: ShoppingListStore(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compras').last);
      await tester.pumpAndSettle();
      expect(find.text('Sua lista está vazia'), findsOneWidget);
      await tester.tap(find.text('Receitas').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arroz').first);
      await tester.pumpAndSettle();
      final add = find.text('Adicionar à lista de compras');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.text('Na lista de compras'), findsOneWidget);
      await tester.tap(find.text('Na lista de compras'));
      await tester.pumpAndSettle();
      expect(add, findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compras').last);
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar comprados'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Água'), findsOneWidget);
    },
  );
}
