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
  bool _isLargeTextEnabled = false;

  @override
  void initState() {
    super.initState();
    _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    _accessibilityService.addListener(_updateState);
    _tabController = TabController(length: 3, vsync: this);
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {
      _isLargeTextEnabled = _accessibilityService.isLargeTextEnabled;
    });
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _matches = await _matchService.getMatchesForCurrentUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar matches: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
    );
  }

  Widget _buildMatchList(MatchStatus status) {
    final filteredMatches = _matches.where((match) => match.status == status).toList();

    if (filteredMatches.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: EdgeInsets.all(_accessibilityService.largeSpacing),
        itemCount: filteredMatches.length,
        itemBuilder: (context, index) {
          final match = filteredMatches[index];
          return FutureBuilder<Widget>(
            future: _buildMatchCard(match),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(child: ListTile(title: Text('Carregando...')));
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
            onPressed: _loadMatches,
            child: ButtonText('Atualizar'),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildMatchCard(Match match) async {
    final currentUser = _authService.currentUser;
    final isElderly = currentUser is ElderlyUser;
    
    // Encontrar o outro usuário no match
    User? otherUser;
    if (isElderly) {
      otherUser = await _matchService.getUserById(match.caregiverId);
    } else {
      otherUser = await _matchService.getUserById(match.elderlyId);
    }

    if (otherUser == null) {
      return const SizedBox.shrink();
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
    final isElderly = currentUser is ElderlyUser;
    
    // Determinar se o usuário atual criou o match ou recebeu
    final isMatchCreator = (isElderly && match.elderlyId == currentUser?.id) ||
                          (!isElderly && match.caregiverId == currentUser?.id);
    
    // Para matches pendentes
    if (match.status == MatchStatus.pending) {
      if (isMatchCreator) {
        // Se o usuário criou o match, mostrar apenas "Ver Perfil" e status
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
        // Se o usuário recebeu o match, mostrar botões de aceitar/rejeitar
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

  Future<void> _acceptMatch(Match match) async {
    try {
      await _matchService.acceptMatch(match.matchId);
      _loadMatches();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match aceito com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectMatch(Match match) async {
    try {
      await _matchService.rejectMatch(match.matchId);
      _loadMatches();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match rejeitado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
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