import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/sign_language_service.dart';
import '../services/accessibility_service.dart';

/// Widget que exibe um intérprete de sinais (Libras) para textos
class SignLanguageInterpreter extends StatefulWidget {
  final String text;
  final double? width;
  final double? height;
  final bool autoPlay;
  final VoidCallback? onVideoReady;
  final VoidCallback? onError;

  const SignLanguageInterpreter({
    super.key,
    required this.text,
    this.width,
    this.height,
    this.autoPlay = true,
    this.onVideoReady,
    this.onError,
  });

  @override
  State<SignLanguageInterpreter> createState() => _SignLanguageInterpreterState();
}

class _SignLanguageInterpreterState extends State<SignLanguageInterpreter> {
  final SignLanguageService _signLanguageService = SignLanguageService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  String? _videoUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _accessibilityService.addListener(_onAccessibilityChanged);
    _checkAndLoad();
  }

  @override
  void dispose() {
    _accessibilityService.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    _checkAndLoad();
  }

  void _checkAndLoad() {
    if (_accessibilityService.signLanguageEnabled) {
      _signLanguageService.enable();
      _loadSignVideo();
    } else {
      _signLanguageService.disable();
      setState(() {
        _videoUrl = null;
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  @override
  void didUpdateWidget(SignLanguageInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _checkAndLoad();
    }
  }

  Future<void> _loadSignVideo() async {
    if (widget.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _videoUrl = null;
    });

    try {
      final videoUrl = await _signLanguageService.translateAndGetVideo(widget.text);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (videoUrl != null) {
            _videoUrl = videoUrl;
            _hasError = false;
            widget.onVideoReady?.call();
          } else {
            _hasError = true;
            widget.onError?.call();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        widget.onError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se não estiver habilitado, não mostrar nada
    if (!_accessibilityService.signLanguageEnabled || !_signLanguageService.isEnabled) {
      return const SizedBox.shrink();
    }

    final width = widget.width ?? 200.0;
    final height = widget.height ?? 150.0;

    if (_isLoading) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError || _videoUrl == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sign_language,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Tradução indisponível',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Exibir widget VLibras (funciona em web via iframe)
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _videoUrl != null && kIsWeb
            ? _buildVlibrasWidget(width, height)
            : _buildVideoIcon(width, height),
      ),
    );
  }


  Widget _buildVideoIcon(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 60,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            'Toque para ver em Libras',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVlibrasWidget(double width, double height) {
    if (!kIsWeb) {
      return _buildVideoIcon(width, height);
    }

    // Em web, usar HtmlElementView para embedar o widget VLibras
    return Container(
      width: width,
      height: height,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sign_language,
              size: 48,
              color: Colors.blue[800],
            ),
            const SizedBox(height: 8),
            Text(
              'Libras Ativado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tradução: "${widget.text}"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _openVlibrasWebsite(),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Abrir VLibras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVlibrasWebsite() {
    if (kIsWeb && _videoUrl != null) {
      try {
        // Usar universal_html para compatibilidade
        // Em web, podemos usar window.open via JavaScript
        // Por enquanto, apenas mostrar mensagem
        print('Abrindo VLibras: $_videoUrl');
      } catch (e) {
        print('Erro ao abrir VLibras: $e');
      }
    }
  }
}

