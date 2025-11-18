import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/data_service.dart';
import '../widgets/accessible_text.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AccessibilityService _accessibilityService = AccessibilityService();
  final DataService _dataService = DataService();
  String _status = 'Carregando...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: -0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    // Iniciar animação com delay para garantir que a tela está pronta
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeApp() async {
    // Garantir que a splash apareça por pelo menos 1.5 segundos
    final startTime = DateTime.now();
    
    // Tentar auto-login em background (não bloqueia)
    _tryAutoLoginInBackground();
    
    // Aguardar tempo mínimo de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Calcular tempo restante se necessário
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
    }
    
    if (!mounted) return;
    
    // Ir para login após tempo mínimo
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  // Tenta auto-login em background sem bloquear
  void _tryAutoLoginInBackground() async {
    try {
      // Inicializar em background
      _dataService.initialize().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      ).catchError((e) => null);
      
      // Tentar auto-login
      final loggedIn = await _dataService.autoLogin().timeout(
        const Duration(seconds: 1),
        onTimeout: () => false,
      ).catchError((e) => false);
      
      // Se logado, aguardar um pouco e navegar para home
      if (loggedIn && mounted) {
        // Aguardar para garantir que splash foi mostrada
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      // Ignora erros
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo com animações
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: AppLogo(
                          width: _accessibilityService.isLargeTextEnabled ? 320 : 280,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: _accessibilityService.largeSpacing * 2),
            
            // Texto com animação de fade
            FadeTransition(
              opacity: _fadeAnimation,
              child: BodyText(
                'Conectando cuidadores e idosos',
                color: AppColors.white.withOpacity(0.9),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: _accessibilityService.largeSpacing * 2),
            
            // Indicador de carregamento com animação
            FadeTransition(
              opacity: _fadeAnimation,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                strokeWidth: _accessibilityService.isLargeTextEnabled ? 4.0 : 3.0,
              ),
            ),
            SizedBox(height: _accessibilityService.defaultSpacing),
            
            // Status de conexão com animação
            FadeTransition(
              opacity: _fadeAnimation,
              child: BodyText(
                _status,
                color: AppColors.white.withOpacity(0.7),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
