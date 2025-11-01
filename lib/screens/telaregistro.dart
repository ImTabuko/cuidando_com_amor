import 'package:flutter/material.dart';
import 'dart:io';
import '../models/auth_service.dart';
import '../models/user.dart';
import '../widgets/custom_text_field.dart';
import '../services/accessibility_service.dart';
import '../services/photo_service.dart';
import '../services/ibge_service.dart';
import '../services/cep_service.dart';
import '../widgets/accessible_text.dart';
import '../utils/app_colors.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AccessibilityService _accessibilityService = AccessibilityService();
  final PhotoService _photoService = PhotoService();
  UserType _selectedUserType = UserType.elderly;
  bool _isLoading = false;
  File? _selectedPhoto;

  // Controllers para campos comuns
  final _fullNameController = TextEditingController();
  final _cepController = TextEditingController(); // CEP
  final _streetController = TextEditingController(); // Rua
  final _neighborhoodController = TextEditingController(); // Bairro
  String? _selectedState;
  String? _selectedCity;
  
  // Estados e cidades
  List<Map<String, String>> _states = [];
  List<String> _cities = [];
  bool _isLoadingStates = false;

  // Controllers para campos específicos do idoso
  final _elderlyCpfController = TextEditingController();
  final _elderlyEmailController = TextEditingController(); // Opcional para idosos
  final _elderlyPasswordController = TextEditingController();
  final _elderlyPhoneController = TextEditingController();
  DateTime _elderlyBirthDate =
      DateTime(DateTime.now().year - 60, 1, 1); // Data padrão (60 anos atrás)
  List<String> _selectedCareNeeds = [];
  String _selectedLocation = 'Casa';
  String _selectedSchedule = 'Manhã';

  // Controllers para campos específicos do cuidador
  final _caregiverEmailController = TextEditingController();
  final _caregiverCpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime _caregiverBirthDate =
      DateTime(DateTime.now().year - 25, 1, 1); // Data padrão (25 anos atrás)
  List<String> _selectedFormations = [];

  @override
  void initState() {
    super.initState();
    _accessibilityService.addListener(_updateState);
    _loadStates();
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
    });
    
    final states = await IBGEService.getStates();
    setState(() {
      _states = states;
      _isLoadingStates = false;
    });
  }

  Future<void> _loadCities(String stateCode) async {
    setState(() {
      _cities = [];
      _selectedCity = null;
    });
    
    final cities = await IBGEService.getCitiesByState(stateCode);
    setState(() {
      _cities = cities;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _elderlyCpfController.dispose();
    _elderlyEmailController.dispose();
    _elderlyPasswordController.dispose();
    _elderlyPhoneController.dispose();
    _caregiverEmailController.dispose();
    _caregiverCpfController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _accessibilityService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  Future<void> _searchCEP() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CEP inválido')),
      );
      return;
    }

    final address = await CEPService.getAddressByCEP(_cepController.text);
    if (address.isNotEmpty) {
      setState(() {
        _streetController.text = address['street'] ?? '';
        _neighborhoodController.text = address['neighborhood'] ?? '';
        _selectedCity = address['city'] ?? '';
        _selectedState = address['state'] ?? '';
        
        // Carregar cidades do estado selecionado
        if (_selectedState != null) {
          _loadCities(_selectedState!);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Endereço preenchido automaticamente!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CEP não encontrado')),
      );
    }
  }

  Future<void> _selectPhoto() async {
    final photo = await _photoService.showImageSourceDialog(context);
    if (photo != null) {
      setState(() {
        _selectedPhoto = photo;
      });
    }
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();

        if (_selectedUserType == UserType.elderly) {
          // Verificar se o telefone foi preenchido (obrigatório para idosos)
          if (_elderlyPhoneController.text.isEmpty) {
            throw Exception('O telefone é obrigatório para idosos');
          }
          
          await authService.registerElderly(
            fullName: _fullNameController.text,
            street: _streetController.text,
            neighborhood: _neighborhoodController.text,
            city: _selectedCity ?? '',
            state: _selectedState ?? '',
            email: _elderlyEmailController.text.isEmpty ? null : _elderlyEmailController.text,
            cpf: _elderlyCpfController.text,
            password: _elderlyPasswordController.text,
            phone: _elderlyPhoneController.text,
            birthDate: _elderlyBirthDate,
            careNeeds: _selectedCareNeeds.join(', '),
            location: _selectedLocation,
            preferredTime: _selectedSchedule,
            photoUrl: _selectedPhoto?.path,
          );
        } else {
          // Verificar se o telefone foi preenchido (obrigatório para cuidadores)
          if (_phoneController.text.isEmpty) {
            throw Exception('O telefone é obrigatório para cuidadores');
          }
          
          await authService.registerCaregiver(
            fullName: _fullNameController.text,
            street: _streetController.text,
            neighborhood: _neighborhoodController.text,
            city: _selectedCity ?? '',
            state: _selectedState ?? '',
            email: _caregiverEmailController.text,
            cpf: _caregiverCpfController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            birthDate: _caregiverBirthDate,
            description: _selectedFormations.join(', '),
            photoUrl: _selectedPhoto?.path,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedUserType == UserType.elderly
                    ? 'Idoso registrado com sucesso!'
                    : 'Cuidador registrado com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TitleText('Cadastro', color: Colors.white),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(_accessibilityService.largeSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitleText(
                'Escolha o tipo de conta:',
                color: Colors.black87,
              ),
              SizedBox(height: _accessibilityService.defaultSpacing),
              Row(
                children: [
                  Expanded(
                    child: _buildUserTypeButton(
                      UserType.elderly,
                      'Idoso',
                      Icons.elderly,
                      'Cliente que precisa de cuidados',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUserTypeButton(
                      UserType.caregiver,
                      'Cuidador',
                      Icons.medical_services,
                      'Profissional de cuidados',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Foto de perfil - Posicionada logo após tipo de usuário
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
                  child: Column(
                    children: [
                      BodyText(
                        'Foto de Perfil',
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: _accessibilityService.smallSpacing),
                      GestureDetector(
                        onTap: _selectPhoto,
                        child: _photoService.buildProfilePhoto(
                          photoUrl: _selectedPhoto?.path,
                          radius: _accessibilityService.isLargeTextEnabled ? 60 : 50,
                          onTap: _selectPhoto,
                          showEditIcon: true,
                        ),
                      ),
                      SizedBox(height: _accessibilityService.smallSpacing),
                      BodyText(
                        _selectedPhoto != null 
                          ? 'Foto selecionada' 
                          : 'Toque para adicionar foto',
                        color: Colors.grey[600],
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: _accessibilityService.defaultSpacing),
              
              CustomTextField(
                controller: _fullNameController,
                label: 'Nome Completo',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome completo';
                  }
                  return null;
                },
              ),
              SizedBox(height: _accessibilityService.defaultSpacing),
              
              if (_selectedUserType == UserType.elderly) ...[
                _buildElderlyFields(),
              ] else ...[
                _buildCaregiverFields(),
              ],
              SizedBox(height: _accessibilityService.largeSpacing),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: _accessibilityService.defaultSpacing,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: _accessibilityService.iconSize,
                        width: _accessibilityService.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : ButtonText(
                        'Completar Cadastro',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(
    UserType userType,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedUserType == userType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = userType;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryShade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: _accessibilityService.isLargeTextEnabled ? 50 : 40,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            SizedBox(height: _accessibilityService.smallSpacing),
            BodyText(
              title,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : Colors.grey.shade700,
            ),
            SizedBox(height: _accessibilityService.smallSpacing / 2),
            HintText(
              subtitle,
              color: isSelected ? AppColors.primaryShade700 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElderlyFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _elderlyCpfController,
          label: 'CPF (Apenas Números)',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira seu CPF';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // CEP
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _cepController,
                label: 'CEP',
                icon: Icons.pin,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe seu CEP';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: _accessibilityService.defaultSpacing),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _searchCEP,
                icon: Icon(Icons.search, size: 18),
                label: Text('Buscar', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Estado
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            labelText: 'Estado',
            prefixIcon: const Icon(Icons.map, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _states.map((state) {
            return DropdownMenuItem<String>(
              value: state['sigla'],
              child: Text(state['nome']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null;
            });
            if (value != null) {
              _loadCities(value);
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor, selecione seu estado';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Cidade
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'Cidade',
            prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _cities
              .map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor, selecione sua cidade';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Rua
        CustomTextField(
          controller: _streetController,
          label: 'Rua',
          icon: Icons.home,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe sua rua';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Bairro
        CustomTextField(
          controller: _neighborhoodController,
          label: 'Bairro',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu bairro';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Removidos campos duplicados de Estado, Cidade e Bairro
        CustomTextField(
          controller: _elderlyEmailController,
          label: 'Email (Opcional)',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty && !value.contains('@')) {
              return 'Por favor, insira um email válido';
            }
            return null;
          },
          hintText: 'Seu endereço de email',
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        CustomTextField(
          controller: _elderlyPhoneController,
          label: 'Telefone (Obrigatório)',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira seu telefone';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        CustomTextField(
          controller: _elderlyPasswordController,
          label: 'Senha',
          icon: Icons.lock,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira sua senha';
            }
            if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabelText(
              'Data de Nascimento:',
              color: Colors.black87,
            ),
            SizedBox(height: _accessibilityService.smallSpacing),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Text(
                    '${_elderlyBirthDate.day.toString().padLeft(2, '0')}/${_elderlyBirthDate.month.toString().padLeft(2, '0')}/${_elderlyBirthDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _elderlyBirthDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(DateTime.now().year - 60, 12, 31),
                        helpText: 'Selecione sua data de nascimento',
                      );
                      if (picked != null && picked != _elderlyBirthDate) {
                        setState(() {
                          _elderlyBirthDate = picked;
                        });
                      }
                    },
                    child: ButtonText('Selecionar'),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        LabelText(
          'Necessidades de Cuidado:',
          color: Colors.black87,
        ),
        SizedBox(height: _accessibilityService.smallSpacing),
        _buildCareNeedsSelector(),
        SizedBox(height: _accessibilityService.defaultSpacing),
        LabelText(
          'Localização:',
          color: Colors.black87,
        ),
        SizedBox(height: _accessibilityService.smallSpacing),
        Row(
          children: ['Casa', 'Hospital'].map((location) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedLocation == location
                        ? AppColors.primaryShade50
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: _selectedLocation == location
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: _selectedLocation == location ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedLocation == location
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _selectedLocation == location
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        location,
                        style: TextStyle(
                          color: _selectedLocation == location
                              ? AppColors.primary
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        LabelText(
          'Horário Preferido:',
          color: Colors.black87,
        ),
        SizedBox(height: _accessibilityService.smallSpacing),
        Row(
          children: ['Manhã', 'Tarde', 'Noite'].map((schedule) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSchedule = schedule;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _selectedSchedule == schedule
                        ? AppColors.primaryShade50
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: _selectedSchedule == schedule
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: _selectedSchedule == schedule ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedSchedule == schedule
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: _selectedSchedule == schedule
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      BodyText(
                        schedule,
                        fontWeight: FontWeight.bold,
                        color: _selectedSchedule == schedule
                            ? AppColors.primary
                            : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCaregiverFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _caregiverCpfController,
          label: 'CPF (Apenas Números)',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira seu CPF';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // CEP (também para cuidador)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _cepController,
                label: 'CEP',
                icon: Icons.pin,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe seu CEP';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: _accessibilityService.defaultSpacing),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _searchCEP,
                icon: Icon(Icons.search, size: 18),
                label: Text('Buscar', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Rua
        CustomTextField(
          controller: _streetController,
          label: 'Rua',
          icon: Icons.home,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe sua rua';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Bairro
        CustomTextField(
          controller: _neighborhoodController,
          label: 'Bairro',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu bairro';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        // Estado
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(
            labelText: 'Estado',
            prefixIcon: const Icon(Icons.map, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _states.map((state) {
            return DropdownMenuItem<String>(
              value: state['sigla'],
              child: Text(state['nome']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _selectedCity = null; // Reset cidade quando muda estado
            });
            if (value != null) {
              _loadCities(value);
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor, selecione seu estado';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        
        // Cidade
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: InputDecoration(
            labelText: 'Cidade',
            prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _cities
              .map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Por favor, selecione sua cidade';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        CustomTextField(
          controller: _caregiverEmailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira seu email';
            }
            if (!value.contains('@')) {
              return 'Por favor, insira um email válido';
            }
            return null;
          },
          hintText: 'Seu endereço de email',
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        CustomTextField(
          controller: _phoneController,
          label: 'Telefone (Obrigatório)',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira seu telefone';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        CustomTextField(
          controller: _passwordController,
          label: 'Senha',
          icon: Icons.lock,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira sua senha';
            }
            if (value.length < 6) {
              return 'A senha deve ter pelo menos 6 caracteres';
            }
            return null;
          },
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabelText(
              'Data de Nascimento:',
              color: Colors.black87,
            ),
            SizedBox(height: _accessibilityService.smallSpacing),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Text(
                    '${_caregiverBirthDate.day.toString().padLeft(2, '0')}/${_caregiverBirthDate.month.toString().padLeft(2, '0')}/${_caregiverBirthDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _caregiverBirthDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(DateTime.now().year - 18, 12, 31),
                        helpText: 'Selecione sua data de nascimento',
                      );
                      if (picked != null && picked != _caregiverBirthDate) {
                        setState(() {
                          _caregiverBirthDate = picked;
                        });
                      }
                    },
                    child: ButtonText('Selecionar'),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: _accessibilityService.defaultSpacing),
        LabelText(
          'Formação e Experiência:',
          color: Colors.black87,
        ),
        SizedBox(height: _accessibilityService.smallSpacing),
        _buildFormationSelector(),
      ],
    );
  }

  Widget _buildCareNeedsSelector() {
    final careNeedsOptions = [
      'Acompanhamento médico',
      'Cuidados pessoais (banho, higiene)',
      'Auxílio na locomoção',
      'Medicação e controle de remédios',
      'Acompanhamento em consultas',
      'Cuidados domésticos básicos',
      'Companhia e conversa',
      'Auxílio com alimentação',
      'Cuidados com diabetes',
      'Cuidados com pressão alta',
      'Fisioterapia domiciliar',
      'Outros cuidados específicos',
    ];

    return ExpansionTile(
      title: BodyText(
        'Selecione suas necessidades',
        fontWeight: FontWeight.bold,
      ),
      subtitle: HintText(
        _selectedCareNeeds.isEmpty 
          ? 'Nenhuma selecionada' 
          : '${_selectedCareNeeds.length} selecionada(s)',
      ),
      children: [
        Container(
          padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: careNeedsOptions.map((option) {
              return CheckboxListTile(
                title: BodyText(option),
                value: _selectedCareNeeds.contains(option),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCareNeeds.add(option);
                    } else {
                      _selectedCareNeeds.remove(option);
                    }
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFormationSelector() {
    final formationOptions = [
      'Técnico em Enfermagem',
      'Auxiliar de Enfermagem',
      'Enfermeiro(a)',
      'Cuidador(a) de Idosos',
      'Técnico em Gerontologia',
      'Fisioterapeuta',
      'Terapeuta Ocupacional',
      'Nutricionista',
      'Psicólogo(a)',
      'Médico(a)',
      'Técnico em Saúde',
      'Experiência prática (sem formação formal)',
      'Outras formações',
    ];

    return ExpansionTile(
      title: BodyText(
        'Selecione suas formações',
        fontWeight: FontWeight.bold,
      ),
      subtitle: HintText(
        _selectedFormations.isEmpty 
          ? 'Nenhuma selecionada' 
          : '${_selectedFormations.length} selecionada(s)',
      ),
      children: [
        Container(
          padding: EdgeInsets.all(_accessibilityService.defaultSpacing),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: formationOptions.map((option) {
              return CheckboxListTile(
                title: BodyText(option),
                value: _selectedFormations.contains(option),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedFormations.add(option);
                    } else {
                      _selectedFormations.remove(option);
                    }
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
