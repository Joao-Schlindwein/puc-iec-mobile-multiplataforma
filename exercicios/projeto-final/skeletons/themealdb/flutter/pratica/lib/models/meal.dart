class MealSummary {
  final String id;
  final String name;
  final String thumbUrl;

  MealSummary({required this.id, required this.name, required this.thumbUrl});

  Map<String, dynamic> toJson() => {
    'idMeal': id,
    'strMeal': name,
    'strMealThumb': thumbUrl,
  };

  factory MealSummary.fromJson(Map<String, dynamic> json) => MealSummary(
    id: json['idMeal'] as String,
    name: json['strMeal'] as String,
    thumbUrl: json['strMealThumb'] as String? ?? '',
  );
}

class MealDetail {
  final String id;
  final String name;
  final String category;
  final String area;
  final String thumbUrl;

  MealDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumbUrl,
  });

  factory MealDetail.fromJson(Map<String, dynamic> json) => MealDetail(
    id: json['idMeal'] as String,
    name: json['strMeal'] as String,
    category: json['strCategory'] as String? ?? '',
    area: json['strArea'] as String? ?? '',
    thumbUrl: json['strMealThumb'] as String? ?? '',
  );
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
