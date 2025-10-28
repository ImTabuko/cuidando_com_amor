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
      theme: ThemeData(
        primarySwatch: Colors.brown,
        primaryColor: const Color(0xFF8B7355), // Marrom taupe
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7355), // Marrom taupe
          brightness: Brightness.light,
        ),
        useMaterial3: true,
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
