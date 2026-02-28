import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../decks/providers/deck_provider.dart';
import '../data/ai_repository.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository();
});

/// List of decks for AI "save to deck" dropdown.
final decksForAiProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(deckRepositoryProvider);
  return repo.getDecks();
});

/// State for generate-by-topic.
final aiGenerateStateProvider =
    StateNotifierProvider<AiGenerateNotifier, AiGenerateState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  return AiGenerateNotifier(repo);
});

class AiGenerateState {
  const AiGenerateState({
    this.status = '',
    this.cards,
    this.error,
  });

  final String status;
  final List<Map<String, String>>? cards;
  final String? error;
}

class AiGenerateNotifier extends StateNotifier<AiGenerateState> {
  AiGenerateNotifier(this._repo) : super(const AiGenerateState());

  final AiRepository _repo;

  Future<void> startGenerate({
    required String topic,
    required int count,
    required String language,
    required String difficulty,
  }) async {
    state = const AiGenerateState(status: 'starting');
    try {
      final cards = await _repo.generateCards(
        topic: topic,
        count: count,
        language: language,
        difficulty: difficulty,
      );
      state = AiGenerateState(status: 'done', cards: cards);
    } catch (e) {
      state = AiGenerateState(error: e.toString());
    }
  }
}