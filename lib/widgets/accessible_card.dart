import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// Card acessível com suporte a leitores de tela
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? hint;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.hint,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    final mediaQuery = MediaQuery.of(context);
    // Não atualizar a cada build - pode travar no web
    // accessibilityService.updateFromMediaQuery(mediaQuery);

    final effectiveColor = accessibilityService.getHighContrastColor(
      color ?? Theme.of(context).cardColor,
    );

    Widget card = Card(
      margin: margin ?? EdgeInsets.all(accessibilityService.defaultSpacing),
      color: effectiveColor,
      elevation: elevation ?? 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? EdgeInsets.all(accessibilityService.defaultSpacing),
          child: child,
        ),
      ),
    );

    if (semanticLabel != null || onTap != null) {
      return Semantics(
        label: semanticLabel,
        hint: hint,
        button: onTap != null,
        child: card,
      );
    }

    return card;
  }
}

