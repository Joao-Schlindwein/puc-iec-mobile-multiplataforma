/// Ingrediente de uma receita salvo na lista de compras.
class ShoppingItem {
  final String mealId;
  final String mealName;
  final String ingredient;
  final String measure;
  final bool checked;

  const ShoppingItem({
    required this.mealId,
    required this.mealName,
    required this.ingredient,
    required this.measure,
    this.checked = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    final item = ShoppingItem(
      mealId: json['mealId'] as String,
      mealName: json['mealName'] as String,
      ingredient: json['ingredient'] as String,
      measure: json['measure'] as String,
      checked: json['checked'] as bool,
    );
    if (item.mealId.trim().isEmpty || item.ingredient.trim().isEmpty) {
      throw const FormatException('Item de compras inválido');
    }
    return item;
  }

  ShoppingItem withChecked(bool value) => ShoppingItem(
    mealId: mealId,
    mealName: mealName,
    ingredient: ingredient,
    measure: measure,
    checked: value,
  );

  Map<String, dynamic> toJson() => {
    'mealId': mealId,
    'mealName': mealName,
    'ingredient': ingredient,
    'measure': measure,
    'checked': checked,
  };
}
