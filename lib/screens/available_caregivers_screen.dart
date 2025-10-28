import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/match_service.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_text.dart';
import '../widgets/accessibility_button.dart';
import 'caregiver_profile_screen.dart';
import '../utils/app_colors.dart';

class AvailableCaregiversScreen extends StatefulWidget {
  const AvailableCaregiversScreen({super.key});

  @override
  State<AvailableCaregiversScreen> createState() => _AvailableCaregiversScreenState();
}

class _AvailableCaregiversScreenState extends State<AvailableCaregiversScreen> {
  final MatchService _matchService = MatchService();
  final AuthService _authService = AuthService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  List<CaregiverUser> _availableCaregivers = [];
  bool _isLoading = true;
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
    _loadAvailableCaregivers();
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
              CircleAvatar(
                radius: _accessibilityService.isLargeTextEnabled ? 40 : 30,
                backgroundColor: AppColors.primaryShade50,
                child: Icon(
                  Icons.person,
                  size: _accessibilityService.isLargeTextEnabled ? 40 : 30,
                  color: AppColors.primary,
                ),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfileScreen(caregiver: caregiver),
      ),
    );

    // Se retornar com resultado positivo (match criado), atualizar a lista
    if (result == true) {
      _loadAvailableCaregivers();
    }
  }
}