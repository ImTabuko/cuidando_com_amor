import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../services/data_service.dart';
import '../widgets/accessible_text.dart';
import 'available_caregivers_screen.dart';
import 'available_elderlies_screen.dart';
import 'matches_screen.dart';
import 'chats_screen.dart';
import 'telalogin.dart';
import 'accessibility_settings_screen.dart';
import '../widgets/accessible_button.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  final DataService _dataService = DataService();
  int _selectedIndex = 0;
  Uint8List? _tempPhotoBytes; // Foto temporária para preview

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
    return PopScope(
      canPop: false, // Desabilita botão de voltar do Android
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const TitleText('Cuidando com Amor', color: Colors.white),
          backgroundColor: AppColors.primary,
          actions: [
            AccessibleIconButton(
              icon: Icons.accessibility_new,
              label: 'Configurações de Acessibilidade',
              hint: 'Abrir configurações de acessibilidade',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccessibilitySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: _getPage(),
      ),
    );
  }

  Widget _getPage() {
    final isElderly = _authService.currentUser is ElderlyUser;

    switch (_selectedIndex) {
      case 0:
        // Mostrar cuidadores para idosos ou idosos para cuidadores
        return Column(
          children: [
            // Botões de navegação
            Container(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.people, isElderly ? 'Cuidadores' : 'Idosos', 0),
                  _buildNavButton(Icons.favorite, 'Matches', 1),
                  _buildNavButton(Icons.chat, 'Chats', 2),
                  _buildNavButton(Icons.person, 'Perfil', 3),
                ],
              ),
            ),
            Expanded(
              child: isElderly
                  ? const AvailableCaregiversScreen()
                  : const AvailableElderliesScreen(),
            ),
          ],
        );
      case 1:
        // Tela de matches
        return Column(
          children: [
            Container(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.people, isElderly ? 'Cuidadores' : 'Idosos', 0),
                  _buildNavButton(Icons.favorite, 'Matches', 1),
                  _buildNavButton(Icons.chat, 'Chats', 2),
                  _buildNavButton(Icons.person, 'Perfil', 3),
                ],
              ),
            ),
            const Expanded(child: MatchesScreen()),
          ],
        );
      case 2:
        // Tela de chats
        return Column(
          children: [
            Container(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.people, isElderly ? 'Cuidadores' : 'Idosos', 0),
                  _buildNavButton(Icons.favorite, 'Matches', 1),
                  _buildNavButton(Icons.chat, 'Chats', 2),
                  _buildNavButton(Icons.person, 'Perfil', 3),
                ],
              ),
            ),
            const Expanded(child: ChatsScreen()),
          ],
        );
      case 3:
        // Tela de perfil
        return Column(
          children: [
            Container(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.people, isElderly ? 'Cuidadores' : 'Idosos', 0),
                  _buildNavButton(Icons.favorite, 'Matches', 1),
                  _buildNavButton(Icons.chat, 'Chats', 2),
                  _buildNavButton(Icons.person, 'Perfil', 3),
                ],
              ),
            ),
            Expanded(child: _buildProfilePage()),
          ],
        );
      default:
        return const Center(child: TitleText('Página não encontrada'));
    }
  }

  Widget _buildProfilePage() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: TitleText('Usuário não encontrado'));
    }

    final isElderly = user is ElderlyUser;
    final name = user.fullName;
    final city = user.city;
    String userType = isElderly ? 'Idoso' : 'Cuidador';

    return SingleChildScrollView(
      padding: EdgeInsets.all(_accessibilityService.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: _accessibilityService.defaultSpacing),
          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _tempPhotoBytes != null
                    ? CircleAvatar(
                        radius: _accessibilityService.isLargeTextEnabled ? 80 : 60,
                        backgroundImage: MemoryImage(_tempPhotoBytes!),
                      )
                    : _photoService.buildProfilePhoto(
                        photoUrl: user.photoUrl,
                        radius: _accessibilityService.isLargeTextEnabled ? 80 : 60,
                        showEditIcon: true,
                        onTap: _changeProfilePhoto,
                      ),
              ],
            ),
          ),
          SizedBox(height: _accessibilityService.smallSpacing),
          ElevatedButton.icon(
            onPressed: _changeProfilePhoto,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const ButtonText('Alterar Foto', color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: _accessibilityService.defaultSpacing,
                vertical: _accessibilityService.smallSpacing,
              ),
            ),
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          TitleText(
            name,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          BodyText(
            '$userType • $city',
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _accessibilityService.largeSpacing * 2),
          _buildProfileInfo(user),
          SizedBox(height: _accessibilityService.largeSpacing * 2),
          ElevatedButton.icon(
            onPressed: () {
              _accessibilityService.mediumImpact();
              _logout();
            },
            icon: const Icon(Icons.logout),
            label: const ButtonText('Sair', color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(
                horizontal: _accessibilityService.largeSpacing * 2,
                vertical: _accessibilityService.defaultSpacing,
              ),
            ),
          ),
          SizedBox(height: _accessibilityService.largeSpacing),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(User user) {
    if (user is ElderlyUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Informações Pessoais', [
            _buildInfoItem('Nome', user.fullName),
            _buildInfoItem('Idade', '${user.age} anos'),
            _buildInfoItem('Cidade', user.city),
            _buildInfoItem('Telefone', user.phone),
            _buildInfoItem('Email', user.email ?? 'Não informado'),
          ]),
          SizedBox(height: _accessibilityService.defaultSpacing),
          _buildInfoSection('Necessidades de Cuidado', [
            _buildInfoItem('Necessidades', user.careNeeds),
            _buildInfoItem('Local', user.location),
            _buildInfoItem('Horário Preferido', user.preferredTime),
          ]),
        ],
      );
    } else if (user is CaregiverUser) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Informações Pessoais', [
            _buildInfoItem('Nome', user.fullName),
            _buildInfoItem('Idade', '${user.age} anos'),
            _buildInfoItem('Cidade', user.city),
            _buildInfoItem('Telefone', user.phone),
            _buildInfoItem('Email', user.email),
          ]),
          SizedBox(height: _accessibilityService.defaultSpacing),
          _buildInfoSection('Sobre Mim', [
            _buildInfoItem('Descrição', user.description),
          ]),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubtitleText(title, fontWeight: FontWeight.bold),
        SizedBox(height: _accessibilityService.smallSpacing),
        const Divider(thickness: 2),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _accessibilityService.smallSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _accessibilityService.isLargeTextEnabled ? 160 : 120,
            child: LabelText(
              '$label:',
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: BodyText(value),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Semantics(
        label: label,
        hint: 'Navegar para $label',
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            _accessibilityService.lightImpact();
            _onItemTapped(index);
          },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: _accessibilityService.iconSize * 0.9),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                label,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final photo = await _photoService.showImageSourceDialog(context);
    if (photo != null) {
      try {
        // Carregar bytes para preview imediato
        final bytes = await photo.readAsBytes();
        setState(() {
          _tempPhotoBytes = bytes;
        });
        
        // Converter para base64
        final base64 = await _photoService.convertXFileToBase64(photo);
        if (base64 == null || base64.isEmpty) {
          throw Exception('Erro ao converter foto. Tente novamente.');
        }
        
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('Usuário não encontrado');
        }
        
        // Atualizar no backend
        await _updateUserPhoto(user.id, base64);
        
        // Atualizar localmente
        user.photoUrl = base64;
        if (user is ElderlyUser) {
          user.photoUrl = base64;
        } else if (user is CaregiverUser) {
          user.photoUrl = base64;
        }
        
        // Recarregar usuários do backend para garantir sincronização
        await _dataService.reloadUsersFromApi();
        
        setState(() {
          _tempPhotoBytes = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Erro ao atualizar foto: $e');
        setState(() {
          _tempPhotoBytes = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar foto: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _updateUserPhoto(String userId, String photoBase64) async {
    try {
      const baseUrl = 'https://cuidando-com-amor-ssud.vercel.app/api';
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/photo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'photoUrl': photoBase64}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        throw Exception('Servidor retornou status ${response.statusCode}');
      }
      
      print('✅ Foto atualizada no backend com sucesso');
    } catch (e) {
      print('❌ Erro ao atualizar foto no backend: $e');
      rethrow; // Re-lançar para que o erro seja tratado no método chamador
    }
  }

  void _logout() {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }
}