class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _isLargeTextEnabled = false;

  // Getters
  bool get isLargeTextEnabled => _isLargeTextEnabled;

  // Tamanhos de texto normais
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
  final List<Function()> _listeners = [];

  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
