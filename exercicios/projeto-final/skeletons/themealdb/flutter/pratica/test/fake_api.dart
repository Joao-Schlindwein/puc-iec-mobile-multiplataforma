import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:themeal_final/api/themealdb_api.dart';

Map<String, dynamic> mealJson(String id, String name) => {
  'idMeal': id,
  'strMeal': name,
  'strMealThumb': 'https://example.com/$id.jpg',
};

Map<String, dynamic> mealDetailJson(String id, String name) => {
  ...mealJson(id, name),
  'strCategory': 'Chicken',
  'strArea': 'Japanese',
  'strInstructions': 'Combine the ingredients.\nCook until ready.',
  'strIngredient1': 'chicken',
  'strMeasure1': '2 cups',
};

/// API com respostas fixas, no formato real da TheMealDB.
/// `failWith` simula falhas: 'offline' (sem rede) ou um status HTTP.
TheMealDbApi fakeApi({
  List<Map<String, dynamic>>? list,
  Map<String, List<Map<String, dynamic>>> byLetter = const {},
  Map<String, Map<String, dynamic>> details = const {},

  /// Catálogo inteiro, onde `search.php?s=<texto>` procura.
  List<Map<String, dynamic>> catalog = const [],
  Map<String, List<Map<String, dynamic>>> byCategory = const {},
  List<String> categories = const ['Beef', 'Dessert', 'Seafood'],
  Object? failWith,
}) {
  final client = MockClient((request) async {
    if (failWith == 'offline') {
      throw http.ClientException('Failed host lookup');
    }
    if (failWith is int) return http.Response('', failWith);

    final path = request.url.path.split('/').last;
    final q = request.url.queryParameters;
    Object body;
    switch (path) {
      case 'search.php':
        final letter = q['f']?.toLowerCase();
        if (letter != null) {
          body = {'meals': byLetter[letter]};
          break;
        }
        final s = (q['s'] ?? '').toLowerCase();
        final source = s.isEmpty
            ? (list ?? [mealJson('1', 'Burek'), mealJson('2', 'Sushi')])
            : catalog;
        final found = source
            .where((m) => (m['strMeal'] as String).toLowerCase().contains(s))
            .toList();
        // Igual à API real: sem resultado vem `"meals": null`.
        body = {'meals': found.isEmpty ? null : found};
      case 'categories.php':
        body = {
          'categories': [
            for (final c in categories) {'strCategory': c},
          ],
        };
      case 'filter.php':
        body = {'meals': byCategory[q['c']]};
      case 'lookup.php':
        final detail = details[q['i']];
        body = {
          'meals': detail == null ? null : [detail],
        };
      default:
        return http.Response('{}', 404);
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return TheMealDbApi(client: client);
}
