import 'package:flutter/material.dart';
import 'package:incipere/screens/Home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart'; // Seu arquivo de temas

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = AppThemes.darkTheme;
  String _currentThemeName = 'dark';

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await supabase
            .from('user_settings')
            .select('theme')
            .eq('user_id', user.id)
            .single();

        if (response['theme'] != null) {
          setTheme(response['theme']);
        }
      } catch (e) {
        // Tema padrão se não encontrar
        setTheme('dark');
      }
    }
  }

  void setTheme(String themeName) {
    _currentTheme = AppThemes.getThemeByName(themeName);
    _currentThemeName = themeName;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: themeProvider.currentTheme,
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}