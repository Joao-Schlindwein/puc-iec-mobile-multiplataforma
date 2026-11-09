import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal.dart';

/// Erro da camada de dados com mensagem pronta para o usuário.
/// `offline` diferencia "sem internet" de "o servidor falhou", porque a
/// tela mostra ícone e texto diferentes para cada caso.
class ApiException implements Exception {
  final String message;
  final bool offline;

  const ApiException(this.message, {this.offline = false});

  @override
  String toString() => message;
}

/// Camada de dados: só fala HTTP + JSON, sem nada de UI.
/// O `http.Client` é injetável para os testes usarem `MockClient`.
class TheMealDbApi {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;

  TheMealDbApi({http.Client? client}) : _client = client ?? http.Client();

  /// Receitas da tela inicial (o "dataset seed" público de `search.php?s=`).
  Future<List<MealSummary>> fetchList() async {
    final body = await _get('search.php?s=');
    return _summaries(body);
  }

  /// Busca por nome no catálogo inteiro da API (`search.php?s=`), não só nas
  /// receitas da tela inicial.
  Future<List<MealSummary>> search(String query) async {
    final body = await _get(
      'search.php?s=${Uri.encodeQueryComponent(query.trim())}',
    );
    return _summaries(body);
  }

  /// Receitas de uma categoria, filtradas pela própria API (`filter.php?c=`).
  Future<List<MealSummary>> fetchByCategory(String category) async {
    final body = await _get(
      'filter.php?c=${Uri.encodeQueryComponent(category)}',
    );
    return _summaries(body);
  }

  /// Receitas cujo nome começa com a letra escolhida (`search.php?f=`).
  Future<List<MealSummary>> fetchByLetter(String letter) async {
    final normalized = letter.trim().toLowerCase();
    if (!RegExp(r'^[a-z]$').hasMatch(normalized)) {
      throw ArgumentError.value(letter, 'letter', 'Use uma letra de A a Z.');
    }
    final body = await _get(
      'search.php?f=${Uri.encodeQueryComponent(normalized)}',
    );
    return _summaries(body);
  }

  /// Nomes das categorias reais (Beef, Dessert, Seafood…).
  Future<List<String>> fetchCategories() async {
    final body = await _get('categories.php');
    final list = (body['categories'] as List?) ?? const [];
    return list
        .map((e) => (e as Map<String, dynamic>)['strCategory'] as String)
        .toList();
  }

  Future<MealDetail> fetchDetail(String id) async {
    final body = await _get('lookup.php?i=${Uri.encodeQueryComponent(id)}');
    final meals = body['meals'] as List?;
    if (meals == null || meals.isEmpty) {
      throw const ApiException('Receita não encontrada.');
    }
    return MealDetail.fromJson(meals.first as Map<String, dynamic>);
  }

  List<MealSummary> _summaries(Map<String, dynamic> body) {
    // A API devolve `"meals": null` quando não há resultado.
    final meals = (body['meals'] as List?) ?? const [];
    return meals
        .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final http.Response res;
    try {
      res = await _client.get(Uri.parse('$baseUrl/$path')).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Verifique sua conexão.',
        offline: true,
      );
    } on http.ClientException {
      throw const ApiException('Sem conexão com a internet.', offline: true);
    }
    if (res.statusCode != 200) {
      throw ApiException(
        'O servidor de receitas respondeu com erro (${res.statusCode}).',
      );
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Resposta inválida do servidor de receitas.');
    }
  }
}
