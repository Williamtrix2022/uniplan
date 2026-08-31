// ============================================
// TESTS: LÓGICA PURA DE PROGRAMACIÓN DE RECORDATORIOS
// ============================================
//
// `now` de referencia en la mayoría de los casos: miércoles 2026-07-15
// 10:00 (verificado: DateTime(2026, 7, 15).weekday == DateTime.wednesday).

import 'package:flutter_test/flutter_test.dart';
import 'package:uniplan/services/notification_scheduler.dart';

void main() {
  group('computeReminderTime', () {
    final now = DateTime(2026, 7, 15, 10, 0);

    test('returns reminder time when it is in the future and no quiet hours',
        () {
      final target = DateTime(2026, 7, 15, 12, 0);
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 60,
        now: now,
      );
      expect(result, DateTime(2026, 7, 15, 11, 0));
    });

    test('returns null when reminder instant equals now exactly', () {
      final target = DateTime(2026, 7, 15, 11, 0);
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 60,
        now: now,
      );
      expect(result, isNull);
    });

    test('returns null when the reminder is already in the past', () {
      final target = DateTime(2026, 7, 14, 9, 0); // ayer
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 60,
        now: now,
      );
      expect(result, isNull);
    });

    test('returns exact target when minutesBefore is 0', () {
      final target = DateTime(2026, 7, 15, 12, 0);
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 0,
        now: now,
      );
      expect(result, DateTime(2026, 7, 15, 12, 0));
    });

    group('quiet hours — non-wrapping window (13:00–14:00)', () {
      test('pushes reminder inside the window to the end of the window', () {
        final target = DateTime(2026, 7, 15, 14, 30);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 13:30
          now: now,
          quietHoursStart: '13:00',
          quietHoursEnd: '14:00',
        );
        expect(result, DateTime(2026, 7, 15, 14, 0));
      });

      test('start boundary is inclusive — reminder exactly at start is pushed',
          () {
        final target = DateTime(2026, 7, 15, 14, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 13:00
          now: now,
          quietHoursStart: '13:00',
          quietHoursEnd: '14:00',
        );
        expect(result, DateTime(2026, 7, 15, 14, 0));
      });

      test('end boundary is exclusive — reminder exactly at end is NOT pushed',
          () {
        final target = DateTime(2026, 7, 15, 15, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 14:00
          now: now,
          quietHoursStart: '13:00',
          quietHoursEnd: '14:00',
        );
        expect(result, DateTime(2026, 7, 15, 14, 0));
      });
    });

    group('quiet hours — wrapping window across midnight (22:00–07:00)', () {
      test('reminder late at night (before midnight) is pushed to next day '
          'at the end time', () {
        final nowLate = DateTime(2026, 7, 15, 10, 0);
        final target = DateTime(2026, 7, 16, 0, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 2026-07-15 23:00
          now: nowLate,
          quietHoursStart: '22:00',
          quietHoursEnd: '07:00',
        );
        expect(result, DateTime(2026, 7, 16, 7, 0));
      });

      test('reminder early in the morning (after midnight) is pushed to the '
          'same day at the end time', () {
        final nowEarly = DateTime(2026, 7, 15, 4, 0);
        final target = DateTime(2026, 7, 15, 6, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 2026-07-15 05:00
          now: nowEarly,
          quietHoursStart: '22:00',
          quietHoursEnd: '07:00',
        );
        expect(result, DateTime(2026, 7, 15, 7, 0));
      });

      test('start boundary is inclusive — reminder exactly at 22:00 is '
          'pushed to next day at end time', () {
        final target = DateTime(2026, 7, 15, 23, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 22:00
          now: now,
          quietHoursStart: '22:00',
          quietHoursEnd: '07:00',
        );
        expect(result, DateTime(2026, 7, 16, 7, 0));
      });

      test('end boundary is exclusive — reminder exactly at 07:00 is NOT '
          'pushed', () {
        final nowEarly = DateTime(2026, 7, 15, 4, 0);
        final target = DateTime(2026, 7, 15, 8, 0);
        final result = computeReminderTime(
          targetDateTime: target,
          minutesBefore: 60, // reminder = 07:00
          now: nowEarly,
          quietHoursStart: '22:00',
          quietHoursEnd: '07:00',
        );
        expect(result, DateTime(2026, 7, 15, 7, 0));
      });
    });

    test('quiet hours are ignored when only one bound is provided', () {
      final target = DateTime(2026, 7, 15, 14, 30);
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 60, // reminder = 13:30, would fall inside 13:00-14:00
        now: now,
        quietHoursStart: '13:00',
        quietHoursEnd: null,
      );
      expect(result, DateTime(2026, 7, 15, 13, 30));
    });

    test('degenerate quiet window (start == end) has no effect', () {
      final target = DateTime(2026, 7, 15, 12, 0);
      final result = computeReminderTime(
        targetDateTime: target,
        minutesBefore: 60, // reminder = 11:00
        now: now,
        quietHoursStart: '11:00',
        quietHoursEnd: '11:00',
      );
      expect(result, DateTime(2026, 7, 15, 11, 0));
    });
  });

  group('nextWeeklyOccurrence', () {
    // 2026-07-15 is a Wednesday ('miercoles'), 10:00.
    final now = DateTime(2026, 7, 15, 10, 0);

    test('today, time still ahead → returns today at that time', () {
      final result = nextWeeklyOccurrence(
        dia: 'miercoles',
        horaInicio: '14:00:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 15, 14, 0));
    });

    test('today, time already passed → returns next week', () {
      final result = nextWeeklyOccurrence(
        dia: 'miercoles',
        horaInicio: '08:00:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 22, 8, 0));
    });

    test('today, time exactly now → returns next week (not-after is pushed)',
        () {
      final result = nextWeeklyOccurrence(
        dia: 'miercoles',
        horaInicio: '10:00:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 22, 10, 0));
    });

    test('later weekday this week → returns this week', () {
      final result = nextWeeklyOccurrence(
        dia: 'viernes',
        horaInicio: '09:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 17, 9, 0));
    });

    test('earlier weekday this week (already happened) → returns next week',
        () {
      final result = nextWeeklyOccurrence(
        dia: 'lunes',
        horaInicio: '09:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 20, 9, 0));
    });

    test('unknown weekday string → returns null', () {
      final result = nextWeeklyOccurrence(
        dia: 'notaday',
        horaInicio: '09:00',
        now: now,
      );
      expect(result, isNull);
    });

    test('weekday string is case-insensitive', () {
      final result = nextWeeklyOccurrence(
        dia: 'VIERNES',
        horaInicio: '09:00',
        now: now,
      );
      expect(result, DateTime(2026, 7, 17, 9, 0));
    });

    test('malformed horaInicio (no colon) → returns null', () {
      final result = nextWeeklyOccurrence(
        dia: 'viernes',
        horaInicio: '0900',
        now: now,
      );
      expect(result, isNull);
    });

    test('non-numeric horaInicio → returns null', () {
      final result = nextWeeklyOccurrence(
        dia: 'viernes',
        horaInicio: 'ab:cd',
        now: now,
      );
      expect(result, isNull);
    });
  });

  group('nextWeeklyOccurrences', () {
    // 2026-07-15 is a Wednesday ('miercoles'), 10:00.
    final now = DateTime(2026, 7, 15, 10, 0);

    test('returns 4 dates by default, 7 days apart, starting at the base '
        'occurrence', () {
      final result = nextWeeklyOccurrences(
        dia: 'miercoles',
        horaInicio: '14:00:00',
        now: now,
      );
      expect(result, [
        DateTime(2026, 7, 15, 14, 0),
        DateTime(2026, 7, 22, 14, 0),
        DateTime(2026, 7, 29, 14, 0),
        DateTime(2026, 8, 5, 14, 0),
      ]);
    });

    test('base occurrence already passed today → sequence starts next week',
        () {
      final result = nextWeeklyOccurrences(
        dia: 'miercoles',
        horaInicio: '08:00:00',
        now: now,
      );
      expect(result, [
        DateTime(2026, 7, 22, 8, 0),
        DateTime(2026, 7, 29, 8, 0),
        DateTime(2026, 8, 5, 8, 0),
        DateTime(2026, 8, 12, 8, 0),
      ]);
    });

    test('respects a custom count', () {
      final result = nextWeeklyOccurrences(
        dia: 'miercoles',
        horaInicio: '14:00:00',
        now: now,
        count: 2,
      );
      expect(result, [
        DateTime(2026, 7, 15, 14, 0),
        DateTime(2026, 7, 22, 14, 0),
      ]);
    });

    test('unknown weekday string → returns an empty list (same invalid-input '
        'contract as nextWeeklyOccurrence)', () {
      final result = nextWeeklyOccurrences(
        dia: 'notaday',
        horaInicio: '09:00',
        now: now,
      );
      expect(result, isEmpty);
    });

    test('malformed horaInicio → returns an empty list', () {
      final result = nextWeeklyOccurrences(
        dia: 'viernes',
        horaInicio: '0900',
        now: now,
      );
      expect(result, isEmpty);
    });
  });
}
