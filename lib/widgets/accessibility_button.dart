import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../utils/app_colors.dart';

class AccessibilityButton extends StatefulWidget {
  final String? heroTag;
  
  const AccessibilityButton({super.key, this.heroTag});

  @override
  State<AccessibilityButton> createState() => _AccessibilityButtonState();
}

class _AccessibilityButtonState extends State<AccessibilityButton> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
  }

  @override
  void dispose() {
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    });
  }

  void _toggleAccessibility() {
    _accessibilityService.toggleLargeText();
    
    // Mostrar mensagem de feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLargeTextEnabled 
            ? 'Texto normal ativado' 
            : 'Texto grande ativado para melhor leitura',
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: _isLargeTextEnabled ? AppColors.primary : AppColors.primaryDark,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: widget.heroTag,
      onPressed: _toggleAccessibility,
      backgroundColor: _isLargeTextEnabled ? AppColors.primaryDark : AppColors.primary,
      foregroundColor: Colors.white,
      tooltip: _isLargeTextEnabled 
        ? 'Ativar texto normal' 
        : 'Ativar texto grande para idosos',
      child: Icon(
        _isLargeTextEnabled ? Icons.text_fields : Icons.text_increase,
        size: 24,
      ),
    );
  }
}

// Widget de botão menor para usar em AppBars
class AccessibilityAppBarButton extends StatelessWidget {
  const AccessibilityAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    final isLargeTextEnabled = accessibilityService.isLargeTextEnabled;

    return IconButton(
      onPressed: () {
        accessibilityService.toggleLargeText();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLargeTextEnabled 
                ? 'Texto normal ativado' 
                : 'Texto grande ativado',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: isLargeTextEnabled ? AppColors.primary : AppColors.primaryDark,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: Icon(
        isLargeTextEnabled ? Icons.text_fields : Icons.text_increase,
        color: Colors.white,
      ),
      tooltip: isLargeTextEnabled 
        ? 'Texto normal' 
        : 'Texto grande',
    );
  }
}
