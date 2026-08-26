// ============================================
// MODELO DE PREFERENCIAS DE POMODORO
// ============================================
//
// A diferencia de `NotificationPreferences`, esto no tiene contraparte en el
// backend (no hay tabla ni endpoint de configuración de Pomodoro) — vive
// solo localmente en el dispositivo vía `PomodoroPreferencesService`.

class PomodoroPreferences {
  final int workDuration; // minutos
  final int shortBreak; // minutos
  final int longBreak; // minutos
  final int cyclesBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartPomodoros;

  const PomodoroPreferences({
    this.workDuration = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.cyclesBeforeLongBreak = 4,
    this.autoStartBreaks = true,
    this.autoStartPomodoros = false,
  });

  factory PomodoroPreferences.defaults() => const PomodoroPreferences();

  factory PomodoroPreferences.fromJson(Map<String, dynamic> json) {
    return PomodoroPreferences(
      workDuration: json['workDuration'] ?? 25,
      shortBreak: json['shortBreak'] ?? 5,
      longBreak: json['longBreak'] ?? 15,
      cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] ?? 4,
      autoStartBreaks: json['autoStartBreaks'] ?? true,
      autoStartPomodoros: json['autoStartPomodoros'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workDuration': workDuration,
      'shortBreak': shortBreak,
      'longBreak': longBreak,
      'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
      'autoStartBreaks': autoStartBreaks,
      'autoStartPomodoros': autoStartPomodoros,
    };
  }

  PomodoroPreferences copyWith({
    int? workDuration,
    int? shortBreak,
    int? longBreak,
    int? cyclesBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
  }) {
    return PomodoroPreferences(
      workDuration: workDuration ?? this.workDuration,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
    );
  }
}
