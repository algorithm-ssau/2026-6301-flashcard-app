import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/streak_model.dart';
import '../../providers/streak_provider.dart';

class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      data: (streak) => _StreakCard(streak: streak),
      loading: () => const _StreakCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StreakModel streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = streak.isActiveToday;
    final isAtRisk = streak.isAtRisk;

    final flameColor = isActive
        ? const Color(0xFFFF6B00)
        : isAtRisk
            ? Colors.orange.shade300
            : colorScheme.outlineVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: flameColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streak.currentStreak} ${_dayLabel(streak.currentStreak)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? flameColor : null,
                      ),
                ),
                if (isAtRisk)
                  Text(
                    'Учитесь сегодня, чтобы не потерять стрик!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                  )
                else if (!isActive && streak.currentStreak > 0)
                  Text(
                    'Стрик прерван',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                  )
                else
                  Text(
                    'Рекорд: ${streak.longestStreak} дн.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Spacer(),
            if (streak.totalStudyDays > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${streak.totalStudyDays}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'всего дней',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(int n) {
    if (n % 100 >= 11 && n % 100 <= 14) return 'дней';
    switch (n % 10) {
      case 1:
        return 'день';
      case 2:
      case 3:
      case 4:
        return 'дня';
      default:
        return 'дней';
    }
  }
}

class _StreakCardSkeleton extends StatelessWidget {
  const _StreakCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
