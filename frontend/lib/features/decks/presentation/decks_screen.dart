import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../providers/deck_provider.dart';
import 'widgets/deck_card_widget.dart';

class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои колоды'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: decksAsync.when(
        data: (decks) {
          if (decks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Нет колод',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Создайте колоду или сгенерируйте с ИИ'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(decksListProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: decks.length,
              itemBuilder: (context, index) {
                final deck = decks[index];
                return DeckCardWidget(
                  deck: deck,
                  learnedCount: 0,
                  onDelete: () =>
                      _confirmDelete(context, ref, deck.id, deck.title),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(decksListProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'ai',
              onPressed: () => context.push(AppRoutes.aiGenerate),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Создать с ИИ'),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'manual',
              onPressed: () => _showCreateDeckDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Создать вручную'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDeckDialog(
      BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая колода'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(labelText: 'Описание (необязательно)'),
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
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (created == true && context.mounted) {
      await ref.read(deckRepositoryProvider).createDeck(
            title: titleController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
          );
      ref.invalidate(decksListProvider);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String deckId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить колоду?'),
        content: Text('Колода «$title» и все карточки будут удалены.'),
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
    if (ok == true && context.mounted) {
      await ref.read(deckRepositoryProvider).deleteDeck(deckId);
      ref.invalidate(decksListProvider);
    }
  }
}
