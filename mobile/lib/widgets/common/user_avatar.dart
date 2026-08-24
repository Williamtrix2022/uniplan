// ============================================
// WIDGET: AVATAR CIRCULAR DE USUARIO REUTILIZABLE
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Avatar circular con la inicial del nombre de usuario, opcionalmente
/// interactivo. Unifica las implementaciones previamente duplicadas en
/// `tasks_screen.dart` y `profile_screen.dart`.
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '';

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryGreen,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: initial.isEmpty
            ? const SizedBox.shrink()
            : Text(
                initial,
                style: TextStyle(
                  color: foregroundColor ?? AppTheme.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}
