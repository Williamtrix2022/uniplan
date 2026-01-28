// ============================================
// PANTALLA DE EDITAR PERFIL
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _careerController;
  late TextEditingController _universityController;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _careerController = TextEditingController();
    _universityController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _careerController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);

    try {
      final profile = await _authService.getProfile();
      final data = profile['data'];

      setState(() {
        _nameController.text = data['nombre'] ?? '';
        _careerController.text = data['carrera'] ?? '';
        _universityController.text = data['universidad'] ?? '';
      });
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      // TODO: Implementar actualización de perfil en el backend
      // Por ahora solo mostramos mensaje de éxito
      
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Avatar (placeholder)
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppTheme.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Nombre
                    CustomTextField(
                      label: 'Nombre completo',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Carrera
                    CustomTextField(
                      label: 'Carrera',
                      controller: _careerController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La carrera es obligatoria';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Universidad
                    CustomTextField(
                      label: 'Universidad',
                      controller: _universityController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La universidad es obligatoria';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botón guardar
                    CustomButton(
                      text: 'Guardar cambios',
                      onPressed: _saveProfile,
                      isLoading: isSaving,
                    ),

                    const SizedBox(height: 12),

                    // Botón cancelar
                    CustomButton(
                      text: 'Cancelar',
                      onPressed: () => Navigator.pop(context),
                      isOutlined: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}