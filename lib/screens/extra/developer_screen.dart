import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Certifique-se de ter o pacote supabase_flutter instalado
import '../../config/app_routes.dart';
import '../../widgets/main_bar.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  _DeveloperScreenState createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final List<Map<String, String>> routes = [
    {'name': 'Login', 'route': AppRoutes.login},
    {'name': 'Register', 'route': AppRoutes.register},
    {'name': 'Register 2', 'route': AppRoutes.register2},
    {'name': 'Register 3', 'route': AppRoutes.register3},
    {'name': 'Register 4', 'route': AppRoutes.register4},
    {'name': 'Welcome', 'route': AppRoutes.welcome},
    {'name': 'Forgot Password', 'route': AppRoutes.forgotPassword},
    {'name': 'Reset Password', 'route': AppRoutes.resetPassword},
    {'name': 'Home', 'route': AppRoutes.home},
    {'name': 'Profile', 'route': AppRoutes.profile},
    {'name': 'Settings', 'route': AppRoutes.settings},
    {'name': 'Community Events', 'route': AppRoutes.communityEvents},
    {'name': 'Subscribed Events', 'route': AppRoutes.subscribedEvents},
  ];

  Future<void> _authenticateAutomatically() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: 'igorrichard13@hotmail.com',
        password: '123456',
      );

      if (response.session != null) {
        // Login bem-sucedido, redireciona para a tela inicial
        Navigator.pushNamed(context, AppRoutes.developer);
      } else if (response.user == null) {
        // Exibe erro se houver
        _showErrorDialog('Erro ao autenticar: $response');
      }
    } catch (e) {
      _showErrorDialog('Erro ao autenticar: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: Column(
        children: [
          // Botão para autenticação automática
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _authenticateAutomatically,
              child: Text('Autenticar Automaticamente'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return ListTile(
                  title: Text(route['name']!),
                  onTap: () => Navigator.pushNamed(context, route['route']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
