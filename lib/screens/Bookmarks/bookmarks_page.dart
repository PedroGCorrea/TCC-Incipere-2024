import 'package:flutter/material.dart';
import 'package:incipere/models/Post/full_screen_post.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarksScreen extends StatelessWidget {

  const BookmarksScreen({Key? key}) : super(key: key);

  Future<List<dynamic>> _fetchFavorites() async {
    final SupabaseClient supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return [];
    }

    final currentUserId = currentUser.id;
    final response = await supabase
        .from('favorites')
        .select('posts(*), added_at')
        .eq('user_id', currentUserId)
        .order('added_at', ascending: false);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar favoritos.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum favorito encontrado.'));
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final post = favorites[index]['posts'];
              return ListTile(
                leading: post['image_path'] != null
                    ? Image.network(post['image_path'], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.image, size: 50),
                title: Text(post['title'] ?? 'Sem título'),
                subtitle: Text('Adicionado em ${favorites[index]['added_at']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostFullscreen(postId: post['post_id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
