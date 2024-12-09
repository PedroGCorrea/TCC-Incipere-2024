import 'package:flutter/material.dart';
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
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select('post_id, user_id, title, image_path, created_at')
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
                            // Header do post (nome do usuário e data)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    radius: 20,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${post['user_id']}', // Atualize para pegar o nome de usuário se disponível
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(DateTime.parse(post['created_at'])),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
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

  // Formata a data de criação para exibir como string legível
  String _formatDate(DateTime utcDate) {
    // Converte a data UTC para o horário local
    final localDate = utcDate.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);
    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else  if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

}
