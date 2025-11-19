import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';

/// Campo de texto acessível com suporte completo a acessibilidade
class AccessibleTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AccessibleTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Não atualizar automaticamente - pode causar problemas de performance
    // _accessibilityService.updateFromMediaQuery(mediaQuery);

    final effectiveLabel = widget.semanticLabel ?? widget.label;
    final effectiveHint = widget.semanticHint ?? widget.hint;

    return Semantics(
      label: effectiveLabel,
      hint: effectiveHint,
      textField: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        onChanged: (value) {
          _accessibilityService.selectionClick();
          widget.onChanged?.call(value);
        },
        onTap: () {
          _accessibilityService.lightImpact();
          widget.onTap?.call();
        },
        inputFormatters: widget.inputFormatters,
        focusNode: widget.focusNode,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: _accessibilityService.bodyTextSize * mediaQuery.textScaleFactor,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  size: _accessibilityService.iconSize,
                )
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    size: _accessibilityService.iconSize,
                  ),
                  onPressed: () {
                    _accessibilityService.lightImpact();
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  tooltip: _obscureText ? 'Mostrar senha' : 'Ocultar senha',
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        size: _accessibilityService.iconSize,
                      ),
                      onPressed: () {
                        _accessibilityService.lightImpact();
                        widget.onSuffixTap?.call();
                      },
                    )
                  : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: _accessibilityService.defaultSpacing,
            vertical: _accessibilityService.defaultSpacing,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

