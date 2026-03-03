import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../decks/providers/deck_provider.dart';
import '../providers/ai_provider.dart';
import 'widgets/generation_progress_widget.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  const AiGenerateScreen({super.key});

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen> {
  final _topicController = TextEditingController();
  double _count = 20;
  String _difficulty = 'beginner';
  String _language = 'ru';
  String? _selectedDeckId;
  bool _createNewDeck = true;
  bool _savingToDeck = false;

  @override
  void initState() {
    super.initState();
    ref.read(aiGenerateStateProvider.notifier).clear();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_topicController.text.trim().isEmpty) return;

    await ref.read(aiGenerateStateProvider.notifier).startGenerate(
          topic: _topicController.text.trim(),
          count: _count.round(),
          language: _language,
          difficulty: _difficulty,
        );
  }

  Future<void> _saveToDeck() async {
    if (_savingToDeck) return;
    final state = ref.read(aiGenerateStateProvider);
    final cards = state.cards;
    if (cards == null || cards.isEmpty) return;

    setState(() => _savingToDeck = true);
    try {
      final deckRepo = ref.read(deckRepositoryProvider);
      String? deckId = _selectedDeckId;
      if (_createNewDeck || deckId == null) {
        final deck = await deckRepo.createDeck(
          title: 'ИИ: ${_topicController.text.trim()}',
          description: 'Сгенерировано ИИ',
        );
        deckId = deck.id;
      }

      for (final c in cards) {
        await deckRepo.createCard(
          deckId,
          question: c['question'] ?? '',
          answer: c['answer'] ?? '',
        );
      }

      ref.invalidate(decksListProvider);
      ref.invalidate(deckDetailProvider(deckId));
      ref.read(aiGenerateStateProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Карточки сохранены')),
        );
        context.go(AppRoutes.deckDetailPath(deckId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingToDeck = false);
      }
    }
  }
}