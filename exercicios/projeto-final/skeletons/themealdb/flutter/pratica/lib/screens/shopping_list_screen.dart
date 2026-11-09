import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shopping_list_controller.dart';
import '../state/translation_controller.dart';
import '../ui/theme.dart';
import '../ui/widgets/state_message.dart';
import '../ui/widgets/translation_toggle.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingListController>();
    final tr = context.watch<TranslationController>();
    final groups = shopping.groupedByMeal.values.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compras'),
        actions: const [TranslationToggle()],
      ),
      body: !shopping.loaded
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? const StateMessage(
              icon: Icons.shopping_basket_outlined,
              title: 'Sua lista está vazia',
              message: 'Adicione ingredientes pelo detalhe da receita.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: shopping.items.any((item) => item.checked)
                          ? () => _save(context, shopping.clearChecked)
                          : null,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Limpar comprados'),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    itemCount: groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTokens.space4),
                    itemBuilder: (context, index) {
                      final items = groups[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppTokens.space4),
                              child: Text(
                                tr.text(items.first.mealName),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            for (final item in items)
                              CheckboxListTile(
                                value: item.checked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  tr.text(item.ingredient),
                                  style: TextStyle(
                                    decoration: item.checked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: item.measure.isEmpty
                                    ? null
                                    : Text(tr.text(item.measure)),
                                onChanged: (_) =>
                                    _save(context, () => shopping.toggle(item)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a lista. Tente novamente.'),
        ),
      );
    }
  }
}
