import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_text.dart';
import '../widgets/accessibility_button.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
    _navigateToLogin();
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

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      floatingActionButton: const AccessibilityButton(heroTag: 'splash_accessibility'),
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
          ],
        ),
      ),
    );
  }
}
