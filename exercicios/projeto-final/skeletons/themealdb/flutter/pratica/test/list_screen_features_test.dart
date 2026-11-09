import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/api/themealdb_api.dart';
import 'package:themeal_final/main.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/storage/favorites_store.dart';
import 'package:themeal_final/storage/meals_cache.dart';

import 'fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'letter endpoint uses f parameter and treats meals null as empty',
    () async {
      Uri? requestedUri;
      final api = TheMealDbApi(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('{"meals":null}', 200);
        }),
      );

      expect(await api.fetchByLetter('X'), isEmpty);
      expect(requestedUri?.queryParameters['f'], 'x');
    },
  );

  Future<void> open(
    WidgetTester tester, {
    required TheMealDbApi api,
    MealsCache? cache,
  }) async {
    await tester.pumpWidget(
      TheMealDbFinalApp(
        api: api,
        favoritesStore: FavoritesStore(),
        mealsCache: cache,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offline list falls back to cache and shows the banner', (
    tester,
  ) async {
    final cache = MealsCache();
    await cache.saveList([
      const MealSummary(id: '2', name: 'Saved soup', thumbUrl: ''),
    ]);
    await cache.saveCategories(['Beef', 'Dessert']);
    await open(
      tester,
      api: fakeApi(failWith: 'offline'),
      cache: cache,
    );

    expect(find.text('Saved soup'), findsOneWidget);
    expect(
      find.text('Sem internet — mostrando receitas salvas'),
      findsOneWidget,
    );
  });

  testWidgets('letter chip loads recipes from that letter', (tester) async {
    await open(
      tester,
      api: fakeApi(
        byLetter: {
          'a': [
            {'idMeal': '30', 'strMeal': 'Apple pie', 'strMealThumb': ''},
          ],
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('letter-A')));
    await tester.pumpAndSettle();

    expect(find.text('Apple pie'), findsOneWidget);
  });
}
