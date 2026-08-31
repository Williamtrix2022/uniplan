// ============================================
// CONFIGURACIÓN DE POMODORO
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/pomodoro_preferences.dart';
import '../../services/pomodoro_preferences_service.dart';
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

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await PomodoroPreferencesService.load();
    if (!mounted) return;
    setState(() {
      workDuration = prefs.workDuration;
      shortBreak = prefs.shortBreak;
      longBreak = prefs.longBreak;
      cyclesBeforeLongBreak = prefs.cyclesBeforeLongBreak;
      autoStartBreaks = prefs.autoStartBreaks;
      autoStartPomodoros = prefs.autoStartPomodoros;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    await PomodoroPreferencesService.save(PomodoroPreferences(
      workDuration: workDuration,
      shortBreak: shortBreak,
      longBreak: longBreak,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak,
      autoStartBreaks: autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros,
    ));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Configuración Pomodoro'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : SingleChildScrollView(
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
            const SizedBox(height: 4),
            const Text(
              'Elige un preset o ajústalo manualmente',
              style: TextStyle(fontSize: 13, color: AppTheme.greyText),
            ),
            const SizedBox(height: 12),
            _buildPresetChips(),
            const SizedBox(height: 20),

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
              step: 1,
              unit: '',
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
              isLoading: _isSaving,
              onPressed: _savePreferences,
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

  // Presets clásicos de Pomodoro: (trabajo, descanso corto).
  static const Map<String, (int, int)> _pomodoroPresets = {
    'Clásico': (25, 5),
    'Largo': (50, 10),
    'Corto': (15, 3),
  };

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _pomodoroPresets.entries.map((entry) {
        final selected =
            workDuration == entry.value.$1 && shortBreak == entry.value.$2;
        return ChoiceChip(
          label: Text(entry.key),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() {
            workDuration = entry.value.$1;
            shortBreak = entry.value.$2;
          }),
          selectedColor: AppTheme.lightGreen,
          backgroundColor: AppTheme.surfaceContainer,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primaryGreen : AppTheme.darkText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
            side: BorderSide(
              color: selected ? AppTheme.primaryGreen : AppTheme.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSetting({
    required String title,
    required int value,
    required int min,
    required int max,
    int step = 5,
    String unit = ' min',
    required ValueChanged<double> onChanged,
  }) {
    return Column(
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
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStepButton(
              icon: Icons.remove,
              onPressed: value > min
                  ? () => onChanged((value - step).clamp(min, max).toDouble())
                  : null,
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value$unit',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            _buildStepButton(
              icon: Icons.add,
              onPressed: value < max
                  ? () => onChanged((value + step).clamp(min, max).toDouble())
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.darkText),
        onPressed: onPressed,
      ),
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