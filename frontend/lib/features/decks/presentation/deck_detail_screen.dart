import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../data/models/deck_model.dart';
import '../providers/deck_provider.dart';

class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsync = ref.watch(deckDetailProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: deckAsync.valueOrNull?.title != null
            ? Text(deckAsync.valueOrNull!.title)
            : const Text('Колода'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: deckAsync.valueOrNull == null
                ? null
                : () => _showEditDeckDialog(
                      context,
                      ref,
                      deckId,
                      deckAsync.valueOrNull!,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push(AppRoutes.statsPath(deckId)),
          ),
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.studyPath(deckId)),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Начать изучение'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.push(AppRoutes.aiGenerate),
          ),
        ],
      ),
      body: deckAsync.when(
        data: (deck) => _CardList(deck: deck, deckId: deckId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(deckDetailProvider(deckId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardDialog(context, ref, deckId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddCardDialog(
      BuildContext context, WidgetRef ref, String deckId) async {
    final qController = TextEditingController();
    final aController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая карточка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: const InputDecoration(labelText: 'Вопрос'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              decoration: const InputDecoration(labelText: 'Ответ'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (qController.text.trim().isEmpty ||
                  aController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deckRepositoryProvider).createCard(
            deckId,
            question: qController.text.trim(),
            answer: aController.text.trim(),
          );
      ref.invalidate(deckDetailProvider(deckId));
      ref.invalidate(decksListProvider);
    }
  }

  Future<void> _showEditDeckDialog(
    BuildContext context,
    WidgetRef ref,
    String deckId,
    DeckModel deck,
  ) async {
    final titleController = TextEditingController(text: deck.title);
    final descController = TextEditingController(text: deck.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать колоду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ref.read(deckRepositoryProvider).updateDeck(
          deckId,
          title: titleController.text.trim(),
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
        );
    ref.invalidate(deckDetailProvider(deckId));
    ref.invalidate(decksListProvider);
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.deck, required this.deckId});

  final DeckModel deck;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final cards = deck.cards ?? [];

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            const Text('Нет карточек'),
            const SizedBox(height: 8),
            Text(
              'Добавьте карточки вручную или сгенерируйте с ИИ',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _CardTile(card: card, deckId: deckId);
      },
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card, required this.deckId});

  final CardModel card;
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answerPreview = card.answer.length > 80
        ? '${card.answer.substring(0, 80)}...'
        : card.answer;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title:
            Text(card.question, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle:
            Text(answerPreview, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => _showEditCardDialog(context, ref),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteCard(context, ref),
        ),
      ),
    );
  }

  Future<void> _showEditCardDialog(BuildContext context, WidgetRef ref) async {
    final qController = TextEditingController(text: card.question);
    final aController = TextEditingController(text: card.answer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать карточку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: const InputDecoration(labelText: 'Вопрос'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aController,
              decoration: const InputDecoration(labelText: 'Ответ'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (qController.text.trim().isEmpty ||
                  aController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;
    await ref.read(deckRepositoryProvider).updateCard(
          deckId,
          card.id,
          question: qController.text.trim(),
          answer: aController.text.trim(),
        );
    ref.invalidate(deckDetailProvider(deckId));
    ref.invalidate(decksListProvider);
  }

  Future<void> _deleteCard(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить карточку?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await ref.read(deckRepositoryProvider).deleteCard(deckId, card.id);
    ref.invalidate(deckDetailProvider(deckId));
    ref.invalidate(decksListProvider);
  }
}
