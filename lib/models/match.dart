
enum MatchStatus {
  pending,   // Match pendente (ainda não visualizado)
  accepted,  // Match aceito
  rejected,  // Match rejeitado
}

enum MatchCreatedBy {
  elderly,   // Match criado por um idoso
  caregiver, // Match criado por um cuidador
}

class Match {
  final String matchId;
  final String elderlyId;
  final String caregiverId;
  MatchStatus status;
  final DateTime dataMatch;
  MatchCreatedBy? createdBy; // Quem criou o match
  
  Match({
    required this.matchId,
    required this.elderlyId,
    required this.caregiverId,
    this.status = MatchStatus.pending,
    required this.dataMatch,
    this.createdBy,
  });
  
  // Método para aceitar o match
  void accept() {
    status = MatchStatus.accepted;
  }
  
  // Método para rejeitar o match
  void reject() {
    status = MatchStatus.rejected;
  }
  
  // Método para verificar se o match está pendente
  bool isPending() {
    return status == MatchStatus.pending;
  }
  
  // Método para verificar se o match foi aceito
  bool isAccepted() {
    return status == MatchStatus.accepted;
  }
  
  // Método para verificar se o match foi rejeitado
  bool isRejected() {
    return status == MatchStatus.rejected;
  }
}