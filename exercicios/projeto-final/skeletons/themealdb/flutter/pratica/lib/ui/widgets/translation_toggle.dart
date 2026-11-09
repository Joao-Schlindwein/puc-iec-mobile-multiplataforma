import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/translation_controller.dart';

/// Botão da barra superior que alterna as receitas entre português e o
/// original em inglês. Mostra quando o tradutor está sendo baixado e quando
/// não está disponível.
class TranslationToggle extends StatelessWidget {
  const TranslationToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final translation = context.watch<TranslationController>();
    final scheme = Theme.of(context).colorScheme;

    if (translation.enabled &&
        translation.status == TranslationStatus.preparing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Tooltip(
          message: 'Preparando o tradutor de português…',
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final unavailable =
        translation.enabled &&
        translation.status == TranslationStatus.unavailable;
    final String tooltip;
    if (unavailable) {
      tooltip = 'Tradutor indisponível. Toque para tentar baixar de novo.';
    } else if (translation.translating) {
      tooltip = 'Receitas em português. Toque para ver o original em inglês.';
    } else {
      tooltip = 'Receitas no original em inglês. Toque para traduzir.';
    }

    return IconButton(
      tooltip: tooltip,
      isSelected: translation.translating,
      icon: Badge(
        isLabelVisible: unavailable,
        backgroundColor: scheme.error,
        smallSize: 8,
        child: const Icon(Icons.translate),
      ),
      selectedIcon: Icon(Icons.translate, color: scheme.primary),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final turnOn = unavailable || !translation.enabled;
        await translation.setEnabled(turnOn);
        final String message;
        if (!turnOn) {
          message = 'Mostrando as receitas no original em inglês.';
        } else if (translation.translating) {
          message = 'Mostrando as receitas em português.';
        } else {
          message =
              'Não deu para preparar o tradutor. Conecte-se à internet para baixá-lo.';
        }
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}
