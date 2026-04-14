import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/local_notifications_service.dart';

class StudyReminderSettings {
  const StudyReminderSettings({
    required this.isEnabled,
    required this.time,
    required this.permissionGranted,
  });

  final bool isEnabled;
  final TimeOfDay time;
  final bool permissionGranted;

  StudyReminderSettings copyWith({
    bool? isEnabled,
    TimeOfDay? time,
    bool? permissionGranted,
  }) {
    return StudyReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      time: time ?? this.time,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

final studyReminderProvider =
    AsyncNotifierProvider<StudyReminderNotifier, StudyReminderSettings>(
        StudyReminderNotifier.new);

class StudyReminderNotifier extends AsyncNotifier<StudyReminderSettings> {
  static const _enabledKey = 'study_reminder_enabled';
  static const _hourKey = 'study_reminder_hour';
  static const _minuteKey = 'study_reminder_minute';

  SharedPreferences? _prefs;

  @override
  Future<StudyReminderSettings> build() async {
    _prefs = await SharedPreferences.getInstance();

    final isEnabled = _prefs?.getBool(_enabledKey) ?? false;
    final hour = _prefs?.getInt(_hourKey) ?? 20;
    final minute = _prefs?.getInt(_minuteKey) ?? 0;

    return StudyReminderSettings(
      isEnabled: isEnabled,
      time: TimeOfDay(hour: hour, minute: minute),
      permissionGranted: false,
    );
  }

  Future<bool> requestPermissions() async {
    final current = await future;
    final granted =
        await LocalNotificationsService.instance.requestPermissions();

    state = AsyncValue.data(
      current.copyWith(permissionGranted: granted),
    );

    return granted;
  }

  Future<void> setEnabled(bool enabled) async {
    final current = await future;

    if (enabled) {
      final granted = await requestPermissions();
      if (!granted) {
        state = AsyncValue.data(
          current.copyWith(isEnabled: false, permissionGranted: false),
        );
        return;
      }

      await LocalNotificationsService.instance.scheduleDailyReminder(
        time: current.time,
      );
    } else {
      await LocalNotificationsService.instance.cancelDailyReminder();
    }

    await _prefs?.setBool(_enabledKey, enabled);

    state = AsyncValue.data(
      current.copyWith(
        isEnabled: enabled,
        permissionGranted: enabled ? true : current.permissionGranted,
      ),
    );
  }

  Future<void> setTime(TimeOfDay time) async {
    final current = await future;

    await _prefs?.setInt(_hourKey, time.hour);
    await _prefs?.setInt(_minuteKey, time.minute);

    if (current.isEnabled) {
      await LocalNotificationsService.instance.scheduleDailyReminder(
        time: time,
      );
    }

    state = AsyncValue.data(current.copyWith(time: time));
  }

  Future<void> sendTestNotification() async {
    final current = await future;
    final granted = current.permissionGranted || await requestPermissions();
    if (!granted) return;

    await LocalNotificationsService.instance.showTestNotification();
  }
}
