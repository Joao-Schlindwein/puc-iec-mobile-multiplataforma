// lib/widgets/offline_banner.dart
//
// TASK 11: mostra um aviso quando NÃO há conexão.
//
// O teste está em test/offline_test.dart (NÃO edite).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/network.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    if (online) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Text(
        'Você está offline — mostrando dados salvos',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
