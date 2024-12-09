import 'package:flutter/material.dart';
import 'package:incipere/config/app_routes.dart';
import 'package:logger/logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/messenger.dart';

class RegisterScreen3 extends StatefulWidget {
  const RegisterScreen3({super.key});

  @override
  _RegisterScreen3State createState() => _RegisterScreen3State();
}

class _RegisterScreen3State extends State<RegisterScreen3> {
  final TextEditingController _bioController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  bool isBioEntered = false;
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
    // Listener para atualizar o estado do botão ao digitar
    _bioController.addListener(() {
      setState(() {
        isBioEntered = _bioController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> saveBioAndProceed() async {
    final bio = _bioController.text.trim();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Messenger.showError(context, 'Usuário não autenticado.');
        return;
      }

      // Atualiza a biografia na tabela user_profiles
      await supabase.from('user_profiles').update({
        'bio': bio,
      }).eq('user_id', user.id);

            Messenger.showSuccess(context, 'Biografia salva com sucesso!');
      Navigator.pushReplacementNamed(context, AppRoutes.register4);
    } catch (error) {
      Messenger.showError(context, 'Erro ao salvar biografia: $error');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture, // Função que obtém os dados do usuário
      builder: (context, snapshot) {
        // Enquanto os dados estão sendo carregados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 3'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Caso haja erro na obtenção dos dados
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 3'),
            ),
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
        final username = userData['username'] ?? 'Usuário';
        final fullName = userData['full_name'] ?? 'Nome completo';
        final profileImageUrl = userData['profile_image_path'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text('Criação de Conta - Parte 3'),
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seção da esquerda: Foto e dados do usuário
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      SizedBox(height: 12),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 24),
                  // Seção da direita: Input de biografia
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fale um pouco sobre você!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dica: Essa é a sua Bio do Incipere. Ela diz mais sobre você para os outros.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _bioController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Escreva aqui os seus pensamentos...',
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (isBioEntered) {
                              saveBioAndProceed();
                            } else {
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.register4);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBioEntered
                                ? Colors.deepPurple
                                : Colors.grey.shade400,
                          ),
                          child: Text(isBioEntered ? 'Próximo' : 'Pular'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                          child: Text('Apenas me leve ao site',
                              style: TextStyle(color: Colors.deepPurple)),
                        ),
                      ],
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
        .select('username, full_name, profile_image_path')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw 'Usuário não encontrado';
    }
    return response as Map<String, dynamic>;
  }
}
