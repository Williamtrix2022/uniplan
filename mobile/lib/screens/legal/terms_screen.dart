// ============================================
// TÉRMINOS Y CONDICIONES / POLÍTICA DE DATOS
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Versión del documento de términos. Debe coincidir con la cadena que el
/// backend guarda en `estudiantes.version_terminos_aceptados` al registrar
/// una cuenta (ver `backend/src/models/Student.js`).
const String kTerminosVersion = '1.0';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uniplan · Términos y Condiciones de Uso',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versión $kTerminosVersion · Universidad de Córdoba',
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
              const SizedBox(height: 24),
              const _TermsSection(
                title: '1. Qué es Uniplan',
                body:
                    'Uniplan es una aplicación de organización académica que te permite '
                    'gestionar materias, tareas, horarios, calificaciones y sesiones de '
                    'estudio (Pomodoro). Al crear una cuenta aceptás estos términos y la '
                    'política de tratamiento de datos descrita a continuación.',
              ),
              const _TermsSection(
                title: '2. Datos que recolectamos',
                body:
                    '• Datos de registro: nombre, correo electrónico, contraseña (cifrada) '
                    'y universidad.\n'
                    '• Datos académicos que vos mismo ingresás: materias, tareas, eventos de '
                    'calendario, calificaciones y sesiones de Pomodoro.\n'
                    '• Datos técnicos mínimos para el funcionamiento del servicio (tokens de '
                    'sesión, fecha de registro, estado de la cuenta).',
              ),
              const _TermsSection(
                title: '3. Para qué usamos tus datos',
                body:
                    'Usamos tus datos exclusivamente para operar la aplicación: mostrar tu '
                    'información académica, calcular tus estadísticas de progreso, enviarte '
                    'notificaciones que vos configurás, y para comunicarte cambios '
                    'importantes de tu cuenta (por ejemplo, confirmaciones de registro o '
                    'recuperación de contraseña). No vendemos ni compartimos tus datos con '
                    'terceros con fines comerciales.',
              ),
              const _TermsSection(
                title: '4. Tus derechos (Ley 1581 de 2012, Colombia)',
                body:
                    'Como titular de tus datos personales, tenés derecho a:\n'
                    '• Conocer, actualizar y rectificar tu información.\n'
                    '• Solicitar prueba de la autorización otorgada para el tratamiento de '
                    'tus datos.\n'
                    '• Solicitar la eliminación de tus datos cuando no exista un deber legal '
                    'u obligación contractual que lo impida.\n'
                    '• Revocar la autorización y/o solicitar la supresión del dato, siempre '
                    'que no exista un deber legal que impida su eliminación.\n'
                    '• Acceder de forma gratuita a tus datos personales que hayan sido objeto '
                    'de tratamiento.',
              ),
              const _TermsSection(
                title: '5. Cómo ejercer tus derechos',
                body:
                    'Podés solicitar acceso, corrección o eliminación de tus datos escribiendo '
                    'al correo de soporte del proyecto, indicando el correo con el que te '
                    'registraste en Uniplan. Responderemos tu solicitud dentro de los plazos '
                    'establecidos por la normativa vigente.',
              ),
              const _TermsSection(
                title: '6. Seguridad',
                body:
                    'Tu contraseña se almacena cifrada (nunca en texto plano). El acceso a la '
                    'aplicación se protege con tokens de sesión con expiración y rotación. Si '
                    'detectás un uso no autorizado de tu cuenta, cambiá tu contraseña '
                    'inmediatamente desde Perfil.',
              ),
              const _TermsSection(
                title: '7. Cambios a estos términos',
                body:
                    'Si estos términos cambian de forma sustancial, te lo notificaremos dentro '
                    'de la aplicación y se te podrá solicitar aceptar la nueva versión. La '
                    'fecha y versión que aceptaste quedan registradas en tu cuenta.',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
