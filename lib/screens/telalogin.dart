import 'package:flutter/material.dart';
import '../models/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_text.dart';
import '../widgets/accessibility_button.dart';
import '../utils/app_colors.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AccessibilityService _accessibilityService = AccessibilityService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLargeTextEnabled = false;
  bool _loginByPhone = false; // Nova opção de login por telefone

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        bool success;
        
        if (_loginByPhone) {
          success = await authService.loginByPhone(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          success = await authService.login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navegar para a tela principal após login bem-sucedido
          Navigator.pushReplacementNamed(context, '/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_loginByPhone ? 'Telefone ou senha incorretos' : 'Email ou senha incorretos'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: const AccessibilityButton(heroTag: 'login_accessibility'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_accessibilityService.largeSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: _accessibilityService.largeSpacing * 2),
                // Logo e título
                Center(
                  child: AppLogo(
                    width: _accessibilityService.isLargeTextEnabled ? 280 : 240,
                  ),
                ),
                SizedBox(height: _accessibilityService.defaultSpacing),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TitleText(
                    'Bem-vindo!',
                    color: Colors.black87,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BodyText(
                    'Faça login para continuar',
                    color: Colors.grey,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _accessibilityService.largeSpacing * 2),

                // Toggle para escolher tipo de login
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: BodyText(
                            'Como deseja fazer login?',
                            fontWeight: FontWeight.bold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: _accessibilityService.smallSpacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: BodyText('Email'),
                                value: false,
                                groupValue: _loginByPhone,
                                onChanged: (value) {
                                  setState(() {
                                    _loginByPhone = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: BodyText('Telefone'),
                                value: true,
                                groupValue: _loginByPhone,
                                onChanged: (value) {
                                  setState(() {
                                    _loginByPhone = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: _accessibilityService.defaultSpacing),

                // Campo de usuário/email/telefone
                CustomTextField(
                  controller: _usernameController,
                  label: _loginByPhone ? 'Número de Telefone' : 'Email',
                  icon: _loginByPhone ? Icons.phone : Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _loginByPhone ? 'Por favor, insira seu telefone' : 'Por favor, insira seu email';
                    }
                    if (_loginByPhone) {
                      // Validação básica de telefone
                      if (value.length < 10) {
                        return 'Telefone deve ter pelo menos 10 dígitos';
                      }
                    } else {
                      // Validação básica de email
                      if (!value.contains('@')) {
                        return 'Por favor, insira um email válido';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: _accessibilityService.defaultSpacing),

                // Campo de senha
                CustomTextField(
                  controller: _passwordController,
                  label: 'Senha',
                  icon: Icons.lock,
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                
                // Botão para mostrar/ocultar senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                      size: _accessibilityService.smallerIconSize,
                    ),
                    label: BodyText(
                      _isPasswordVisible ? 'Ocultar' : 'Mostrar',
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: _accessibilityService.largeSpacing),

                // Botão de login
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: _accessibilityService.defaultSpacing,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: _accessibilityService.iconSize,
                          width: _accessibilityService.iconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : ButtonText(
                          'Entrar',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                ),
                SizedBox(height: _accessibilityService.defaultSpacing),

                // Link para registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BodyText(
                      'Não tem uma conta? ',
                      color: Colors.grey,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registration');
                      },
                      child: ButtonText(
                        'Cadastre-se',
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
