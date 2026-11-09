/// Item de lista: o que a API devolve em `search.php` e `filter.php`.
/// Também é o que guardamos nos favoritos (id + nome + foto), para a aba
/// Favoritos abrir sem internet.
class MealSummary {
  final String id;
  final String name;
  final String thumbUrl;

  const MealSummary({
    required this.id,
    required this.name,
    required this.thumbUrl,
  });

  factory MealSummary.fromJson(Map<String, dynamic> json) => MealSummary(
    id: json['idMeal'] as String,
    name: json['strMeal'] as String,
    thumbUrl: json['strMealThumb'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'idMeal': id,
    'strMeal': name,
    'strMealThumb': thumbUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is MealSummary &&
      other.id == id &&
      other.name == name &&
      other.thumbUrl == thumbUrl;

  @override
  int get hashCode => Object.hash(id, name, thumbUrl);
}

class Ingredient {
  final String name;
  final String measure;

  const Ingredient({required this.name, required this.measure});

  /// Foto pequena do ingrediente, servida pela própria TheMealDB.
  String get imageUrl =>
      'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(name)}-Small.png';
}

/// Detalhe completo de `lookup.php`.
class MealDetail {
  final String id;
  final String name;
  final String category;
  final String area;
  final String thumbUrl;
  final String instructions;
  final List<String> tags;
  final List<Ingredient> ingredients;
  final String youtubeUrl;
  final String sourceUrl;

  const MealDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumbUrl,
    required this.instructions,
    required this.tags,
    required this.ingredients,
    this.youtubeUrl = '',
    this.sourceUrl = '',
  });

  factory MealDetail.fromJson(Map<String, dynamic> json) => MealDetail(
    id: json['idMeal'] as String,
    name: json['strMeal'] as String,
    category: _text(json['strCategory']),
    area: _text(json['strArea']),
    thumbUrl: _text(json['strMealThumb']),
    instructions: _text(json['strInstructions']),
    youtubeUrl: _text(json['strYoutube']),
    sourceUrl: _text(json['strSource']),
    tags: _text(
      json['strTags'],
    ).split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    ingredients: _parseIngredients(json),
  );

  MealSummary toSummary() =>
      MealSummary(id: id, name: name, thumbUrl: thumbUrl);

  /// Passos do preparo: a API manda um texto só, separado por quebras de
  /// linha (às vezes numerado "STEP 1"). Viram parágrafos limpos.
  List<String> get steps => instructions
      .split(RegExp(r'\r?\n'))
      .map((s) => s.trim())
      .where(
        (s) =>
            s.isNotEmpty &&
            !RegExp(r'^(step\s*)?\d+\.?$', caseSensitive: false).hasMatch(s),
      )
      .toList();

  /// A API devolve `strIngredient1..20` e `strMeasure1..20`, com campos
  /// vazios, `null` ou só espaços quando a receita usa menos de 20.
  static List<Ingredient> _parseIngredients(Map<String, dynamic> json) {
    final result = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final name = _text(json['strIngredient$i']);
      if (name.isEmpty) continue;
      result.add(Ingredient(name: name, measure: _text(json['strMeasure$i'])));
    }
    return result;
  }

  static String _text(Object? value) => (value as String?)?.trim() ?? '';
}
