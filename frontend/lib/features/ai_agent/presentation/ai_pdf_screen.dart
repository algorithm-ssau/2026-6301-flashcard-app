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

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiPdfStateProvider);
    final decksAsync = ref.watch(decksForAiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Генерация из PDF'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.picture_as_pdf,
                        size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      aiState.filePath != null
                          ? '${aiState.filePath!.split(RegExp(r'[/\\]')).last}\n${(aiState.fileSize! / 1024).toStringAsFixed(1)} KB'
                          : 'Нажмите чтобы выбрать PDF',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Количество карточек: ${_count.round()}'),
            Slider(
              value: _count,
              min: AppConstants.minAiCards.toDouble(),
              max: AppConstants.maxAiCards.toDouble(),
              divisions: AppConstants.maxAiCards - AppConstants.minAiCards,
              onChanged: (v) => setState(() => _count = v),
            ),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(labelText: 'Язык'),
              items: const [
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'ru'),
            ),
            const SizedBox(
              height: 20,
            ),
            decksAsync.when(
              data: (decks) => DropdownButtonFormField<String>(
                value: _selectedDeckId,
                decoration:
                    const InputDecoration(labelText: 'Колода (необязательно)'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('— Новая колода —')),
                  ...decks.map((d) =>
                      DropdownMenuItem(value: d.id, child: Text(d.title))),
                ],
                onChanged: (v) => setState(() => _selectedDeckId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            if (aiState.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(aiState.error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (aiState.status == 'uploading' &&
                aiState.cards == null &&
                aiState.error == null)
              const GenerationProgressWidget(status: 'Загрузка...'),
            if (aiState.cards != null) ...[
              Text('Создано карточек: ${aiState.cards!.length}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...aiState.cards!.take(10).map((c) => Card(
                    child: ListTile(
                      title: Text((c['question'] ?? '').length > 60
                          ? '${(c['question'] ?? '').substring(0, 60)}...'
                          : c['question'] ?? ''),
                      subtitle: Text((c['answer'] ?? '').length > 40
                          ? '${(c['answer'] ?? '').substring(0, 40)}...'
                          : c['answer'] ?? ''),
                    ),
                  )),
              if (aiState.cards!.length > 10)
                Text('... и ещё ${aiState.cards!.length - 10}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _savingToDeck ? null : _saveToDeck,
                icon: const Icon(Icons.save),
                label: Text(
                    _savingToDeck ? 'Сохранение...' : 'Сохранить в колоду'),
              ),
            ],
            if (aiState.cards == null)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(50), // увеличивает ТОЛЬКО высоту
                ),
                onPressed:
                    (aiState.status == 'uploading' || aiState.filePath == null)
                        ? null
                        : _generate,
                child: aiState.status == 'uploading'
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Создать карточки',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}