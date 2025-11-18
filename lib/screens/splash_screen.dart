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

class _SplashScreenState extends State<SplashScreen> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  final DataService _dataService = DataService();
  String _status = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
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
            // Logo completa
            AppLogo(
              width: _accessibilityService.isLargeTextEnabled ? 320 : 280,
            ),
            SizedBox(height: _accessibilityService.largeSpacing * 2),
            
            BodyText(
              'Conectando cuidadores e idosos',
              color: AppColors.white.withOpacity(0.9),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _accessibilityService.largeSpacing * 2),
            
            // Indicador de carregamento
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
              strokeWidth: _accessibilityService.isLargeTextEnabled ? 4.0 : 3.0,
            ),
            SizedBox(height: _accessibilityService.defaultSpacing),
            
            // Status de conexão
            BodyText(
              _status,
              color: AppColors.white.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
