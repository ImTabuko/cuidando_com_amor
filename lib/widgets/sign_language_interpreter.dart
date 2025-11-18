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
    // Widget que mostra a tradução em Libras
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!, width: 2),
      ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '"${widget.text}"',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _openVlibrasWebsite(),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver em Libras'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVlibrasWebsite() {
    if (_videoUrl != null && mounted) {
      // Mostrar mensagem informativa
      try {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Libras: "${widget.text}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Erro ao mostrar mensagem: $e');
      }
    }
  }
}

