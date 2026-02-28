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

  void clear() {
    state = const AiGenerateState();
  }
}

/// State for PDF generation.
final aiPdfStateProvider =
    StateNotifierProvider<AiPdfNotifier, AiPdfState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  return AiPdfNotifier(repo);
});

class AiPdfState {
  const AiPdfState({
    this.filePath,
    this.fileSize,
    this.status = '',
    this.cards,
    this.error,
  });

  final String? filePath;
  final int? fileSize;
  final String status;
  final List<Map<String, String>>? cards;
  final String? error;
}

class AiPdfNotifier extends StateNotifier<AiPdfState> {
  AiPdfNotifier(this._repo) : super(const AiPdfState());

  final AiRepository _repo;

  void setFile(String path, int size) {
    state = AiPdfState(filePath: path, fileSize: size);
  }

  Future<void> startGenerate({
    required int count,
    String language = 'ru',
  }) async {
    if (state.filePath == null) {
      state = const AiPdfState(error: 'Выберите файл');
      return;
    }
    state = AiPdfState(
      filePath: state.filePath,
      fileSize: state.fileSize,
      status: 'uploading',
    );
    try {
      final cards = await _repo.generateFromPdf(
        file: File(state.filePath!),
        count: count,
        language: language,
      );
      state = AiPdfState(
        filePath: state.filePath,
        fileSize: state.fileSize,
        status: 'done',
        cards: cards,
      );
    } catch (e) {
      state = AiPdfState(
        filePath: state.filePath,
        fileSize: state.fileSize,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const AiPdfState();
  }
}
