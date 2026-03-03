import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../decks/providers/deck_provider.dart';
import '../providers/ai_provider.dart';
import 'widgets/generation_progress_widget.dart';

class AiPdfScreen extends ConsumerStatefulWidget {
  const AiPdfScreen({super.key});

  @override
  ConsumerState<AiPdfScreen> createState() => _AiPdfScreenState();
}

class _AiPdfScreenState extends ConsumerState<AiPdfScreen> {
  double _count = 20;
  String _language = 'ru';
  String? _selectedDeckId;
  bool _savingToDeck = false;

  @override
  void initState() {
    super.initState();
    ref.read(aiPdfStateProvider.notifier).clear();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result?.files.single.path != null) {
      final path = result!.files.single.path!;
      final file = File(path);
      ref.read(aiPdfStateProvider.notifier).setFile(path, await file.length());
    }
  }

  Future<void> _generate() async {
    await ref.read(aiPdfStateProvider.notifier).startGenerate(
          count: _count.round(),
          language: _language,
        );
  }

  Future<void> _saveToDeck() async {
    if (_savingToDeck) return;
    final state = ref.read(aiPdfStateProvider);
    final cards = state.cards;
    if (cards == null || cards.isEmpty) return;

    setState(() => _savingToDeck = true);
    try {
      final deckRepo = ref.read(deckRepositoryProvider);
      String? deckId = _selectedDeckId;
      if (deckId == null &&
          ref.read(decksForAiProvider).valueOrNull?.isNotEmpty == true) {
        deckId = ref.read(decksForAiProvider).valueOrNull!.first.id;
      }
      if (deckId == null) {
        final deck = await deckRepo.createDeck(
            title: 'ИИ из PDF', description: 'Из файла PDF');
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
      ref.read(aiPdfStateProvider.notifier).clear();
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