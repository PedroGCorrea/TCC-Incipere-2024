import 'package:flutter/material.dart';
import 'package:incipere/services/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = Supabase.instance.client;
  
  // Variáveis para armazenar configurações
  String? _selectedLanguage;
  String? _selectedTheme;
  bool? _notificationsEnabled;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    try {
      // Buscar o usuário atual do Supabase
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        // Tratar caso não haja usuário logado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado'))
        );
        return;
      }

      // Buscar configurações do usuário na tabela user_settings
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', currentUser.id)
          .single();

      setState(() {
        _selectedLanguage = response['language'] ?? 'pt';
        _selectedTheme = response['theme'] ?? 'dark';
        _notificationsEnabled = response['notifications_enabled'] ?? true;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar configurações: $error'))
      );
    }
  }

  Future<void> _saveUserSettings() async {
    var log = Logger();
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      log.i(_selectedLanguage);
      log.i(_selectedTheme);
      log.i(_notificationsEnabled);

      await _supabase
          .from('user_settings')
          .upsert({
        'user_id': currentUser.id,
        'language': _selectedLanguage,
        'theme': _selectedTheme,
        'notifications_enabled': _notificationsEnabled
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso'))
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $error'))
      );
    }
  }

  Future<void> _saveThemePreference(String themeName) async {
    
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      await supabase
          .from('user_settings')
          .upsert({
            'user_id': user.id,
            'theme': themeName
          });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator())
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Droplist de Idioma
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Idioma',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Droplist de Tema
            DropdownButtonFormField<String>(
              value: _selectedTheme,
              decoration: const InputDecoration(
                labelText: 'Tema',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'light', child: Text('Claro')),
                DropdownMenuItem(value: 'dark', child: Text('Escuro')),
                DropdownMenuItem(value: 'dracula', child: Text('Dracula')),
              ],
              onChanged: (themeName) {
              if (themeName != null) {
                Provider.of<ThemeProvider>(context, listen: false)
                    .setTheme(themeName);
                
                // Salvar a preferência do tema no Supabase
                _saveThemePreference(themeName);
              }
            },
            ),
            const SizedBox(height: 16),

            // Switch de Notificações
            SwitchListTile(
              title: const Text('Notificações'),
              value: _notificationsEnabled ?? true,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Botão de Salvar
            ElevatedButton(
              onPressed: _saveUserSettings,
              child: const Text('Salvar Configurações'),
            ),
          ],
        ),
      ),
    );
  }
}