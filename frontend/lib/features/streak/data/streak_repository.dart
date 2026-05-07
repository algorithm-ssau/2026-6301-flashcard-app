import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/streak_model.dart';

class StreakRepository {
  static const _key = 'user_streak';

  Future<StreakModel> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const StreakModel();
    return StreakModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<StreakModel> recordStudySession() async {
    final streak = await getStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (streak.isActiveToday) return streak;

    int newCurrent;
    if (streak.lastStudyDate == null) {
      newCurrent = 1;
    } else {
      final last = DateTime(
        streak.lastStudyDate!.year,
        streak.lastStudyDate!.month,
        streak.lastStudyDate!.day,
      );
      final diff = today.difference(last).inDays;
      newCurrent = diff == 1 ? streak.currentStreak + 1 : 1;
    }

    final updated = streak.copyWith(
      currentStreak: newCurrent,
      longestStreak: newCurrent > streak.longestStreak
          ? newCurrent
          : streak.longestStreak,
      lastStudyDate: now,
      totalStudyDays: streak.totalStudyDays + 1,
    );

    await _save(updated);
    return updated;
  }

  Future<void> _save(StreakModel streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(streak.toJson()));
  }
}
