import 'meal.dart';

/// Texto puro: pode ser testado sem abrir a folha de compartilhamento.
String shareText(MealDetail meal) {
  final lines = <String>[
    meal.name,
    '',
    'Ingredientes:',
    for (final ingredient in meal.ingredients)
      '- ${ingredient.name}${ingredient.measure.isEmpty ? '' : ' — ${ingredient.measure}'}',
  ];
  final link = meal.sourceUrl.isNotEmpty ? meal.sourceUrl : meal.youtubeUrl;
  if (link.isNotEmpty) lines.addAll(['', 'Receita: $link']);
  return lines.join('\n');
}
