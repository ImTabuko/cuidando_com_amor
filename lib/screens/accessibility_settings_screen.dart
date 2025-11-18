import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_text.dart';
import '../widgets/accessible_card.dart';
import '../widgets/accessible_button.dart';
import '../utils/app_colors.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  final AccessibilityService _accessibilityService = AccessibilityService();

  @override
  void initState() {
    super.initState();
    _accessibilityService.addListener(_updateState);
  }

  @override
  void dispose() {
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Não atualizar automaticamente - usar configurações manuais do usuário
    // _accessibilityService.updateFromMediaQuery(mediaQuery);

    return Scaffold(
      appBar: AppBar(
        title: const TitleText('Configurações de Acessibilidade', color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
        children: [
          Semantics(
            header: true,
            child: TitleText(
              'Ajustes de Texto',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          
          // Texto Grande
          AccessibleCard(
            semanticLabel: 'Ativar texto grande',
            hint: 'Aumenta o tamanho da fonte para facilitar a leitura',
            child: SwitchListTile(
              title: const BodyText('Texto Grande'),
              subtitle: const HintText(
                'Aumenta o tamanho da fonte em todo o aplicativo',
                color: Colors.grey,
              ),
              value: _accessibilityService.isLargeTextEnabled,
              onChanged: (value) {
                _accessibilityService.mediumImpact();
                if (value) {
                  _accessibilityService.enableLargeText();
                } else {
                  _accessibilityService.disableLargeText();
                }
              },
            ),
          ),
          
          SizedBox(height: _accessibilityService.smallSpacing),
          
          // Alto Contraste
          AccessibleCard(
            semanticLabel: 'Ativar alto contraste',
            hint: 'Aumenta o contraste das cores para melhor visibilidade',
            child: SwitchListTile(
              title: const BodyText('Alto Contraste'),
              subtitle: const HintText(
                'Aumenta o contraste entre texto e fundo',
                color: Colors.grey,
              ),
              value: _accessibilityService.isHighContrastEnabled,
              onChanged: (value) {
                _accessibilityService.mediumImpact();
                _accessibilityService.toggleHighContrast();
              },
            ),
          ),

          SizedBox(height: _accessibilityService.smallSpacing),

          // Feedback Tátil
          AccessibleCard(
            semanticLabel: 'Ativar feedback tátil',
            hint: 'Vibração ao tocar em elementos interativos',
            child: SwitchListTile(
              title: const BodyText('Feedback Tátil'),
              subtitle: const HintText(
                'Vibração ao interagir com botões e elementos',
                color: Colors.grey,
              ),
              value: _accessibilityService.hapticFeedbackEnabled,
              onChanged: (value) {
                _accessibilityService.mediumImpact();
                _accessibilityService.toggleHapticFeedback();
              },
            ),
          ),

          SizedBox(height: _accessibilityService.largeSpacing),
          
          Semantics(
            header: true,
            child: TitleText(
              'Configurações do Sistema',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          
          // Informações do sistema
          Builder(
            builder: (context) {
              final mediaQuery = MediaQuery.of(context);
              return AccessibleCard(
                semanticLabel: 'Informações de acessibilidade do sistema',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BodyText(
                      'Fator de Escala de Texto: ${mediaQuery.textScaleFactor.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      'Texto em Negrito: ${mediaQuery.boldText ? "Ativado" : "Desativado"}',
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      'Alto Contraste: ${_accessibilityService.isHighContrastEnabled || mediaQuery.highContrast ? "Ativado" : "Desativado"}',
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      'Animações Reduzidas: ${mediaQuery.disableAnimations ? "Ativado" : "Desativado"}',
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      'Leitor de Tela: ${mediaQuery.accessibleNavigation ? "Ativado" : "Desativado"}',
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      'Feedback Tátil: ${_accessibilityService.hapticFeedbackEnabled ? "Ativado" : "Desativado"}',
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: _accessibilityService.largeSpacing),
          
          Semantics(
            header: true,
            child: TitleText(
              'Dicas de Acessibilidade',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          
          AccessibleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyText(
                  '• Use leitores de tela: O aplicativo é compatível com TalkBack (Android) e VoiceOver (iOS)',
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                BodyText(
                  '• Navegação por teclado: Todos os elementos podem ser navegados usando o teclado',
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                BodyText(
                  '• Áreas de toque: Todos os botões têm área mínima de toque de 48x48 pixels',
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                BodyText(
                  '• Contraste: O aplicativo respeita as configurações de alto contraste do sistema',
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                BodyText(
                  '• Feedback Tátil: Ative para receber vibração ao interagir com elementos',
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                BodyText(
                  '• Navegação: Use gestos de deslizar para navegar entre elementos',
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),

          SizedBox(height: _accessibilityService.largeSpacing),

          // Teste de Feedback Tátil
          Semantics(
            header: true,
            child: TitleText(
              'Testar Feedback Tátil',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),

          AccessibleCard(
            semanticLabel: 'Botões de teste de feedback tátil',
            child: Column(
              children: [
                AccessibleButton(
                  label: 'Teste Leve',
                  onPressed: () => _accessibilityService.lightImpact(),
                  icon: Icons.touch_app,
                  semanticLabel: 'Testar feedback tátil leve',
                  hint: 'Toque para sentir uma vibração leve',
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                AccessibleButton(
                  label: 'Teste Médio',
                  onPressed: () => _accessibilityService.mediumImpact(),
                  icon: Icons.touch_app,
                  semanticLabel: 'Testar feedback tátil médio',
                  hint: 'Toque para sentir uma vibração média',
                ),
                SizedBox(height: _accessibilityService.smallSpacing),
                AccessibleButton(
                  label: 'Teste Forte',
                  onPressed: () => _accessibilityService.heavyImpact(),
                  icon: Icons.touch_app,
                  semanticLabel: 'Testar feedback tátil forte',
                  hint: 'Toque para sentir uma vibração forte',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

