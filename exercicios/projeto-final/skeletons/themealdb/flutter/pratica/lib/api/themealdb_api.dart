import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal.dart';

class TheMealDbApi {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  final http.Client _client;

  TheMealDbApi({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> _get(Uri uri) async {
    try {
      return await _client.get(uri);
    } on SocketException catch (error) {
      throw ApiException(error.toString(), offline: true);
    } on http.ClientException catch (error) {
      throw ApiException(error.message, offline: true);
    }
  }

  Future<List<MealSummary>> fetchList() async {
    final res = await _get(Uri.parse('$baseUrl/search.php?s='));
    if (res.statusCode != 200) {
      throw Exception('Falha ao carregar lista de receitas');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (body['meals'] as List?) ?? [];
    return meals
        .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealDetail> fetchDetail(String id) async {
    final res = await _get(Uri.parse('$baseUrl/lookup.php?i=$id'));
    if (res.statusCode != 200) {
      throw Exception('Falha ao carregar detalhe da receita $id');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = body['meals'] as List;
    return MealDetail.fromJson(meals.first as Map<String, dynamic>);
  }

  /// A própria API filtra por categoria — sem precisar de endpoint separado
  /// de "tipo" como o PokeAPI.
  Future<Set<String>> fetchNamesByCategory(String category) async {
    final res = await _get(
      Uri.parse('$baseUrl/filter.php?c=${Uri.encodeQueryComponent(category)}'),
    );
    if (res.statusCode != 200) {
      throw Exception('Falha ao carregar categoria $category');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (body['meals'] as List?) ?? [];
    return meals.map((e) => e['strMeal'] as String).toSet();
  }

  Future<List<MealSummary>> fetchByCategory(String category) async {
    final res = await _get(
      Uri.parse('$baseUrl/filter.php?c=${Uri.encodeQueryComponent(category)}'),
    );
    if (res.statusCode != 200) {
      throw Exception('Falha ao carregar categoria $category');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (body['meals'] as List?) ?? [];
    return meals
        .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MealSummary>> fetchByLetter(String letter) async {
    final normalized = letter.trim().toLowerCase();
    if (!RegExp(r'^[a-z]$').hasMatch(normalized)) {
      throw ArgumentError.value(letter, 'letter', 'Use uma letra de A a Z.');
    }
    final res = await _get(
      Uri.parse(
        '$baseUrl/search.php?f=${Uri.encodeQueryComponent(normalized)}',
      ),
    );
    if (res.statusCode != 200) {
      throw Exception('Falha ao carregar receitas com a letra $normalized');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final meals = (body['meals'] as List?) ?? [];
    return meals
        .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ApiException implements Exception {
  final String message;
  final bool offline;

  const ApiException(this.message, {this.offline = false});

  @override
  String toString() => message;
}
