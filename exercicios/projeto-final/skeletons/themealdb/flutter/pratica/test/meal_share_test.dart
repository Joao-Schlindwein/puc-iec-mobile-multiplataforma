import 'package:flutter_test/flutter_test.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/models/meal_share.dart';

import 'meal_detail_test.dart' show teriyakiJson;

void main() {
  test('texto contém nome, todos os ingredientes, medidas e link da fonte', () {
    final meal = MealDetail.fromJson(
      teriyakiJson()
        ..['strSource'] = 'https://example.com/receita'
        ..['strYoutube'] = 'https://www.youtube.com/watch?v=abc',
    );
    final text = shareText(meal);
    expect(text, contains(meal.name));
    for (final ingredient in meal.ingredients) {
      expect(text, contains('${ingredient.name} — ${ingredient.measure}'));
    }
    expect(text, contains('https://example.com/receita'));
  });

  test('sem fonte usa o vídeo; sem ambos não inventa um link', () {
    final json = teriyakiJson()..['strYoutube'] = 'https://youtu.be/abc';
    expect(
      shareText(MealDetail.fromJson(json)),
      contains('https://youtu.be/abc'),
    );
    json['strYoutube'] = null;
    expect(shareText(MealDetail.fromJson(json)), isNot(contains('Receita:')));
  });

  test('ingrediente sem medida não deixa separador solto', () {
    final json = teriyakiJson()..['strMeasure1'] = null;
    expect(shareText(MealDetail.fromJson(json)), contains('- soy sauce\n'));
  });
}
