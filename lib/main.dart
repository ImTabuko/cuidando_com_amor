import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/telalogin.dart';
import 'screens/telaregistro.dart';
import 'screens/home_screen.dart';
import 'screens/available_caregivers_screen.dart';
import 'screens/available_elderlies_screen.dart';
import 'screens/matches_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuidando com Amor',
      debugShowCheckedModeBanner: false,
      // Configurações de acessibilidade
      builder: (context, child) {
        return MediaQuery(
          // Respeitar configurações de acessibilidade do sistema
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(1.0, 2.0),
            boldText: MediaQuery.of(context).boldText,
            highContrast: MediaQuery.of(context).highContrast,
          ),
          child: Semantics(
            // Configurações globais de Semantics
            label: 'Cuidando com Amor - Aplicativo de conexão entre idosos e cuidadores',
            child: child!,
          ),
        );
      },
      theme: ThemeData(
        primarySwatch: Colors.brown,
        primaryColor: const Color(0xFF8B7355), // Marrom taupe
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7355), // Marrom taupe
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Melhorar contraste de texto
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.black87),
          displayMedium: TextStyle(color: Colors.black87),
          displaySmall: TextStyle(color: Colors.black87),
          headlineLarge: TextStyle(color: Colors.black87),
          headlineMedium: TextStyle(color: Colors.black87),
          headlineSmall: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
        ),
        // Melhorar contraste de ícones
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        // Áreas de toque maiores
        buttonTheme: const ButtonThemeData(
          minWidth: 48.0,
          height: 48.0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/available_caregivers': (context) => const AvailableCaregiversScreen(),
        '/available_elderlies': (context) => const AvailableElderliesScreen(),
        '/matches': (context) => const MatchesScreen(),
      },
    );
  }
}
