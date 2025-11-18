import 'package:flutter/material.dart';
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
    if (_accessibilityService.signLanguageEnabled && _signLanguageService.isEnabled) {
      _loadSignVideo();
    }
  }

  @override
  void didUpdateWidget(SignLanguageInterpreter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && 
        _accessibilityService.signLanguageEnabled && 
        _signLanguageService.isEnabled) {
      _loadSignVideo();
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

    // Exibir vídeo de sinais (funciona em web e mobile)
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _videoUrl != null
            ? Stack(
                children: [
                  // Tentar exibir como imagem primeiro (se for GIF ou frame)
                  Image.network(
                    _videoUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Se falhar, mostrar ícone de vídeo
                      return _buildVideoIcon(width, height);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  // Botão de play sobreposto
                  Positioned.fill(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.play_circle_filled,
                          color: Colors.white70,
                          size: 48,
                        ),
                        onPressed: () {
                          // Abrir vídeo em player externo ou modal
                          _showVideoModal(context);
                        },
                      ),
                    ),
                  ),
                ],
              )
            : _buildErrorWidget(width, height),
      ),
    );
  }

  Widget _buildErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
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
            'Erro ao carregar vídeo',
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

  void _showVideoModal(BuildContext context) {
    if (_videoUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Center(
                child: _videoUrl != null
                    ? Image.network(
                        _videoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Erro ao carregar vídeo',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

