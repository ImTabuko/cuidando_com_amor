import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/auth_service.dart';
import '../services/photo_service.dart';
import 'elderly_profile_screen.dart';

class AvailableElderliesScreen extends StatefulWidget {
  const AvailableElderliesScreen({super.key});

  @override
  State<AvailableElderliesScreen> createState() => _AvailableElderliesScreenState();
}

class _AvailableElderliesScreenState extends State<AvailableElderliesScreen> {
  final AuthService _authService = AuthService();
  final PhotoService _photoService = PhotoService();
  List<ElderlyUser> _availableElderlies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableElderlies();
  }

  Future<void> _loadAvailableElderlies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Apenas cuidadores podem ver idosos disponíveis
      if (_authService.currentUser is CaregiverUser) {
        _availableElderlies = await _authService.getAvailableElderlies();
      } else {
        // Se não for um cuidador, não mostrar nada
        _availableElderlies = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar idosos: ${e.toString()}')),
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
        : _availableElderlies.isEmpty
            ? _buildEmptyState()
            : _buildElderlyList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum idoso disponível no momento',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAvailableElderlies,
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildElderlyList() {
    return RefreshIndicator(
      onRefresh: _loadAvailableElderlies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableElderlies.length,
        itemBuilder: (context, index) {
          final elderly = _availableElderlies[index];
          return _buildElderlyCard(elderly);
        },
      ),
    );
  }

  Widget _buildElderlyCard(ElderlyUser elderly) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewElderlyProfile(elderly),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photoService.buildProfilePhoto(
                photoUrl: elderly.photoUrl,
                radius: 30,
                showEditIcon: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elderly.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${elderly.age} anos • ${elderly.city}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Necessidades: ${elderly.careNeeds}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local: ${elderly.location} • Horário: ${elderly.preferredTime}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _viewElderlyProfile(elderly),
                          child: const Text('Ver Perfil'),
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

  Future<void> _viewElderlyProfile(ElderlyUser elderly) async {
    // Recarregar dados antes de abrir o perfil para garantir informações atualizadas
    try {
      await _authService.getAvailableElderlies();
    } catch (e) {
      print('⚠️ Erro ao recarregar idosos: $e');
    }
    
    // Buscar o idoso atualizado na lista
    final updatedElderlies = await _authService.getAvailableElderlies();
    final updatedElderly = updatedElderlies.where((e) => e.id == elderly.id).firstOrNull;
    
    if (updatedElderly == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil não encontrado')),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElderlyProfileScreen(elderly: updatedElderly),
      ),
    );

    // Se retornar com resultado positivo (match criado), atualizar a lista
    if (result == true || mounted) {
      _loadAvailableElderlies();
    }
  }
}