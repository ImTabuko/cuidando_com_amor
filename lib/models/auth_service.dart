import 'user.dart';
import '../services/data_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final DataService _dataService = DataService();

  AuthService._internal();

  User? get currentUser => _dataService.currentUser;
  bool get isLoggedIn => _dataService.currentUser != null;

  Future<bool> login(String emailOrPhone, String password) async {
    return _dataService.login(emailOrPhone, password);
  }

  Future<bool> loginByPhone(String phone, String password) async {
    return _dataService.loginByPhone(phone, password);
  }

  Future<bool> registerElderly({
    required String fullName,
    required String street,
    required String neighborhood,
    required String city,
    required String state,
    String? email, // Email opcional para idosos
    required String cpf,
    required String password,
    required String phone,
    required DateTime birthDate,
    required String careNeeds,
    required String location,
    required String preferredTime,
    String? photoUrl,
  }) async {
    return _dataService.registerElderly(
      fullName: fullName,
      street: street,
      neighborhood: neighborhood,
      city: city,
      state: state,
      email: email,
      cpf: cpf,
      password: password,
      phone: phone,
      birthDate: birthDate,
      careNeeds: careNeeds,
      location: location,
      preferredTime: preferredTime,
      photoUrl: photoUrl,
    );
  }

  Future<bool> registerCaregiver({
    required String fullName,
    required String street,
    required String neighborhood,
    required String city,
    required String state,
    required String email,
    required String cpf,
    required String password,
    required String phone,
    required DateTime birthDate,
    required String description,
    String? photoUrl,
  }) async {
    return _dataService.registerCaregiver(
      fullName: fullName,
      street: street,
      neighborhood: neighborhood,
      city: city,
      state: state,
      email: email,
      cpf: cpf,
      password: password,
      phone: phone,
      birthDate: birthDate,
      description: description,
      photoUrl: photoUrl,
    );
  }

  Future<List<CaregiverUser>> getAvailableCaregivers() async {
    return _dataService.getAvailableCaregivers();
  }

  Future<List<ElderlyUser>> getAvailableElderlies() async {
    return _dataService.getAvailableElderlies();
  }

  Future<void> updateUser(User user) async {
    // Implementar atualização se necessário
  }

  void logout() {
    _dataService.logout();
  }
}