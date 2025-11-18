enum UserType { elderly, caregiver }

abstract class User {
  final String id;
  final String fullName;
  final String street; // Rua
  final String neighborhood; // Bairro
  final String city; // Cidade
  final String state; // Estado
  final UserType userType;
  String? photoUrl; // Não final para permitir atualização

  User({
    required this.id,
    required this.fullName,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.userType,
    this.photoUrl,
  });
  
  // Getter para endereço completo
  String get fullAddress => '$street, $neighborhood, $city - $state';
}

class ElderlyUser extends User {
  final String cpf;
  final String? email; // Email opcional para idosos
  final String password;
  final String phone;
  final DateTime birthDate;
  final String careNeeds;
  final String location; // 'Casa' ou 'Hospital'
  final String preferredTime; // 'Manhã', 'Tarde' ou 'Noite'
  @override
  String? photoUrl;

  ElderlyUser({
    required super.id,
    required super.fullName,
    required super.street,
    required super.neighborhood,
    required super.city,
    required super.state,
    required this.cpf,
    this.email, // Email opcional
    required this.password,
    required this.phone,
    required this.birthDate,
    required this.careNeeds,
    required this.location,
    required this.preferredTime,
    this.photoUrl,
  }) : super(userType: UserType.elderly, photoUrl: photoUrl);
  
  // Calcular idade com base na data de nascimento
  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

class CaregiverUser extends User {
  final String email;
  final String cpf;
  final String password;
  final String phone;
  final String description;
  final DateTime birthDate;
  @override
  String? photoUrl;

  CaregiverUser({
    required super.id,
    required super.fullName,
    required super.street,
    required super.neighborhood,
    required super.city,
    required super.state,
    required this.email,
    required this.cpf,
    required this.password,
    required this.phone,
    required this.description,
    required this.birthDate,
    this.photoUrl,
  }) : super(userType: UserType.caregiver, photoUrl: photoUrl);
  
  // Calcular idade com base na data de nascimento
  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}



