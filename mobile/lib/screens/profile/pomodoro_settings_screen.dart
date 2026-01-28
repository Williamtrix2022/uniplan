// ============================================
// CONFIGURACIÓN DE POMODORO
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_button.dart';

class PomodoroSettingsScreen extends StatefulWidget {
  const PomodoroSettingsScreen({super.key});

  @override
  State<PomodoroSettingsScreen> createState() => _PomodoroSettingsScreenState();
}

class _PomodoroSettingsScreenState extends State<PomodoroSettingsScreen> {
  int workDuration = 25;
  int shortBreak = 5;
  int longBreak = 15;
  int cyclesBeforeLongBreak = 4;
  bool autoStartBreaks = true;
  bool autoStartPomodoros = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Configuración Pomodoro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiempos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),

            // Tiempo de trabajo
            _buildTimeSetting(
              title: 'Tiempo de trabajo',
              value: workDuration,
              min: 15,
              max: 60,
              onChanged: (value) {
                setState(() => workDuration = value.round());
              },
            ),

            const SizedBox(height: 20),

            // Descanso corto
            _buildTimeSetting(
              title: 'Descanso corto',
              value: shortBreak,
              min: 3,
              max: 15,
              onChanged: (value) {
                setState(() => shortBreak = value.round());
              },
            ),

            const SizedBox(height: 20),

            // Descanso largo
            _buildTimeSetting(
              title: 'Descanso largo',
              value: longBreak,
              min: 10,
              max: 30,
              onChanged: (value) {
                setState(() => longBreak = value.round());
              },
            ),

            const SizedBox(height: 20),

            // Ciclos antes de descanso largo
            _buildTimeSetting(
              title: 'Pomodoros antes de descanso largo',
              value: cyclesBeforeLongBreak,
              min: 2,
              max: 8,
              onChanged: (value) {
                setState(() => cyclesBeforeLongBreak = value.round());
              },
            ),

            const SizedBox(height: 32),

            const Text(
              'Automatización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 16),

            // Auto-iniciar descansos
            _buildSwitchSetting(
              title: 'Iniciar descansos automáticamente',
              subtitle: 'Los descansos empezarán sin intervención',
              value: autoStartBreaks,
              onChanged: (value) {
                setState(() => autoStartBreaks = value);
              },
            ),

            const SizedBox(height: 12),

            // Auto-iniciar pomodoros
            _buildSwitchSetting(
              title: 'Iniciar pomodoros automáticamente',
              subtitle: 'El siguiente pomodoro empezará tras el descanso',
              value: autoStartPomodoros,
              onChanged: (value) {
                setState(() => autoStartPomodoros = value);
              },
            ),

            const SizedBox(height: 32),

            // Botón guardar
            CustomButton(
              text: 'Guardar configuración',
              onPressed: () {
                // TODO: Guardar en SharedPreferences o backend
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración guardada'),
                    backgroundColor: AppTheme.success,
                  ),
                );
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 12),

            // Restaurar valores por defecto
            CustomButton(
              text: 'Restaurar valores por defecto',
              onPressed: () {
                setState(() {
                  workDuration = 25;
                  shortBreak = 5;
                  longBreak = 15;
                  cyclesBeforeLongBreak = 4;
                  autoStartBreaks = true;
                  autoStartPomodoros = false;
                });
              },
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSetting({
    required String title,
    required int value,
    required int min,
    required int max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value min',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryGreen,
            inactiveTrackColor: AppTheme.lightGreen,
            thumbColor: AppTheme.primaryGreen,
            overlayColor: AppTheme.primaryGreen.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}