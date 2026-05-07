import 'package:json_annotation/json_annotation.dart';

part 'streak_model.g.dart';

@JsonSerializable()
class StreakModel {
  const StreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    this.totalStudyDays = 0,
  });

  final int currentStreak;
  final int longestStreak;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? lastStudyDate;
  final int totalStudyDays;

  bool get isActiveToday {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(
      lastStudyDate!.year,
      lastStudyDate!.month,
      lastStudyDate!.day,
    );
    return today == last;
  }

  bool get isAtRisk {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(
      lastStudyDate!.year,
      lastStudyDate!.month,
      lastStudyDate!.day,
    );
    return today.difference(last).inDays == 1 && currentStreak > 0;
  }

  StreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudyDate,
    int? totalStudyDays,
  }) {
    return StreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      totalStudyDays: totalStudyDays ?? this.totalStudyDays,
    );
  }

  factory StreakModel.fromJson(Map<String, dynamic> json) =>
      _$StreakModelFromJson(json);
  Map<String, dynamic> toJson() => _$StreakModelToJson(this);

  static DateTime? _dateFromJson(String? value) =>
      value != null ? DateTime.parse(value) : null;
  static String? _dateToJson(DateTime? value) => value?.toIso8601String();
}
