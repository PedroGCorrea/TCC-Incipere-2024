import 'package:flutter/material.dart';
import 'package:incipere/config/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/messenger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

    Future<void> checkRegistrationStep(BuildContext context) async {
      /*final prefs = await SharedPreferences.getInstance();
      final registerStep = prefs.getInt('registering') ?? false;

      switch (registerStep) {
        case 1:
          Navigator.pushNamed(context, AppRoutes.register2);
          break;
        case 2:
          Navigator.pushNamed(context, AppRoutes.register3);
          break;
        case 3:
          Navigator.pushNamed(context, AppRoutes.register4);
          break;
        case 4:
          Navigator.pushNamed(context, AppRoutes.welcome);
          break;
        default:
          */Navigator.pushNamed(context, AppRoutes.register);/*
      }*/
    }

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  // Função para autenticar o usuário
  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Messenger.showError(context,'Preencha todos os campos');
      return;
    }

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        Messenger.showSuccess(context,'Login realizado com sucesso!');
        // Redirecione para a tela principal (HomeScreen, por exemplo)

        final user = supabase.auth.currentUser;
        final profileResponse = await supabase
          .from('user_profiles')
          .select('profile_image_path')
          .eq('user_id', user!.id)
          .maybeSingle();

        if (profileResponse != null) {
          final imagePath = profileResponse['profile_image_path'];
          if (imagePath != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profile_image_path', imagePath);
          }
        }

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Messenger.showError(context,'Credenciais inválidas.');
      }
    } catch (error) {
      Messenger.showError(context,'Erro ao autenticar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de texto para e-mail
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),

            // Campo de texto para senha
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),

            // Botão "Entrar"
            ElevatedButton(
              onPressed: login,
              child: Text('Entrar'),
            ),

            // Botão "Esqueci minha senha"
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.forgotPassword);
              },
              child: Text('Esqueci minha senha'),
            ),
            SizedBox(height: 16),

            // Botão "Entrar com o Google"
            OutlinedButton.icon(
              onPressed: () {
                // Implementação futura
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Autenticação com Google será implementada em breve.'),
                  ),
                );
              },
              icon: Icon(Icons.login),
              label: Text('Entrar com o Google'),
            ),
            SizedBox(height: 16),

            // Botão "Criar uma conta"
            TextButton(
              onPressed: () {
                checkRegistrationStep(context);
              },
              child: Text('Criar uma conta'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
