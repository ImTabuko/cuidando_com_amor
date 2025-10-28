# Cuidando com Amor

Uma aplicação Flutter para conectar idosos que precisam de cuidados com cuidadores profissionais.

## Funcionalidades


- Tela inicial com logo e nome do aplicativo
- Navegação automática para a tela de login após 3 segundos
- Design moderno com tema rosa e ícone de coração

### 🔐 Tela de Login
- Campos para usuário/email e senha
- Validação de formulário
- Botão para mostrar/ocultar senha
- Link para tela de registro
- Integração com serviço de autenticação simulado

### 📝 Tela de Registro
- Seleção entre dois tipos de usuário:
  - **Idoso (Cliente)**: Para quem precisa de cuidados
  - **Cuidador**: Para profissionais de cuidados

#### Campos para Idosos:
- Nome completo
- CPF
- Idade (mínimo 60 anos)
- Cidade
- Necessidades de cuidado
- Localização (Casa ou Hospital)
- Horário preferido (Manhã, Tarde ou Noite)
- Upload de foto (interface preparada)

#### Campos para Cuidadores:
- Nome completo
- Email
- Senha
- Cidade
- Telefone
- Descrição e experiência

## 🏗️ Arquitetura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada da aplicação
├── screens/                  # Telas da aplicação
│   ├── splash_screen.dart    # Tela de splash
│   ├── login_screen.dart     # Tela de login
│   └── registration_screen.dart # Tela de registro
├── widgets/                  # Widgets reutilizáveis
│   └── custom_text_field.dart # Campo de texto personalizado
└── models/                   # Modelos de dados
    ├── user.dart             # Classes de usuário
    └── auth_service.dart     # Serviço de autenticação
```

## 🎨 Design e UX

- **Tema**: Material Design 3 com cores rosa
- **Tipografia**: Hierarquia clara e legível
- **Formulários**: Validação em tempo real com mensagens de erro
- **Navegação**: Rotas nomeadas para fácil navegação
- **Responsividade**: Layout adaptável para diferentes tamanhos de tela

## 🚀 Como Executar

1. Certifique-se de ter o Flutter instalado
2. Clone o repositório
3. Execute `flutter pub get` para instalar as dependências
4. Execute `flutter run` para iniciar a aplicação

## 🔧 Tecnologias Utilizadas

- **Flutter**: Framework de desenvolvimento
- **Dart**: Linguagem de programação
- **Material Design**: Sistema de design
- **Named Routes**: Navegação entre telas
- **Form Validation**: Validação de formulários
- **State Management**: Gerenciamento de estado local

## 📱 Funcionalidades Futuras

- [ ] Integração com backend real
- [ ] Sistema de notificações
- [ ] Chat entre usuários
- [ ] Sistema de avaliações
- [ ] Filtros de busca para cuidadores
- [ ] Agendamento de consultas
- [ ] Histórico de cuidados
- [ ] Perfil de usuário completo


