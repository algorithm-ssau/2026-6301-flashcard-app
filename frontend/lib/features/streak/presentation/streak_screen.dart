import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/streak_provider.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Стрик'),
      ),
      body: streakAsync.when(
        data: (streak) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StreakHero(currentStreak: streak.currentStreak),
              const SizedBox(height: 24),
              _StatRow(
                label: 'Текущий стрик',
                value: '${streak.currentStreak} дн.',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF6B00),
              ),
              const Divider(height: 1),
              _StatRow(
                label: 'Рекорд',
                value: '${streak.longestStreak} дн.',
                icon: Icons.emoji_events_rounded,
                iconColor: Colors.amber,
              ),
              const Divider(height: 1),
              _StatRow(
                label: 'Всего дней занятий',
                value: '${streak.totalStudyDays}',
                icon: Icons.calendar_today_rounded,
                iconColor: Colors.blue,
              ),
              const SizedBox(height: 32),
              if (!streak.isActiveToday)
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(streakProvider.notifier).recordSession(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Начать занятие'),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 64,
              color: Color(0xFFFF6B00),
            ),
            const SizedBox(height: 12),
            Text(
              '$currentStreak',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B00),
                  ),
            ),
            Text(
              'дней подряд',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
