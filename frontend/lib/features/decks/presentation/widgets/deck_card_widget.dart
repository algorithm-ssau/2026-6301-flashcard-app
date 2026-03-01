import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../data/models/deck_model.dart';

class DeckCardWidget extends StatelessWidget {
  const DeckCardWidget({
    super.key,
    required this.deck,
    this.onDelete,
    this.learnedCount = 0,
  });

  final DeckModel deck;
  final VoidCallback? onDelete;
  final int learnedCount;

  @override
  Widget build(BuildContext context) {
    final total = deck.cardCount;
    final progress = total > 0 ? learnedCount / total : 0.0;

    return Card(
      elevation: AppConstants.cardElevation,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.deckDetailPath(deck.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      deck.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) {
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Удалить колоду'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                '$total карточек',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (total > 0) ...[
                const SizedBox(height: AppConstants.spacingXs),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
