import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/deck_repository.dart';
import '../data/models/deck_model.dart';

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final decksListProvider = StreamProvider.autoDispose<List<DeckModel>>((ref) {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.watchDecks();
});

final deckDetailProvider =
    StreamProvider.autoDispose.family<DeckModel, String>((ref, deckId) {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.watchDeck(deckId);
});

void invalidateDecks(Ref ref) {
  ref.invalidate(decksListProvider);
}

void invalidateDeckDetail(Ref ref, String deckId) {
  ref.invalidate(deckDetailProvider(deckId));
}
