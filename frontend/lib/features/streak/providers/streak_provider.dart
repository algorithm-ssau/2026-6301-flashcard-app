import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/streak_model.dart';
import '../data/streak_repository.dart';

final streakRepositoryProvider = Provider<StreakRepository>(
  (_) => StreakRepository(),
);

final streakProvider = AsyncNotifierProvider<StreakNotifier, StreakModel>(
  StreakNotifier.new,
);

class StreakNotifier extends AsyncNotifier<StreakModel> {
  @override
  Future<StreakModel> build() async {
    return ref.read(streakRepositoryProvider).getStreak();
  }

  Future<void> recordSession() async {
    final repo = ref.read(streakRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repo.recordStudySession);
  }
}
