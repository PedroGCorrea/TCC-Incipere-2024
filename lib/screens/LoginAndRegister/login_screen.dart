import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:incipere/config/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/messenger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

//login com google configurado para porta 58565

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
              onPressed: () async {
                try {
                  await googleLogin(context);
                  // Redirecionar ou realizar outra ação após o login
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
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

  Future<void> googleLogin(BuildContext context) async {
    try {

      // Login com Google
      if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Web, macOS, Windows, Linux
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          authScreenLaunchMode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      } else if (Platform.isAndroid || Platform.isIOS) {
        // iOS e Android
        const webClientId = '1004314503008-0qvm1u2c12g4cpp1i60fqa07alq1cgqa.apps.googleusercontent.com';
        const iosClientId = '1004314503008-q2vi3qd9h2clo61l29hvobrv3eu8lnk8.apps.googleusercontent.com';

        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? iosClientId : null,
          serverClientId: webClientId,
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw 'Usuário cancelou o login com Google.';
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null || accessToken == null) {
          throw 'Tokens não encontrados.';
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } else {
        throw UnsupportedError('Plataforma não suportada para login com Google.');
      }
    } catch (e) {
      debugPrint('Erro ao fazer login com Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
    }
  }
}