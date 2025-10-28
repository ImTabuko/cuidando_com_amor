import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/match_service.dart';
import '../models/auth_service.dart';

class ElderlyProfileScreen extends StatefulWidget {
  final ElderlyUser elderly;

  const ElderlyProfileScreen({super.key, required this.elderly});

  @override
  State<ElderlyProfileScreen> createState() => _ElderlyProfileScreenState();
}

class _ElderlyProfileScreenState extends State<ElderlyProfileScreen> {
  final MatchService _matchService = MatchService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Idoso'),
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
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue[100],
            backgroundImage: widget.elderly.photoUrl != null
                ? NetworkImage(widget.elderly.photoUrl!)
                : null,
            child: widget.elderly.photoUrl == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.blue[800],
                  )
                : null,
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

    return Center(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Oferecer Cuidados',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _createMatch() async {
    if (_authService.currentUser is! CaregiverUser) {
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
      await _matchService.createMatch(widget.elderly.id, caregiver.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta enviada com sucesso!')),
        );
        Navigator.pop(context, true); // Retornar com resultado positivo
      }
    } catch (e) {
      if (mounted) {
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