import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniplan/models/pomodoro_preferences.dart';
import 'package:uniplan/services/pomodoro_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PomodoroPreferencesService', () {
    test('load returns defaults when nothing was saved yet', () async {
      final prefs = await PomodoroPreferencesService.load();

      expect(prefs.workDuration, 25);
      expect(prefs.shortBreak, 5);
      expect(prefs.longBreak, 15);
      expect(prefs.cyclesBeforeLongBreak, 4);
      expect(prefs.autoStartBreaks, isTrue);
      expect(prefs.autoStartPomodoros, isFalse);
    });

    test('save then load round-trips every field, including presets/toggles',
        () async {
      const saved = PomodoroPreferences(
        workDuration: 50,
        shortBreak: 10,
        longBreak: 20,
        cyclesBeforeLongBreak: 6,
        autoStartBreaks: false,
        autoStartPomodoros: true,
      );

      await PomodoroPreferencesService.save(saved);
      final loaded = await PomodoroPreferencesService.load();

      expect(loaded.workDuration, 50);
      expect(loaded.shortBreak, 10);
      expect(loaded.longBreak, 20);
      expect(loaded.cyclesBeforeLongBreak, 6);
      expect(loaded.autoStartBreaks, isFalse);
      expect(loaded.autoStartPomodoros, isTrue);
    });

    test('load falls back to defaults when the stored value is corrupted',
        () async {
      SharedPreferences.setMockInitialValues({
        'pomodoro_preferences': 'not valid json{{{',
      });

      final prefs = await PomodoroPreferencesService.load();

      expect(prefs.workDuration, 25);
      expect(prefs.shortBreak, 5);
    });
  });
}
