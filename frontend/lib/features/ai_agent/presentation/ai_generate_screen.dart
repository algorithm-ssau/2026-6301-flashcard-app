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

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGenerateStateProvider);
    final decksAsync = ref.watch(decksForAiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Генерация по теме'),
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
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Тема',
                hintText: 'Например: Квантовая физика',
              ),
            ),
            const SizedBox(height: 16),
            Text('Количество карточек: ${_count.round()}'),
            Slider(
              value: _count,
              min: AppConstants.minAiCards.toDouble(),
              max: AppConstants.maxAiCards.toDouble(),
              divisions: AppConstants.maxAiCards - AppConstants.minAiCards,
              onChanged: (v) => setState(() => _count = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Сложность'),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Начальный')),
                DropdownMenuItem(value: 'intermediate', child: Text('Средний')),
                DropdownMenuItem(value: 'advanced', child: Text('Продвинутый')),
              ],
              onChanged: (v) => setState(() => _difficulty = v ?? 'beginner'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(labelText: 'Язык'),
              items: const [
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'ru'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _createNewDeck,
                  onChanged: (v) => setState(() => _createNewDeck = v ?? true),
                ),
                const Text('Создать новую колоду'),
              ],
            ),
            if (!_createNewDeck)
              decksAsync.when(
                data: (decks) => DropdownButtonFormField<String>(
                  value: _selectedDeckId,
                  decoration: const InputDecoration(labelText: 'Колода'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Выберите —')),
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
            if (aiState.status == 'starting' &&
                aiState.cards == null &&
                aiState.error == null)
              const GenerationProgressWidget(status: 'Генерация...'),
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
                onPressed: aiState.status == 'starting' ? null : _generate,
                child: aiState.status == 'starting'
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Генерировать',
                        style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}