import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/api/themealdb_api.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/screens/list_screen.dart';
import 'package:themeal_final/storage/meals_cache.dart';

class FakeMealApi extends TheMealDbApi {
  FakeMealApi({this.offline = false});

  final bool offline;
  List<MealSummary> initial = [];
  List<MealSummary> byLetter = [];
  List<MealSummary> byCategory = [];
  String? lastLetter;

  void _checkConnection() {
    if (offline) throw const ApiException('offline', offline: true);
  }

  @override
  Future<List<MealSummary>> fetchList() async {
    _checkConnection();
    return initial;
  }

  @override
  Future<List<MealSummary>> fetchByLetter(String letter) async {
    _checkConnection();
    lastLetter = letter;
    return byLetter;
  }

  @override
  Future<List<MealSummary>> fetchByCategory(String category) async {
    _checkConnection();
    return byCategory;
  }
}

MealSummary meal(String id, String name) =>
    MealSummary(id: id, name: name, thumbUrl: '');

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
    WidgetTester tester,
    FakeMealApi api,
    MealsCache cache,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListScreen(api: api, cache: cache),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('online list is shown and saved in cache', (tester) async {
    final api = FakeMealApi()..initial = [meal('1', 'Apple cake')];
    final cache = MealsCache();
    await open(tester, api, cache);

    expect(find.text('Apple cake'), findsOneWidget);
    expect((await cache.loadList())?.single.name, 'Apple cake');
  });

  testWidgets('offline list falls back to cache with a banner', (tester) async {
    final cache = MealsCache();
    await cache.saveList([meal('2', 'Saved soup')]);
    await open(tester, FakeMealApi(offline: true), cache);

    expect(find.text('Saved soup'), findsOneWidget);
    expect(
      find.text('Sem internet — mostrando receitas salvas'),
      findsOneWidget,
    );
  });

  testWidgets('offline without cached list shows error and retry', (
    tester,
  ) async {
    await open(tester, FakeMealApi(offline: true), MealsCache());

    expect(
      find.text('Você está sem internet e ainda não há receitas salvas.'),
      findsOneWidget,
    );
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('offline category uses that category cache', (tester) async {
    final cache = MealsCache();
    await cache.saveCategory('Beef', [meal('3', 'Cached beef')]);
    await cache.saveList([meal('1', 'Cached list')]);
    await open(tester, FakeMealApi(offline: true), cache);
    await tester.tap(find.text('Beef'));
    await tester.pumpAndSettle();

    expect(find.text('Cached beef'), findsOneWidget);
    expect(
      find.text('Sem internet — mostrando receitas salvas'),
      findsOneWidget,
    );
  });

  testWidgets(
    'letter results work with local search; category and letter are exclusive',
    (tester) async {
      final api = FakeMealApi()
        ..initial = [meal('1', 'Initial meal')]
        ..byLetter = [meal('2', 'Apple pie'), meal('3', 'Apple tart')]
        ..byCategory = [meal('4', 'Beef stew')];
      await open(tester, api, MealsCache());

      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      expect(api.lastLetter, 'A');
      expect(find.text('Apple pie'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tart');
      await tester.pump();
      expect(find.text('Apple tart'), findsOneWidget);
      expect(find.text('Apple pie'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.text('Beef'));
      await tester.pumpAndSettle();
      expect(find.text('Beef stew'), findsOneWidget);
      expect(find.text('Apple pie'), findsNothing);
    },
  );

  testWidgets('empty API letter response displays empty state', (tester) async {
    final api = FakeMealApi()..initial = [meal('1', 'Initial meal')];
    await open(tester, api, MealsCache());
    await tester.drag(find.byType(ListView).at(1), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('letter-Z')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma receita encontrada.'), findsOneWidget);
  });
}
