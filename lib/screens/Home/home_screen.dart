import 'package:flutter/material.dart';
import 'package:incipere/screens/Profile/main_profile.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/Post/full_screen_post.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCompletedRegister();
    _loadPosts();
  }

  Future<void> _checkCompletedRegister() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado';
      }

      final response = await supabase
          .from('user_profiles')
          .select('completed_register')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        throw 'Usuário não encontrado';
      }

      final isCompleted = response['completed_register'] as bool? ?? false;

      if (!isCompleted) {
        _showIncompleteRegisterDialog();
      }
    } catch (error) {
      debugPrint('Erro ao verificar completed_register: $error');
    }
  }

  Future<void> _updateCompletedRegister(bool isComplete) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado';
      }

      await supabase
          .from('user_profiles')
          .update({'completed_register': isComplete})
          .eq('user_id', user.id);
    } catch (error) {
      debugPrint('Erro ao atualizar completed_register: $error');
    }
  }

  void _showIncompleteRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cadastro Incompleto'),
          content: const Text(
              'Percebemos que seu cadastro não está completo. Você deseja completá-lo agora? \n\nObs: você sempre pode adicionar as informações manualmente na edição de perfil.'),
          actions: [
            TextButton(
              onPressed: () async {
                // Define completed_register como true e fecha o diálogo
                await _updateCompletedRegister(true);
                Navigator.of(context).pop();
              },
              child: const Text('Não, obrigado'),
            ),
            TextButton(
              onPressed: () {
                // Direciona o usuário para a página de registro
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/register2');
              },
              child: const Text('Completar Agora'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select('''
            post_id,
            user_id,
            title,
            image_path,
            created_at,
            user_profiles(
              username,
              profile_image_path
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        posts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Erro ao carregar posts: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text('Nenhum post encontrado.'))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final userProfile = post['user_profiles'];
                    final profileImageUrl = userProfile?['profile_image_path'];
                    final username = userProfile?['username'] ?? 'usuário desconhecido';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostFullscreen(postId: post['post_id']),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header do post (imagem, nome do usuário e data)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(
                                            profileUserId: post['user_id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 20,
                                      backgroundImage: profileImageUrl != null
                                          ? NetworkImage(profileImageUrl)
                                          : null,
                                      child: profileImageUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(
                                            profileUserId: post['user_id'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '@$username',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(
                                              DateTime.parse(post['created_at'])),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (post['title'] != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Text(
                                  post['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            if (post['image_path'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Image.network(
                                  post['image_path'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.height * 0.2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime utcDate) {
    final localDate = utcDate.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}
