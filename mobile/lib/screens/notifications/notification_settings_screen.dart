// ============================================
// PANTALLA: CONFIGURACIÓN DE NOTIFICACIONES
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/notification_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/local_notification_service.dart';
import '../../widgets/common/custom_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPreferences _draft;
  bool _loadedDraft = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _draft = NotificationPreferences.defaults();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // El permiso de notificaciones se pide en un momento con contexto
      // claro para el usuario (aquí, no a ciegas en el arranque de la app).
      await LocalNotificationService.requestPermission();
      if (!mounted) return;
      await context.read<NotificationProvider>().initialize();
    });
  }

  void _syncDraftFromProvider(NotificationPreferences preferences) {
    if (_loadedDraft) return;
    _draft = preferences;
    _loadedDraft = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    _syncDraftFromProvider(provider.preferences);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Notificaciones'),
      ),
      body: provider.isPreferencesLoading && !provider.isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('TIPOS DE NOTIFICACIÓN'),
                  const SizedBox(height: 12),
                  _buildTypesSection(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('TIEMPO DE ANTICIPACIÓN'),
                  const SizedBox(height: 12),
                  _buildLeadTimeSection(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('HORARIO DE SILENCIO'),
                  const SizedBox(height: 12),
                  _buildQuietHoursSection(),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Guardar cambios',
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTypesSection() {
    return _card([
      _buildSwitchItem(
        icon: Icons.assignment_outlined,
        title: 'Tareas',
        subtitle: 'Avisos antes de la fecha de entrega',
        value: _draft.notifTareas,
        onChanged: (v) => setState(() => _draft = _draft.copyWith(notifTareas: v)),
      ),
      const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
      _buildSwitchItem(
        icon: Icons.school_outlined,
        title: 'Clases',
        subtitle: 'Avisos antes de que inicie una clase',
        value: _draft.notifClases,
        onChanged: (v) => setState(() => _draft = _draft.copyWith(notifClases: v)),
      ),
      const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
      _buildSwitchItem(
        icon: Icons.notifications_outlined,
        title: 'Generales',
        subtitle: 'Anuncios y avisos del sistema',
        value: _draft.notifGenerales,
        onChanged: (v) =>
            setState(() => _draft = _draft.copyWith(notifGenerales: v)),
      ),
      const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
      _buildSwitchItem(
        icon: Icons.volume_up_outlined,
        title: 'Sonido',
        subtitle: 'Reproducir sonido al recibir un aviso',
        value: _draft.sonidoActivo,
        onChanged: (v) => setState(() => _draft = _draft.copyWith(sonidoActivo: v)),
      ),
    ]);
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // El track queda en un verde suave (solo el thumb usa el verde
            // saturado de marca) para que la fila no "explote" en verde
            // cuando varios switches están activos a la vez.
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppTheme.primaryGreen
                  : null,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppTheme.lightGreen
                  : AppTheme.surfaceContainer,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.transparent
                  : AppTheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }

  static const List<int> _leadTimePresets = [10, 15, 30, 60, 1440];

  String _formatLeadTime(int minutes) {
    if (minutes == 60) return '1 h';
    if (minutes == 1440) return '1 día';
    return '$minutes min';
  }

  Widget _buildLeadTimeSection() {
    return _card([
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Antes de una tarea',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildLeadTimeChips(
          value: _draft.minutosAntesTarea,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(minutosAntesTarea: v)),
        ),
      ),
      const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          'Antes de una clase',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: _buildLeadTimeChips(
          value: _draft.minutosAntesClase,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(minutosAntesClase: v)),
        ),
      ),
    ]);
  }

  Widget _buildLeadTimeChips({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final isPreset = _leadTimePresets.contains(value);

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onSelected,
    }) {
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
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
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final preset in _leadTimePresets)
          chip(
            label: _formatLeadTime(preset),
            selected: value == preset,
            onSelected: () => onChanged(preset),
          ),
        chip(
          label: isPreset ? 'Personalizado' : '${_formatLeadTime(value)} (personalizado)',
          selected: !isPreset,
          onSelected: () => _pickCustomLeadTime(current: value, onChanged: onChanged),
        ),
      ],
    );
  }

  Future<void> _pickCustomLeadTime({
    required int current,
    required ValueChanged<int> onChanged,
  }) async {
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Minutos personalizados'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'min'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(int.tryParse(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result >= 0) {
      onChanged(result);
    }
  }

  Widget _buildQuietHoursSection() {
    final activo = _draft.tieneHorarioSilencio;

    return _card([
      _buildSwitchItem(
        icon: Icons.bedtime_outlined,
        title: 'Activar horario de silencio',
        subtitle: 'No recibirás avisos durante este rango',
        value: activo,
        onChanged: (v) {
          setState(() {
            _draft = v
                ? _draft.copyWith(
                    horaSilencioInicio: _draft.horaSilencioInicio ?? '22:00',
                    horaSilencioFin: _draft.horaSilencioFin ?? '07:00',
                  )
                : _draft.copyWith(clearHoraSilencio: true);
          });
        },
      ),
      if (activo) ...[
        const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
        _buildTimePickerItem(
          label: 'Desde',
          value: _draft.horaSilencioInicio!,
          onTap: () => _pickQuietHour(isStart: true),
        ),
        const Divider(height: 1, color: AppTheme.surfaceContainerHighest),
        _buildTimePickerItem(
          label: 'Hasta',
          value: _draft.horaSilencioFin!,
          onTap: () => _pickQuietHour(isStart: false),
        ),
      ],
    ]);
  }

  Widget _buildTimePickerItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    color: AppTheme.onSurfaceVariant, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickQuietHour({required bool isStart}) async {
    final current = isStart ? _draft.horaSilencioInicio : _draft.horaSilencioFin;
    final parts = (current ?? '22:00').split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      _draft = isStart
          ? _draft.copyWith(horaSilencioInicio: formatted)
          : _draft.copyWith(horaSilencioFin: formatted);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final tasks = context.read<TaskProvider>().tasks;
      final schedules = context.read<ScheduleProvider>().schedules;

      await context.read<NotificationProvider>().updatePreferences(
            _draft,
            tasks: tasks,
            schedules: schedules,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferencias guardadas'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
