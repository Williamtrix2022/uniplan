// ============================================
// AYUDA - FAQ Y REPORTE DE PROBLEMAS
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/report_service.dart';
import '../../widgets/common/custom_button.dart';
import '../onboarding/onboarding_screen.dart';

class _Faq {
  final String question;
  final String answer;

  const _Faq({required this.question, required this.answer});
}

class _FaqSection {
  final String title;
  final IconData icon;
  final List<_Faq> items;

  const _FaqSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

const _faqSections = [
  _FaqSection(
    title: 'Materias y tareas',
    icon: Icons.menu_book_rounded,
    items: [
      _Faq(
        question: '¿Cómo agrego una materia nueva?',
        answer:
            'Ve a Materias y toca el botón "+". Puedes asignarle un color y '
            'un profesor para identificarla fácilmente en el calendario.',
      ),
      _Faq(
        question: '¿Cómo marco una tarea como completada?',
        answer:
            'Desde la lista de tareas, toca el check junto a la tarea. '
            'Las estadísticas de Inicio se actualizan automáticamente.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Horario y calendario',
    icon: Icons.calendar_month_rounded,
    items: [
      _Faq(
        question: '¿Cómo agrego una clase a mi horario?',
        answer:
            'En Calendario, cambia a la pestaña "Horario" y toca "+" para '
            'crear un bloque de clase con día, hora y materia.',
      ),
      _Faq(
        question: '¿Puedo ver eventos puntuales además del horario fijo?',
        answer:
            'Sí, cambia a la pestaña "Eventos" para crear parciales, '
            'entregas u otros eventos de una sola fecha.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Pomodoro',
    icon: Icons.timer_rounded,
    items: [
      _Faq(
        question: '¿Cómo funciona la racha de estudio?',
        answer:
            'Cuenta los días consecutivos en los que completaste al menos '
            'un ciclo Pomodoro. Si un día no estudias, la racha se reinicia.',
      ),
      _Faq(
        question: '¿Puedo cambiar la duración de los ciclos?',
        answer:
            'Sí, en Perfil → Preferencias de Pomodoro puedes ajustar los '
            'minutos de trabajo y descanso.',
      ),
    ],
  ),
  _FaqSection(
    title: 'Calificaciones',
    icon: Icons.grade_rounded,
    items: [
      _Faq(
        question: '¿Cómo registro una nota?',
        answer:
            'Entra a la materia desde Materias y agrega la calificación con '
            'su porcentaje. Uniplan calcula el acumulado automáticamente.',
      ),
    ],
  ),
];

const _moduloOptions = [
  ('tareas', 'Tareas'),
  ('materias', 'Materias'),
  ('horario', 'Horario'),
  ('calendario', 'Calendario'),
  ('pomodoro', 'Pomodoro'),
  ('calificaciones', 'Calificaciones'),
  ('notificaciones', 'Notificaciones'),
  ('perfil', 'Perfil'),
  ('otro', 'Otro'),
];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _reportService = ReportService();

  String _selectedModulo = _moduloOptions.first.$1;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await _reportService.sendReport(
        modulo: _selectedModulo,
        mensaje: _messageController.text.trim(),
      );

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Gracias! Tu reporte fue enviado.'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.white,
      appBar: AppBar(title: const Text('Ayuda')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guía rápida',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Quieres volver a ver la introducción a Uniplan?',
                style: TextStyle(fontSize: 14, color: context.colors.greyText),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Ver introducción'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primaryGreen,
                  side: BorderSide(color: context.colors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Preguntas frecuentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              ..._faqSections.map((section) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(section.icon, color: context.colors.primaryGreen),
                        title: Text(
                          section.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.darkText,
                          ),
                        ),
                        children: section.items
                            .map((faq) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        faq.question,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: context.colors.darkText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        faq.answer,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.colors.greyText,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  )),

              const SizedBox(height: 24),

              Text(
                'Reportar un problema o sugerencia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¿Encontraste un error o tienes una idea para mejorar '
                'Uniplan? Cuéntanos.',
                style: TextStyle(fontSize: 14, color: context.colors.greyText),
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Módulo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedModulo,
                      isExpanded: true,
                      items: _moduloOptions
                          .map((option) => DropdownMenuItem(
                                value: option.$1,
                                child: Text(option.$2),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedModulo = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Mensaje',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe el problema o tu sugerencia...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Cuéntanos un poco más (mínimo 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Enviar reporte',
                      onPressed: _sendReport,
                      isLoading: _isSending,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
