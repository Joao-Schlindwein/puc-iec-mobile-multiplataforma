import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:themeal_final/models/meal.dart';
import 'package:themeal_final/state/favorites_controller.dart';
import 'package:themeal_final/storage/favorites_store.dart';

const burek = MealSummary(id: '53060', name: 'Burek', thumbUrl: 'b.jpg');
const flan = MealSummary(id: '53322', name: 'Flan', thumbUrl: 'f.jpg');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('favorito sobrevive a "fechar o app" (nova instância lê do disco)',
      () async {
    final first = FavoritesController(FavoritesStore());
    await first.load();
    await first.toggle(burek);
    await first.toggle(flan);

    final reopened = FavoritesController(FavoritesStore());
    await reopened.load();

    expect(reopened.items, [flan, burek], reason: 'mais recente primeiro');
    expect(reopened.isFavorite('53060'), isTrue);
  });

  test('tocar de novo remove, e "Desfazer" devolve na mesma posição',
      () async {
    final favorites = FavoritesController(FavoritesStore());
    await favorites.load();
    await favorites.toggle(burek);
    await favorites.toggle(flan); // [flan, burek]

    await favorites.toggle(flan);
    expect(favorites.items, [burek]);

    await favorites.add(flan, index: 0);
    expect(favorites.items, [flan, burek]);
  });

  test('entrada corrompida no disco é ignorada sem derrubar o app', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_meals_v2': [
        '{"idMeal":"53060","strMeal":"Burek","strMealThumb":"b.jpg"}',
        'isto não é json',
      ],
    });
    final favorites = FavoritesController(FavoritesStore());
    await favorites.load();

    expect(favorites.items, [burek]);
  });
}
