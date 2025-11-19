import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/auth_service.dart';
import '../services/photo_service.dart';

class ElderlyProfileScreen extends StatefulWidget {
  final ElderlyUser elderly;

  const ElderlyProfileScreen({super.key, required this.elderly});

  @override
  State<ElderlyProfileScreen> createState() => _ElderlyProfileScreenState();
}

class _ElderlyProfileScreenState extends State<ElderlyProfileScreen> {
  final MatchService _matchService = MatchService();
  final AuthService _authService = AuthService();
  final PhotoService _photoService = PhotoService();
  bool _isLoading = false;
  Match? _existingMatch;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Recarregar dados do usuário para garantir que temos as informações mais atualizadas
    try {
      await _matchService.dataService.reloadUsersFromApi();
      await _matchService.dataService.reloadMatchesFromApi();
      
      // Verificar se existe match entre o usuário atual e este idoso
      final currentUser = _authService.currentUser;
      if (currentUser is CaregiverUser) {
        _existingMatch = _matchService.dataService.getExistingMatch(
          widget.elderly.id,
          currentUser.id,
        );
      }
      
      // Atualizar o widget com os dados mais recentes
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('⚠️ Erro ao recarregar dados do perfil: $e');
    }
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
        title: const Text('Perfil do Idoso', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildInfoSection('Informações Pessoais', [
                    _buildInfoItem('Nome', widget.elderly.fullName),
                    _buildInfoItem('Idade', '${widget.elderly.age} anos'),
                    _buildInfoItem('Cidade', widget.elderly.city),
                    _buildInfoItem('Telefone', widget.elderly.phone),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Necessidades de Cuidado', [
                    _buildInfoItem('Necessidades', widget.elderly.careNeeds),
                    _buildInfoItem('Local', widget.elderly.location),
                    _buildInfoItem('Horário Preferido', widget.elderly.preferredTime),
                  ]),
                  const SizedBox(height: 32),
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
            photoUrl: widget.elderly.photoUrl,
            radius: 60,
            showEditIcon: false,
          ),
          const SizedBox(height: 16),
          Text(
            widget.elderly.fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            'Idoso(a) • ${widget.elderly.city}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Divider(),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchButton() {
    // Verificar se o usuário atual é um cuidador
    if (_authService.currentUser is! CaregiverUser) {
      return const SizedBox.shrink();
    }

    final currentUser = _authService.currentUser as CaregiverUser;
    
    // Verificar se já existe match aceito
    final hasAccepted = _matchService.dataService.hasAcceptedMatch(
      widget.elderly.id,
      currentUser.id,
    );
    
    if (hasAccepted) {
      // Match já aceito, não mostrar botão
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Text(
            'Match aceito! Vocês já estão conectados.',
            style: TextStyle(
              color: Colors.green[800],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Verificar se existe match rejeitado
    final isRejected = _existingMatch?.status == MatchStatus.rejected;
    final buttonText = isRejected ? 'Reenviar Oferta' : 'Oferecer Cuidados';

    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRejected ? Colors.orange : Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _createMatch() async {
    if (_authService.currentUser is! CaregiverUser) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apenas cuidadores podem oferecer cuidados')),
      );
      return;
    }

    final caregiver = _authService.currentUser as CaregiverUser;

    setState(() {
      _isLoading = true;
    });

    try {
      await _matchService.createMatch(widget.elderly.id, caregiver.id, createdBy: MatchCreatedBy.caregiver);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta enviada com sucesso!')),
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