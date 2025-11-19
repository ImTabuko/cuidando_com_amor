import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../widgets/accessible_text.dart';
import 'caregiver_profile_screen.dart';

class AvailableCaregiversScreen extends StatefulWidget {
  const AvailableCaregiversScreen({super.key});

  @override
  State<AvailableCaregiversScreen> createState() => _AvailableCaregiversScreenState();
}

class _AvailableCaregiversScreenState extends State<AvailableCaregiversScreen> {
  final AuthService _authService = AuthService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  List<CaregiverUser> _availableCaregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _accessibilityService.addListener(_updateState);
    _loadAvailableCaregivers();
  }

  @override
  void dispose() {
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  Future<void> _loadAvailableCaregivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Apenas idosos podem ver cuidadores disponíveis
      if (_authService.currentUser is ElderlyUser) {
        _availableCaregivers = await _authService.getAvailableCaregivers();
      } else {
        // Se não for um idoso, não mostrar nada
        _availableCaregivers = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar cuidadores: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _availableCaregivers.isEmpty
            ? _buildEmptyState()
            : _buildCaregiverList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: _accessibilityService.isLargeTextEnabled ? 100 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          TitleText(
            'Nenhum cuidador disponível no momento',
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _accessibilityService.largeSpacing),
          ElevatedButton(
            onPressed: _loadAvailableCaregivers,
            child: ButtonText('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverList() {
    return RefreshIndicator(
      onRefresh: _loadAvailableCaregivers,
      child: ListView.builder(
        padding: EdgeInsets.all(_accessibilityService.largeSpacing),
        itemCount: _availableCaregivers.length,
        itemBuilder: (context, index) {
          final caregiver = _availableCaregivers[index];
          return _buildCaregiverCard(caregiver);
        },
      ),
    );
  }

  Widget _buildCaregiverCard(CaregiverUser caregiver) {
    return Card(
      margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewCaregiverProfile(caregiver),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(_accessibilityService.largeSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photoService.buildProfilePhoto(
                photoUrl: caregiver.photoUrl,
                radius: _accessibilityService.isLargeTextEnabled ? 40 : 30,
                showEditIcon: false,
              ),
              SizedBox(width: _accessibilityService.defaultSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleText(
                      caregiver.fullName,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing / 2),
                    BodyText(
                      '${caregiver.age} anos • ${caregiver.city}',
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    BodyText(
                      caregiver.description,
                      maxLines: 2,
                    ),
                    SizedBox(height: _accessibilityService.smallSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _viewCaregiverProfile(caregiver),
                          child: ButtonText('Ver Perfil'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewCaregiverProfile(CaregiverUser caregiver) async {
    // Recarregar dados antes de abrir o perfil para garantir informações atualizadas
    try {
      await _authService.getAvailableCaregivers();
    } catch (e) {
      print('⚠️ Erro ao recarregar cuidadores: $e');
    }
    
    // Buscar o cuidador atualizado na lista
    final updatedCaregivers = await _authService.getAvailableCaregivers();
    final updatedCaregiver = updatedCaregivers.where((c) => c.id == caregiver.id).firstOrNull;
    
    if (updatedCaregiver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil não encontrado')),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfileScreen(caregiver: updatedCaregiver),
      ),
    );

    // Se retornar com resultado positivo (match criado), atualizar a lista
    if (result == true || mounted) {
      _loadAvailableCaregivers();
    }
  }
}