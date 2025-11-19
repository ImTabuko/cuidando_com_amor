import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _isLargeTextEnabled = false;
  bool _reduceMotionEnabled = false;
  bool _hapticFeedbackEnabled = true;
  bool _screenReaderEnabled = false;

  // Getters
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  bool get reduceMotionEnabled => _reduceMotionEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get screenReaderEnabled => _screenReaderEnabled;

  // Detectar configurações do sistema (apenas leitor de tela e animações)
  // Não sobrescreve configurações manuais de texto grande
  void updateFromMediaQuery(MediaQueryData mediaQuery) {
    _reduceMotionEnabled = mediaQuery.disableAnimations;
    _screenReaderEnabled = mediaQuery.accessibleNavigation;
    
    // Apenas atualizar texto grande se o usuário não configurou manualmente
    // (isso é detectado se ainda está no valor padrão)
    if (!_isLargeTextEnabled) {
      final textScaleFactor = mediaQuery.textScaleFactor;
      _isLargeTextEnabled = textScaleFactor > 1.0;
    }
    
    _notifyListeners();
  }
  
  // Método para atualizar apenas leitor de tela e animações (sem afetar configurações manuais)
  void updateSystemOnly(MediaQueryData mediaQuery) {
    _reduceMotionEnabled = mediaQuery.disableAnimations;
    _screenReaderEnabled = mediaQuery.accessibleNavigation;
    _notifyListeners();
  }

  // Feedback tátil (desabilitado no web para evitar travamentos)
  Future<void> lightImpact() async {
    if (kIsWeb) return; // Não funciona no web
    if (_hapticFeedbackEnabled) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e) {}
    }
  }

  Future<void> mediumImpact() async {
    if (kIsWeb) return;
    if (_hapticFeedbackEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e) {}
    }
  }

  Future<void> heavyImpact() async {
    if (kIsWeb) return;
    if (_hapticFeedbackEnabled) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (e) {}
    }
  }

  Future<void> selectionClick() async {
    if (kIsWeb) return;
    if (_hapticFeedbackEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (e) {}
    }
  }

  Future<void> vibrate() async {
    if (kIsWeb) return;
    if (_hapticFeedbackEnabled) {
      try {
        await HapticFeedback.vibrate();
      } catch (e) {}
    }
  }

  void toggleHapticFeedback() {
    _hapticFeedbackEnabled = !_hapticFeedbackEnabled;
    _notifyListeners();
  }

  // Tamanhos de texto que respeitam o sistema
  double getTitleSize(double baseSize, double? textScaleFactor) {
    final scale = textScaleFactor ?? (_isLargeTextEnabled ? 1.3 : 1.0);
    return baseSize * scale;
  }

  double get titleSize => _isLargeTextEnabled ? 32.0 : 24.0;
  double get subtitleSize => _isLargeTextEnabled ? 24.0 : 18.0;
  double get bodyTextSize => _isLargeTextEnabled ? 20.0 : 16.0;
  double get buttonTextSize => _isLargeTextEnabled ? 20.0 : 16.0;
  double get labelTextSize => _isLargeTextEnabled ? 16.0 : 14.0;
  double get hintTextSize => _isLargeTextEnabled ? 16.0 : 14.0;

  // Tamanhos para campos de texto
  double get textFieldHeight => _isLargeTextEnabled ? 70.0 : 56.0;
  double get iconSize => _isLargeTextEnabled ? 28.0 : 24.0;
  double get smallerIconSize => _isLargeTextEnabled ? 24.0 : 20.0;

  // Espaçamentos maiores
  double get defaultSpacing => _isLargeTextEnabled ? 24.0 : 16.0;
  double get smallSpacing => _isLargeTextEnabled ? 16.0 : 8.0;
  double get largeSpacing => _isLargeTextEnabled ? 32.0 : 24.0;

  // Método mantido para compatibilidade (sempre retorna a cor padrão)
  Color getHighContrastColor(Color defaultColor, {Color? lightColor, Color? darkColor}) {
    return defaultColor;
  }

  // Toggle para ativar/desativar texto grande
  void toggleLargeText() {
    _isLargeTextEnabled = !_isLargeTextEnabled;
    _notifyListeners();
  }

  // Ativar texto grande
  void enableLargeText() {
    if (!_isLargeTextEnabled) {
      _isLargeTextEnabled = true;
      _notifyListeners();
    }
  }

  // Desativar texto grande
  void disableLargeText() {
    if (_isLargeTextEnabled) {
      _isLargeTextEnabled = false;
      _notifyListeners();
    }
  }

  // Listeners para atualizar a UI
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
