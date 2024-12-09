import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:incipere/services/themeprovider.dart';
import 'package:provider/provider.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './config/theme.dart';
import './config/app_routes.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider()
        )
      ],
      child: MainApp(),
    ),
);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
    @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      theme: AppThemes.getThemeByName('light'),
      darkTheme: AppThemes.getThemeByName('dark'),
      themeMode: ThemeMode.system,
      title: 'Incipere',
      initialRoute: AppRoutes.developer,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

/* class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erro ao verificar se está logado: ${snapshot.error}');
        }

        // Carregando enquanto aguarda a verificação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Decide a tela inicial com base no resultado
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          title: 'Incipere',
          initialRoute: snapshot.data ?? false ? AppRoutes.home : AppRoutes.login,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }

  Future<bool> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('supabase_token');

    // Verifica se o token existe antes de usar
    if (token == null) {
      return false;
    }

    try {
      final response = await Supabase.instance.client.auth.recoverSession(token);
      return response.session != null;
    } catch (e) {
      print('Erro ao recuperar a sessão: $e');
      return false;
    }
  }
} */

/*
lib/
├── config/          # Configurações globais
├── models/          # Modelos de dados
├── services/        # Serviços (Ex: autenticação, Supabase)
├── screens/         # Telas principais
├── widgets/         # Widgets reutilizáveis
├── utils/           # Funções utilitárias e constantes
└── main.dart        # Entrada do app

      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      title: 'Incipere',
*/