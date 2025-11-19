import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../widgets/accessible_text.dart';

class CaregiverProfileScreen extends StatefulWidget {
  final CaregiverUser caregiver;

  const CaregiverProfileScreen({super.key, required this.caregiver});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final MatchService _matchService = MatchService();
  final AuthService _authService = AuthService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accessibilityService.addListener(_updateState);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Recarregar dados do usuário para garantir que temos as informações mais atualizadas
    try {
      await _matchService.dataService.reloadUsersFromApi();
      // Atualizar o widget com os dados mais recentes
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Erro ao recarregar dados do perfil: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TitleText('Perfil do Cuidador', color: Colors.white),
        backgroundColor: Colors.blue[800],
      ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(_accessibilityService.largeSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: _accessibilityService.largeSpacing),
                    _buildInfoSection('Informações Pessoais', [
                      _buildInfoItem('Nome', widget.caregiver.fullName),
                      _buildInfoItem('Idade', '${widget.caregiver.age} anos'),
                      _buildInfoItem('Cidade', widget.caregiver.city),
                      _buildInfoItem('Telefone', widget.caregiver.phone),
                    ]),
                    SizedBox(height: _accessibilityService.defaultSpacing),
                    _buildInfoSection('Sobre Mim', [
                      _buildInfoItem('Descrição', widget.caregiver.description),
                    ]),
                    SizedBox(height: _accessibilityService.largeSpacing * 2),
                    _buildMatchButton(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          _photoService.buildProfilePhoto(
            photoUrl: widget.caregiver.photoUrl,
            radius: _accessibilityService.isLargeTextEnabled ? 80 : 60,
            showEditIcon: false,
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          TitleText(
            widget.caregiver.fullName,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          BodyText(
            'Cuidador(a) • ${widget.caregiver.city}',
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
            width: _accessibilityService.isLargeTextEnabled ? 160 : 100,
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

  Widget _buildMatchButton() {
    // Verificar se o usuário atual é um idoso
    if (_authService.currentUser is! ElderlyUser) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(
            horizontal: _accessibilityService.largeSpacing * 2,
            vertical: _accessibilityService.defaultSpacing,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: ButtonText(
          'Solicitar Cuidados',
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _createMatch() async {
    if (_authService.currentUser is! ElderlyUser) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas idosos podem solicitar cuidados')),
      );
      return;
    }

    final elderly = _authService.currentUser as ElderlyUser;

    setState(() {
      _isLoading = true;
    });

    try {
      await _matchService.createMatch(elderly.id, widget.caregiver.id, createdBy: MatchCreatedBy.elderly);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada com sucesso!')),
        );
        Navigator.pop(context, true); // Retornar com resultado positivo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
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