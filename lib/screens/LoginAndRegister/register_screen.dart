import 'package:flutter/material.dart';
import 'package:incipere/config/app_routes.dart';
import 'package:incipere/services/userprovider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/messenger.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para criar a conta
  Future<void> createAccount() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Verificar campos obrigatórios
    if ([firstName, lastName, email, username, password, confirmPassword].contains('')) {
      Messenger.showError(context,'Todos os campos devem ser preenchidos.');
      return;
    }

    // Validar e-mail
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      Messenger.showError(context,'E-mail inválido.');
      return;
    }

    // Validar nome de usuário
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      Messenger.showError(context,'Nome de usuário inválido. Use apenas letras, números e underscores.');
      return;
    }

    // Verificar senhas
    if (password != confirmPassword) {
      Messenger.showError(context,'As senhas não coincidem.');
      return;
    }

    try {
      // Tenta criar o usuário
      final authResponse = await supabase.auth.signUp(email: email, password: password);
      final user = authResponse.user;

      // Verifica se o usuário foi criado com sucesso
      if (user == null) {
        Messenger.showError(context, 'Usuário não foi criado. Verifique as configurações do Supabase.');
        return;
      }

      final loginResponse = await supabase.auth.signInWithPassword(email: email, password: password);

      if (loginResponse.session == null) {
        Messenger.showError(context, 'Erro ao autenticar usuário após registro.');
        return;
      }

      // Obtém o userId
      final userId = user.id;

      // Insere dados adicionais na tabela `user_profiles`
      await supabase.from('user_profiles').upsert({
        'user_id': userId,
        'username': username,
        'full_name': '$firstName $lastName',
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUserData(
        userId: userId,
        username: username,
        fullName: '$firstName $lastName',
        email: email
      );

      /* // Salva o token da sessão, se disponível
      if (response.session != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('supabase_token', response.session!.accessToken);
        await prefs.setString('username', username);
        await prefs.setString('full_name', '$firstName $lastName');
      } */

      // Feedback de sucesso e navegação
      Messenger.showSuccess(context, 'Conta criada com sucesso!');
      //final prefs = await SharedPreferences.getInstance();
      //await prefs.setInt('registering', 2);
      Navigator.pushNamed(context, AppRoutes.register2); // Próxima tela
    } catch (error) {
      Messenger.showError(context, 'Erro inesperado ao criar conta: $error');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Conta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Botão Entrar com Google
            OutlinedButton.icon(
              onPressed: () {
                Messenger.showInfo(context, 'Autenticação com Google será implementada em breve.');
              },
              icon: Icon(Icons.login),
              label: Text('Entrar com o Google'),
            ),
            SizedBox(height: 16),

            // Campos de entrada
            _buildTextField(controller: _firstNameController, label: 'Primeiro Nome'),
            _buildTextField(controller: _lastNameController, label: 'Último Nome'),
            _buildTextField(controller: _emailController, label: 'E-mail', inputType: TextInputType.emailAddress),
            _buildTextField(controller: _usernameController, label: 'Nome de Usuário'),
            _buildTextField(controller: _passwordController, label: 'Senha', isPassword: true),
            _buildTextField(controller: _confirmPasswordController, label: 'Confirmar Senha', isPassword: true),
            SizedBox(height: 16),

            // Botões
            ElevatedButton(
              onPressed: createAccount,
              child: Text('Criar Conta'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: Text('Já tem uma conta? Log-in'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
