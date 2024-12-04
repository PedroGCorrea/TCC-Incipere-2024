import 'dart:async';
import 'package:flutter/material.dart';
import 'package:incipere/services/userprovider.dart';
import 'package:provider/provider.dart';

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

  int currentIndex = 0; // Para controlar qual frase está visível
  late Timer _timer; // Timer para mudar as frases

  @override
  void initState() {
    super.initState();
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String fullName = userProvider.fullName ?? '';
    final String firstName;

    if (fullName.isNotEmpty) {
      firstName = fullName.split(' ')[0];
    } else {
      firstName = '';
    }
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
                transitionBuilder: (Widget child, Animation<double> animation) {
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                onPressed: () {
                  // Ação ao clicar no botão
                  Navigator.pushReplacementNamed(context, '/profile'); // Navegar para a tela de perfil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
  }
}
