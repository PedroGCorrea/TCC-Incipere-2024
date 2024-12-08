import 'package:flutter/material.dart';
import 'package:incipere/config/app_routes.dart';
import 'package:incipere/services/userprovider.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();

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
    // Mock de dados do usuário atual
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String username = userProvider.username ?? '';
    final String fullName = userProvider.fullName ?? '';
    final String profileImageUrl = userProvider.profilePictureUrl ?? '';

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
                    backgroundImage: NetworkImage(profileImageUrl),
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
                      'Dica:Essa é a sua Bio do Incipere. Ela diz mais sobre você para os outros.',
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
                      child: Text('Apenas me leve ao site', style: TextStyle(color: Colors.deepPurple)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
