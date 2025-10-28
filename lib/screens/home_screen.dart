import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../widgets/accessible_text.dart';
import '../widgets/accessibility_button.dart';
import 'available_caregivers_screen.dart';
import 'available_elderlies_screen.dart';
import 'matches_screen.dart';
import 'chats_screen.dart';
import 'telalogin.dart';
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
  int _selectedIndex = 0;
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
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

  @override
  Widget build(BuildContext context) {
    final isElderly = _authService.currentUser is ElderlyUser;
    final isCaregiver = _authService.currentUser is CaregiverUser;

    return Scaffold(
      appBar: AppBar(
        title: TitleText('Cuidando com Amor', color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: _getPage(),
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
        return Center(child: TitleText('Página não encontrada'));
    }
  }

  Widget _buildProfilePage() {
    final user = _authService.currentUser;
    if (user == null) {
      return Center(child: TitleText('Usuário não encontrado'));
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
          _photoService.buildProfilePhoto(
            photoUrl: user.photoUrl,
            radius: _accessibilityService.isLargeTextEnabled ? 80 : 60,
            showEditIcon: false,
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
            onPressed: _logout,
            icon: Icon(Icons.logout),
            label: ButtonText('Sair', color: Colors.white),
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
            _buildInfoItem('Email', user.email ?? 'Não informado'),
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
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: _accessibilityService.iconSize),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
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