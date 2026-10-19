// lib/state/favorites.dart
//
// Ex2 (TASK 2): estado compartilhado de favoritos com Riverpod (local).
// Ex4 (TASK 7): mesmo provider, mas sincronizado com Firestore (cloud).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint

// ── Ex4 · TASK 7 — persistência Firestore (ativa) ──────────────────────────────────────────────
// 1 documento por aluno (seu projeto = seu Firestore). Mesma interface (toggle/clear) do Ex2,
// mas agora sincroniza com a nuvem: o estado começa vazio e é populado assim que o Firestore
// responde (leitura async em build()); toggle/clear atualizam o state local de forma otimista
// (a UI reage na hora) e gravam a mudança em paralelo.
const _favDoc = 'favorites/meus-favoritos';

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    _load(); // dispara leitura async; state começa vazio até o Firestore responder
    return {};
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance.doc(_favDoc).get();
      final ids = (doc.data()?['ids'] as List<dynamic>?)?.cast<int>() ?? <int>[];
      state = ids.toSet();
    } catch (e) {
      // offline, ou `flutter test` — mantém vazio (mesmo comportamento do TASK 2).
      // O erro aparece no console: `permission-denied` = revise as REGRAS do Firestore.
      // (no `flutter test` aparece "No Firebase App" — é esperado, o Firebase não sobe em teste)
      debugPrint('Firestore (ler): $e');
    }
  }

  Future<void> _persist(Set<int> next) async {
    try {
      await FirebaseFirestore.instance.doc(_favDoc).set({'ids': next.toList()});
    } catch (e) {
      // offline, ou `flutter test` (Firebase não inicializado em widget test) — tudo bem,
      // o estado local (otimista) já refletiu a mudança na UI.
      debugPrint('Firestore (gravar): $e'); // `permission-denied` = regras
    }
  }

  void toggle(int id) {
    final next = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    state = next; // UI reage na hora (otimista)
    _persist(next); // grava no Firestore em paralelo
  }

  void clear() {
    state = {};
    _persist({});
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

// 👉 Teste você mesmo: favorita um filme, dá F5 na página — o favorito sobrevive (antes, sumia).
