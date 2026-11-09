import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/state/meal_detail_controller.dart';
import 'package:themeal_final/state/meal_list_controller.dart';
import 'package:themeal_final/storage/meals_cache.dart';

import 'fake_api.dart';

/// Recorte real de `lookup.php?i=52772` (Teriyaki Chicken Casserole), com
/// os campos vazios/nulos/só-espaço que a API manda de verdade.
Map<String, dynamic> teriyakiJson() {
  final json = <String, dynamic>{
    'idMeal': '52772',
    'strMeal': 'Teriyaki Chicken Casserole',
    'strCategory': 'Chicken',
    'strArea': 'Japanese',
    'strMealThumb':
        'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
    'strTags': 'Meat,Casserole',
    'strInstructions':
        'STEP 1\r\nPreheat oven to 350° F.\r\n\r\nSTEP 2\r\n'
        'Combine soy sauce and sugar.',
    'strIngredient1': 'soy sauce',
    'strMeasure1': '3/4 cup',
    'strIngredient2': 'water',
    'strMeasure2': '1/2 cup ',
    'strIngredient3': ' brown sugar ',
    'strMeasure3': '1/4 cup',
    'strIngredient4': '',
    'strMeasure4': '',
    'strIngredient5': ' ',
    'strMeasure5': ' ',
  };
  for (var i = 6; i <= 20; i++) {
    json['strIngredient$i'] = null;
    json['strMeasure$i'] = null;
  }
  return json;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MealDetail.fromJson', () {
    test('lê links de vídeo e fonte removendo espaços', () {
      final detail = MealDetail.fromJson(
        teriyakiJson()
          ..['strYoutube'] = ' https://www.youtube.com/watch?v=abc '
          ..['strSource'] = ' https://example.com/receita ',
      );
      expect(detail.youtubeUrl, 'https://www.youtube.com/watch?v=abc');
      expect(detail.sourceUrl, 'https://example.com/receita');
    });

    test('links vazios, nulos e ausentes viram texto vazio', () {
      for (final value in ['', '   ', null]) {
        final detail = MealDetail.fromJson(
          teriyakiJson()
            ..['strYoutube'] = value
            ..['strSource'] = value,
        );
        expect(detail.youtubeUrl, isEmpty);
        expect(detail.sourceUrl, isEmpty);
      }
      final missing = MealDetail.fromJson(teriyakiJson());
      expect(missing.youtubeUrl, isEmpty);
      expect(missing.sourceUrl, isEmpty);
    });
    test('só mantém ingredientes preenchidos, sem espaços sobrando', () {
      final detail = MealDetail.fromJson(teriyakiJson());

      expect(detail.ingredients.map((i) => i.name), [
        'soy sauce',
        'water',
        'brown sugar',
      ]);
      expect(detail.ingredients[1].measure, '1/2 cup');
    });

    test('separa as tags e tira os marcadores "STEP n" do preparo', () {
      final detail = MealDetail.fromJson(teriyakiJson());

      expect(detail.tags, ['Meat', 'Casserole']);
      expect(detail.steps, [
        'Preheat oven to 350° F.',
        'Combine soy sauce and sugar.',
      ]);
    });

    test('aguenta tags nulas e vira resumo para os favoritos', () {
      final json = teriyakiJson()..['strTags'] = null;
      final detail = MealDetail.fromJson(json);

      expect(detail.tags, isEmpty);
      expect(detail.toSummary().name, 'Teriyaki Chicken Casserole');
    });
  });

  group('MealDetailController offline cache', () {
    test('saves a detail fetched online for later offline use', () async {
      final cache = MealsCache();
      final controller = MealDetailController(
        fakeApi(
          details: {'52772': mealDetailJson('52772', 'Teriyaki Chicken')},
        ),
        '52772',
        cache: cache,
      );

      await controller.load();
      final cached = await cache.loadDetail('52772');

      expect(controller.status, LoadStatus.ready);
      expect(cached?.ingredients.single.name, 'chicken');
      expect(cached?.steps, ['Combine the ingredients.', 'Cook until ready.']);
    });

    test(
      'shows the saved ingredients and instructions without internet',
      () async {
        final cache = MealsCache();
        await cache.saveDetail(
          MealDetail.fromJson(mealDetailJson('52772', 'Teriyaki Chicken')),
        );
        final controller = MealDetailController(
          fakeApi(failWith: 'offline'),
          '52772',
          cache: cache,
        );

        await controller.load();

        expect(controller.status, LoadStatus.ready);
        expect(controller.offline, isTrue);
        expect(controller.detail?.ingredients.single.measure, '2 cups');
        expect(controller.detail?.steps, [
          'Combine the ingredients.',
          'Cook until ready.',
        ]);
      },
    );

    test('vídeo e fonte sobrevivem ao cache offline do detalhe', () async {
      final cache = MealsCache();
      final json = mealDetailJson('52772', 'Teriyaki Chicken')
        ..['strYoutube'] = 'https://www.youtube.com/watch?v=4aZr5hZXP_s'
        ..['strSource'] = 'https://example.com/teriyaki';
      await cache.saveDetail(MealDetail.fromJson(json));

      final cached = await cache.loadDetail('52772');

      expect(cached?.youtubeUrl, 'https://www.youtube.com/watch?v=4aZr5hZXP_s');
      expect(cached?.sourceUrl, 'https://example.com/teriyaki');
    });

    test('does not use cached details for a server error', () async {
      final cache = MealsCache();
      await cache.saveDetail(
        MealDetail.fromJson(mealDetailJson('52772', 'Teriyaki Chicken')),
      );
      final controller = MealDetailController(
        fakeApi(failWith: 500),
        '52772',
        cache: cache,
      );

      await controller.load();

      expect(controller.status, LoadStatus.error);
      expect(controller.offline, isFalse);
      expect(controller.detail, isNull);
    });
  });
}
