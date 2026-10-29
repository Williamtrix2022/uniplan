// ============================================
// PANTALLA DE REGISTRO - POR PASOS
// ============================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../home/home_screen.dart';
import '../legal/terms_screen.dart';
import 'login_screen.dart';

const _universityOptions = [
  'Universidad de Córdoba',
  'Universidad de Antioquia',
  'Universidad Nacional de Colombia',
  'Universidad del Norte',
  'Universidad de los Andes',
  'Otra universidad',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _accountFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otherUniversityController = TextEditingController();
  final _authService = AuthService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  double _passwordStrength = 0;
  String? _selectedUniversity = _universityOptions.first;
  late final TapGestureRecognizer _termsRecognizer;

  static const _totalSteps = 2;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TermsScreen()),
        );
      };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otherUniversityController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 6) strength += 0.33;
    if (password.length >= 8) strength += 0.17;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength < 0.33) return AppTheme.error;
    if (_passwordStrength < 0.66) return AppTheme.warning;
    return AppTheme.success;
  }

  String _getStrengthLabel() {
    if (_passwordStrength < 0.33) return 'Débil';
    if (_passwordStrength < 0.66) return 'Media';
    return 'Fuerte';
  }

  String get _universityValue {
    if (_selectedUniversity == 'Otra universidad') {
      return _otherUniversityController.text.trim();
    }
    return _selectedUniversity ?? '';
  }

  void _goToProfileStep() {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() => _currentStep = 1);
  }

  void _goToAccountStep() {
    setState(() => _currentStep = 0);
  }

  // Si se llegó aquí desde el onboarding (Splash → Onboarding → Register,
  // todo con pushReplacement), no queda ninguna pantalla debajo en el stack:
  // un pop() dejaría el Navigator vacío (pantalla en negro).
  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_profileFormKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        university: _universityValue,
      );

      if (mounted) {
        // Ir directamente al home (ya que register también devuelve token)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isLoading = true);

    try {
      await _authService.loginWithGoogle(allowRegister: true);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStepIndicator() {
    final stepLabel = _currentStep == 0
        ? 'Paso 1 de $_totalSteps · Cuenta'
        : 'Paso 2 de $_totalSteps · Perfil académico';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stepLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_totalSteps, (index) {
            final isActiveOrDone = index <= _currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index == _totalSteps - 1 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: isActiveOrDone
                      ? AppTheme.primaryGreen
                      : AppTheme.borderGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAccountStep() {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Únete a Uniplan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu camino hacia una productividad brillante comienza aquí',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),

          const SizedBox(height: 32),

          // Nombre completo
          CustomTextField(
            label: 'Nombre completo',
            hintText: 'Ej. Sofía Rodríguez',
            controller: _nameController,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu nombre';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Email
          CustomTextField(
            label: 'Correo electrónico',
            hintText: 'hola@universidad.edu',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu correo';
              }
              if (!value.contains('@')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Contraseña
          CustomTextField(
            label: 'Contraseña',
            hintText: '••••••••',
            controller: _passwordController,
            obscureText: true,
            onChanged: _calculatePasswordStrength,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa una contraseña';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Indicador de fuerza de contraseña
          if (_passwordController.text.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: AppTheme.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStrengthColor(),
                    ),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Nivel de seguridad: ${_getStrengthLabel()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStrengthColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 4),

          // Botón Siguiente
          CustomButton(
            text: 'Siguiente',
            onPressed: _goToProfileStep,
          ),

          const SizedBox(height: 24),

          // Divisor
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: AppTheme.borderGrey,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O regístrate con',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppTheme.borderGrey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones de redes sociales
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  onPressed: _handleGoogleRegister,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SocialButton(
                  icon: Icons.apple,
                  label: 'Apple',
                  onPressed: () {
                    // TODO: Registro con Apple
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ¿Ya tienes cuenta?
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¿Ya tienes cuenta? ',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: _goToLogin,
                  child: const Text(
                    'Inicia sesión',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu perfil académico',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para terminar, cuéntanos en qué universidad estudias',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),

          const SizedBox(height: 32),

          // Universidad (lista de selección)
          const Text(
            'Universidad',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedUniversity,
            isExpanded: true,
            items: _universityOptions
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(
                        option,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedUniversity = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona tu universidad';
              }
              return null;
            },
          ),

          if (_selectedUniversity == 'Otra universidad') ...[
            const SizedBox(height: 20),
            CustomTextField(
              label: '¿Cuál universidad?',
              hintText: 'Escribe el nombre de tu universidad',
              controller: _otherUniversityController,
              validator: (value) {
                if (_selectedUniversity != 'Otra universidad') return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu universidad';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),

          // Términos y condiciones
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptedTerms = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkText,
                    ),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'Términos y Condiciones',
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: _termsRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones Atrás / Crear cuenta
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Atrás',
                  isOutlined: true,
                  onPressed: _isLoading ? null : _goToAccountStep,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Crear cuenta',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 0) {
              _goToLogin();
            } else {
              _goToAccountStep();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 0) _buildAccountStep() else _buildProfileStep(),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== BOTÓN DE RED SOCIAL ==========
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.darkText,
        side: const BorderSide(color: AppTheme.borderGrey),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }
}
