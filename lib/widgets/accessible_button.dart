import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Botão acessível com suporte a leitores de tela
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final String? hint;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();

    final effectiveBackgroundColor = accessibilityService.getHighContrastColor(
      backgroundColor ?? Theme.of(context).primaryColor,
    );
    final effectiveTextColor = accessibilityService.getHighContrastColor(
      textColor ?? Colors.white,
    );

    Widget button = SizedBox(
      width: width,
      height: height ?? accessibilityService.textFieldHeight,
        child: ElevatedButton(
        onPressed: () {
          accessibilityService.lightImpact();
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          textStyle: TextStyle(
            fontSize: accessibilityService.buttonTextSize,
            fontWeight: FontWeight.bold,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: accessibilityService.defaultSpacing,
            vertical: accessibilityService.smallSpacing,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: accessibilityService.iconSize),
              SizedBox(width: accessibilityService.smallSpacing),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Adicionar Semantics para leitores de tela
    return Semantics(
      label: semanticLabel ?? label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: button,
    );
  }
}

/// Botão de ícone acessível
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  final double? size;
  final String? hint;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.size,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    // Não atualizar mediaQuery - pode travar no web

    final effectiveColor = accessibilityService.getHighContrastColor(
      color ?? Theme.of(context).iconTheme.color ?? Colors.black,
    );

    Widget iconButton = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: effectiveColor,
      iconSize: size ?? accessibilityService.iconSize,
      tooltip: label,
    );

    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: iconButton,
    );
  }
}

