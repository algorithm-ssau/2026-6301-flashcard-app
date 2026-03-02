import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/router/app_router.dart';
import '../data/models/study_stats_model.dart';
import '../providers/study_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(studyStatsProvider(deckId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => _StatsContent(deckId: deckId, stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка: $err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(studyStatsProvider(deckId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.deckId, required this.stats});

  final String deckId;
  final StudyStatsModel stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalCards;
    final sections = <PieChartSectionData>[];
    if (total > 0) {
      if (stats.dueToday > 0) {
        sections.add(PieChartSectionData(
          value: stats.dueToday.toDouble(),
          title: '${stats.dueToday}',
          color: Colors.orange,
          radius: 60,
        ));
      }
      if (stats.learnedCards > 0) {
        sections.add(PieChartSectionData(
          value: stats.learnedCards.toDouble(),
          title: '${stats.learnedCards}',
          color: Colors.green,
          radius: 60,
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sections.isNotEmpty)
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Нет данных для отображения'),
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Всего карточек',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600)),
                  Text('${stats.totalCards} карточек'),
                  const SizedBox(height: 12),
                  const Text('На сегодня',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600)),
                  Text('${stats.dueToday} карточек к повторению'),
                  const SizedBox(height: 12),
                  const Text('Выучено',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600)),
                  Text('${stats.learnedCards} карточек'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.studyPath(deckId)),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Начать изучение'),
          ),
        ],
      ),
    );
  }
}
