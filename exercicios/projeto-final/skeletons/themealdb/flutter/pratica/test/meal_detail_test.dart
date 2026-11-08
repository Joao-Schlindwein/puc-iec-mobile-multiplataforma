import 'package:flutter_test/flutter_test.dart';
import 'package:themeal_final/models/meal.dart';

/// Recorte real de `lookup.php?i=52772` (Teriyaki Chicken Casserole), com
/// os campos vazios/nulos/só-espaço que a API manda de verdade.
Map<String, dynamic> teriyakiJson() {
  final json = <String, dynamic>{
    'idMeal': '52772',
    'strMeal': 'Teriyaki Chicken Casserole',
    'strCategory': 'Chicken',
    'strArea': 'Japanese',
    'strMealThumb': 'https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg',
    'strTags': 'Meat,Casserole',
    'strInstructions': 'STEP 1\r\nPreheat oven to 350° F.\r\n\r\nSTEP 2\r\n'
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
  group('MealDetail.fromJson', () {
    test('só mantém ingredientes preenchidos, sem espaços sobrando', () {
      final detail = MealDetail.fromJson(teriyakiJson());

      expect(detail.ingredients.map((i) => i.name),
          ['soy sauce', 'water', 'brown sugar']);
      expect(detail.ingredients[1].measure, '1/2 cup');
    });

    test('separa as tags e tira os marcadores "STEP n" do preparo', () {
      final detail = MealDetail.fromJson(teriyakiJson());

      expect(detail.tags, ['Meat', 'Casserole']);
      expect(detail.steps,
          ['Preheat oven to 350° F.', 'Combine soy sauce and sugar.']);
    });

    test('aguenta tags nulas e vira resumo para os favoritos', () {
      final json = teriyakiJson()..['strTags'] = null;
      final detail = MealDetail.fromJson(json);

      expect(detail.tags, isEmpty);
      expect(detail.toSummary().name, 'Teriyaki Chicken Casserole');
    });
  });
}
