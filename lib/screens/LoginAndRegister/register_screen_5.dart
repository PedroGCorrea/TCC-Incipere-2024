import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final List<String> messages = [
    "Spread Creativity",
    "Unlock Your Potential",
    "Inspire the World",
    "Create with Passion",
  ];
  late Future<Map<String, dynamic>> _userDataFuture;

  int currentIndex = 0; // Para controlar qual frase está visível
  late Timer _timer; // Timer para mudar as frases

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
    // Iniciar o timer para mudar frases a cada 2 segundos
    _timer = Timer.periodic(Duration(seconds: 2), (Timer timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancelar o timer ao sair da tela
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture, // Função que busca os dados do usuário
      builder: (context, snapshot) {
        // Enquanto os dados estão sendo carregados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Caso haja erro na obtenção dos dados
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar os dados do usuário'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Tentar novamente
                    },
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        // Dados carregados com sucesso
        final userData = snapshot.data!;
        final fullName = userData['full_name'] ?? '';
        final firstName = fullName.isNotEmpty ? fullName.split(' ')[0] : '';

        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Texto de boas-vindas
                  Text(
                    "Welcome, $firstName",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8), // Espaçamento
                  // Texto animado alternando entre mensagens
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: Offset(0, 1), // De baixo para cima
                        end: Offset(0, 0),
                      ).animate(animation);

                      return SlideTransition(
                        position: slideAnimation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      messages[currentIndex],
                      key: ValueKey<String>(messages[currentIndex]),
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 32), // Espaçamento maior
                  // Descrição
                  Text(
                    "Incipere means start in Latin.\nIncipere your journey now!",
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32), // Espaçamento maior
                  // Botão para iniciar
                  ElevatedButton(
                    onPressed: () async {
                      // Ação ao clicar no botão
                      await updateCompletedRegister();
                      Navigator.pushReplacementNamed(context, '/profile'); // Navegar para a tela de perfil
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Incipere now!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final supabaseClient = Supabase.instance.client;

    // Obter o usuário autenticado
    final user = supabaseClient.auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw 'Usuário não autenticado';
    }

    // Buscar dados do perfil no Supabase
    final response = await supabaseClient
        .from('user_profiles')
        .select('full_name')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw 'Usuário não encontrado';
    }

    return response as Map<String, dynamic>;
  }

  Future<void> updateCompletedRegister() async {
    final supabaseClient = Supabase.instance.client;

    // Obter o usuário autenticado
    final user = supabaseClient.auth.currentUser;

    if (user == null) {
      throw 'Usuário não autenticado';
    }

    // Atualizar o campo completed_register na tabela user_profiles
    final response = await supabaseClient
        .from('user_profiles')
        .update({'completed_register': true})
        .eq('user_id', user.id);

    print('Registro atualizado com sucesso!');
  }
}
