import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/match_service.dart';
import '../models/auth_service.dart';
import '../services/accessibility_service.dart';
import '../widgets/accessible_text.dart';
import 'elderly_profile_screen.dart';
import 'caregiver_profile_screen.dart';
import '../utils/app_colors.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  final AuthService _authService = AuthService();
  final AccessibilityService _accessibilityService = AccessibilityService();
  late TabController _tabController;
  List<Match> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches({bool reload = false}) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Garantir que os dados estão carregados
      if (reload) {
        // Recarregar usuários primeiro para garantir que temos os dados atualizados
        await _matchService.dataService.reloadUsersFromApi();
        // Recarregar matches do servidor
        await _matchService.dataService.reloadMatchesFromApi();
      }
      
      // Obter matches do usuário atual (não recarregar novamente se já recarregamos acima)
      _matches = await _matchService.getMatchesForCurrentUser(reload: false);
      
      // Debug: verificar matches encontrados
      print('📊 Matches encontrados: ${_matches.length}');
      for (var match in _matches) {
        print('  - Match ID: ${match.matchId}, Elderly: ${match.elderlyId}, Caregiver: ${match.caregiverId}, Status: ${match.status}');
      }
    } catch (e) {
      print('❌ Erro ao carregar matches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar matches: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Desabilita botão de voltar do Android
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        title: TitleText('Meus Matches', color: Colors.white),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontSize: _accessibilityService.buttonTextSize,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: _accessibilityService.buttonTextSize,
          ),
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aceitos'),
            Tab(text: 'Rejeitados'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchList(MatchStatus.pending),
                _buildMatchList(MatchStatus.accepted),
                _buildMatchList(MatchStatus.rejected),
              ],
            ),
      ),
    );
  }

  Widget _buildMatchList(MatchStatus status) {
    final filteredMatches = _matches.where((match) => match.status == status).toList();

    if (filteredMatches.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: () => _loadMatches(reload: true),
      child: ListView.builder(
        padding: EdgeInsets.all(_accessibilityService.largeSpacing),
        itemCount: filteredMatches.length,
        itemBuilder: (context, index) {
          final match = filteredMatches[index];
          return FutureBuilder<Widget>(
            future: _buildMatchCard(match),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Card(
                  margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
                  child: ListTile(
                    leading: const CircularProgressIndicator(),
                    title: const Text('Carregando...'),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
                  child: ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: Text('Erro: ${snapshot.error}'),
                  ),
                );
              }
              return snapshot.data ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(MatchStatus status) {
    String message;
    switch (status) {
      case MatchStatus.pending:
        message = 'Nenhum match pendente';
        break;
      case MatchStatus.accepted:
        message = 'Nenhum match aceito';
        break;
      case MatchStatus.rejected:
        message = 'Nenhum match rejeitado';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: _accessibilityService.isLargeTextEnabled ? 100 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: _accessibilityService.defaultSpacing),
          TitleText(
            message,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _accessibilityService.largeSpacing),
          ElevatedButton(
            onPressed: () => _loadMatches(reload: true),
            child: ButtonText('Atualizar'),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildMatchCard(Match match) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    
    final isElderly = currentUser is ElderlyUser;
    
    // Encontrar o outro usuário no match
    User? otherUser;
    try {
      // Garantir que os usuários estão carregados
      await _matchService.dataService.reloadUsersFromApi();
      
      if (isElderly) {
        otherUser = _matchService.getUserById(match.caregiverId);
        print('🔍 Buscando cuidador ID: ${match.caregiverId}');
      } else {
        otherUser = _matchService.getUserById(match.elderlyId);
        print('🔍 Buscando idoso ID: ${match.elderlyId}');
      }
      
      if (otherUser == null) {
        print('⚠️ Usuário não encontrado! IDs disponíveis:');
        final allUsers = _matchService.dataService.allUsers;
        for (var user in allUsers) {
          print('  - ${user.id}: ${user.fullName}');
        }
      }
    } catch (e) {
      print('❌ Erro ao buscar usuário: $e');
      return Card(
        child: Padding(
          padding: EdgeInsets.all(_accessibilityService.largeSpacing),
          child: BodyText('Erro ao carregar informações do match: $e'),
        ),
      );
    }

    if (otherUser == null) {
      return Card(
        margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
        child: Padding(
          padding: EdgeInsets.all(_accessibilityService.largeSpacing),
          child: Column(
            children: [
              BodyText('Usuário não encontrado'),
              SizedBox(height: _accessibilityService.smallSpacing),
              HintText('Match ID: ${match.matchId}'),
              HintText('Elderly ID: ${match.elderlyId}'),
              HintText('Caregiver ID: ${match.caregiverId}'),
            ],
          ),
        ),
      );
    }

    final name = otherUser.fullName;
    final role = isElderly ? 'Cuidador' : 'Idoso';
    final city = otherUser.city;

    return Card(
      margin: EdgeInsets.only(bottom: _accessibilityService.defaultSpacing),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(_accessibilityService.largeSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: _accessibilityService.isLargeTextEnabled ? 40 : 30,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: _accessibilityService.isLargeTextEnabled ? 40 : 30,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(width: _accessibilityService.defaultSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleText(
                        name,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: _accessibilityService.smallSpacing / 2),
                      BodyText(
                        '$role • $city',
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: _accessibilityService.smallSpacing),
                      HintText(
                        'Match criado em: ${_formatDate(match.dataMatch)}',
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: _accessibilityService.defaultSpacing),
            _buildMatchActions(match, otherUser),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchActions(Match match, User otherUser) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    
    final isElderly = currentUser is ElderlyUser;
    final isCaregiver = currentUser is CaregiverUser;
    
    // Determinar se o usuário atual pode aceitar/rejeitar o match
    // Lógica: O match é criado por um cuidador oferecendo cuidados
    // Então o idoso (elderlyId) é quem pode aceitar/rejeitar
    // O cuidador (caregiverId) NUNCA pode aceitar - apenas aguarda a resposta
    // Verificação rigorosa: apenas idoso que recebeu o match pode aceitar
    // IMPORTANTE: O cuidador que criou o match (caregiverId) NUNCA pode aceitar
    
    // Verificar se o usuário atual é o idoso que recebeu o match
    final isElderlyRecipient = isElderly && match.elderlyId == currentUser.id;
    
    // Verificar se o usuário atual é o cuidador que criou o match
    final isCaregiverCreator = isCaregiver && match.caregiverId == currentUser.id;
    
    // Só pode aceitar se for o idoso que recebeu E NÃO for o cuidador que criou
    // Isso garante que mesmo que por algum motivo o ID esteja errado, o cuidador nunca pode aceitar
    final canAcceptMatch = isElderlyRecipient && !isCaregiverCreator;
    
    // Debug
    print('🔍 Match ${match.matchId}:');
    print('  - Current User ID: ${currentUser.id}');
    print('  - Is Elderly: $isElderly, Is Caregiver: $isCaregiver');
    print('  - Elderly ID: ${match.elderlyId}, Caregiver ID: ${match.caregiverId}');
    print('  - Is Elderly Recipient: $isElderlyRecipient');
    print('  - Is Caregiver Creator: $isCaregiverCreator');
    print('  - Can Accept: $canAcceptMatch');
    
    // Para matches pendentes
    if (match.status == MatchStatus.pending) {
      if (!canAcceptMatch) {
        // Se o usuário não pode aceitar (criou o match), mostrar apenas "Ver Perfil" e status
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _accessibilityService.defaultSpacing,
                vertical: _accessibilityService.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: BodyText(
                'Aguardando resposta',
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewProfile(otherUser),
                icon: const Icon(Icons.person, size: 18),
                label: const ButtonText('Ver Perfil', color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        );
      } else {
        // Se o usuário pode aceitar/rejeitar (recebeu o match), mostrar botões
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => _viewProfile(otherUser),
              icon: const Icon(Icons.person, size: 18),
              label: const ButtonText('Ver Perfil', color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: _accessibilityService.smallSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptMatch(match),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const ButtonText('Aceitar', color: Colors.white),
                  ),
                ),
                SizedBox(width: _accessibilityService.smallSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectMatch(match),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const ButtonText('Rejeitar', color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    }
    
    // Para matches aceitos ou rejeitados, mostrar apenas botão de ver perfil
    return ElevatedButton.icon(
      onPressed: () => _viewProfile(otherUser),
      icon: const Icon(Icons.person, size: 18),
      label: const ButtonText('Ver Perfil', color: Colors.white),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _updateMatchStatus(Match match, MatchStatus status, String successMessage) async {
    try {
      // Atualizar status do match
      if (status == MatchStatus.accepted) {
        await _matchService.acceptMatch(match.matchId);
      } else {
        await _matchService.rejectMatch(match.matchId);
      }
      
      // Recarregar matches com reload=true para garantir sincronização
      await _loadMatches(reload: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao atualizar status do match: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _acceptMatch(Match match) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado')),
        );
      }
      return;
    }
    
    // Verificação de segurança RIGOROSA: apenas o idoso que recebeu o match pode aceitar
    final isElderly = currentUser is ElderlyUser;
    final isCaregiver = currentUser is CaregiverUser;
    
    // Verificar se é o idoso que recebeu o match
    final isElderlyRecipient = isElderly && match.elderlyId == currentUser.id;
    
    // Verificar se é o cuidador que criou o match (NUNCA pode aceitar)
    final isCaregiverCreator = isCaregiver && match.caregiverId == currentUser.id;
    
    // Só pode aceitar se for o idoso que recebeu E não for o cuidador que criou
    final canAccept = isElderlyRecipient && !isCaregiverCreator;
    
    print('🔐 Tentativa de aceitar match ${match.matchId}:');
    print('  - User ID: ${currentUser.id}');
    print('  - Is Elderly: $isElderly, Is Caregiver: $isCaregiver');
    print('  - Elderly ID: ${match.elderlyId}, Caregiver ID: ${match.caregiverId}');
    print('  - Is Elderly Recipient: $isElderlyRecipient');
    print('  - Is Caregiver Creator: $isCaregiverCreator');
    print('  - Can Accept: $canAccept');
    
    if (!canAccept) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não pode aceitar este match. Apenas o idoso que recebeu o match pode aceitá-lo.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    await _updateMatchStatus(match, MatchStatus.accepted, 'Match aceito com sucesso!');
  }

  Future<void> _rejectMatch(Match match) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado')),
        );
      }
      return;
    }
    
    // Verificação de segurança RIGOROSA: apenas o idoso que recebeu o match pode rejeitar
    final isElderly = currentUser is ElderlyUser;
    final isCaregiver = currentUser is CaregiverUser;
    
    // Verificar se é o idoso que recebeu o match
    final isElderlyRecipient = isElderly && match.elderlyId == currentUser.id;
    
    // Verificar se é o cuidador que criou o match (NUNCA pode rejeitar)
    final isCaregiverCreator = isCaregiver && match.caregiverId == currentUser.id;
    
    // Só pode rejeitar se for o idoso que recebeu E não for o cuidador que criou
    final canReject = isElderlyRecipient && !isCaregiverCreator;
    
    if (!canReject) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apenas o idoso que recebeu o match pode rejeitá-lo')),
        );
      }
      return;
    }
    
    await _updateMatchStatus(match, MatchStatus.rejected, 'Match rejeitado');
  }

  Future<void> _viewProfile(User user) async {
    if (user is ElderlyUser) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ElderlyProfileScreen(elderly: user),
        ),
      );
    } else if (user is CaregiverUser) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaregiverProfileScreen(caregiver: user),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}