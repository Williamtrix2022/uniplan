// ============================================
// WIDGET: AVATAR CIRCULAR DE USUARIO REUTILIZABLE
// ============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Avatar circular con la inicial del nombre de usuario, opcionalmente
/// interactivo. Es la única implementación del avatar en la app: la usan los
/// headers de home, tareas, calendario y notas, y también las dos variantes
/// del perfil (la miniatura del AppBar y el avatar grande con borde y sombra
/// de la tarjeta de identidad).
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  /// Inicial a mostrar cuando `name` llega vacío. Los headers prefieren dejar
  /// el círculo liso mientras carga el nombre, pero la tarjeta de identidad
  /// del perfil necesita un marcador de posición para no verse rota.
  final String? fallbackInitial;

  /// Borde y sombra opcionales. Solo el avatar grande del perfil los usa, para
  /// despegarse del fondo de la tarjeta.
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.fallbackInitial,
    this.borderColor,
    this.borderWidth = 0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : (fallbackInitial ?? '');

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryGreen,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: boxShadow,
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
