import 'package:flutter/material.dart';
import 'package:incipere/models/Post/full_screen_post.dart';
import 'package:incipere/screens/Profile/edit_profile.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String? profileUserId;
  const ProfileScreen({super.key, required this.profileUserId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfileData;
  List<Map<String, String>> _interests = [];
  List<dynamic> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _showPosts = false;
  int _followersCount = 0;
  int _postCount = 0;
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

  }

  Future<void> _loadUserProfile() async {
    try {

      // Consulta os dados do perfil do usuário na tabela `user_profiles`
      final profileResponse = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', widget.profileUserId.toString())
          .maybeSingle();

      if (profileResponse == null) {
        throw Exception('Perfil do usuário não encontrado');
      }

      setState(() {
        _userProfileData = profileResponse;
      });

      // Consulta os interesses do usuário
      final interestsResponse = await supabase
          .from('user_interests')
          .select('categories(name, icon_path)')
          .eq('user_id', widget.profileUserId.toString());

      setState(() {
        _interests = (interestsResponse as List).map<Map<String, String>>((interest) {
          final category = interest['categories'];
          return {
            'name': category['name'] ?? 'Desconhecido',
            'iconPath': category['icon_path'] ?? '',
          };
        }).toList();
      });

      // Consulta o número de seguidores
      final followersResponse = await supabase
          .from('followers')
          .count()
          .eq('user_id', widget.profileUserId.toString());

      setState(() {
        _followersCount = followersResponse;
      });

      // Conta a quantidade de posts do usuário
      final postCountResponse = await supabase
          .from('posts')
          .count()
          .eq('user_id', widget.profileUserId.toString());

      setState(() {
        _postCount = postCountResponse; // Define a contagem de posts
      });

      // Verifica se o usuário atual já segue
      if (currentUserId != null) {
        final isFollowingResponse = await supabase
            .from('followers')
            .select('*')
            .eq('user_id', widget.profileUserId.toString())
            .eq('follower_id', currentUserId.toString())
            .maybeSingle();

        setState(() {
          _isFollowing = isFollowingResponse != null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar os dados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        // Deixar de seguir
        await supabase
            .from('followers')
            .delete()
            .eq('user_id', widget.profileUserId.toString())
            .eq('follower_id', currentUserId.toString());

        setState(() {
          _isFollowing = false;
          _followersCount--;
        });
      } else {
        // Seguir
        await supabase.from('followers').insert({
          'user_id': widget.profileUserId,
          'follower_id': currentUserId,
        });

        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao seguir/desseguir: $e')),
      );
    }
  }

  void _viewFollowers() {
    var log = Logger();
  showDialog(
    context: context,
    builder: (context) {
      return FutureBuilder(
        future: supabase
            .from('followers')
            .select('follower_id, followed_at, user_profiles!inner(user_id, username, profile_image_path)')
            .eq('user_id', widget.profileUserId.toString()), // Busca seguidores do usuário atual
        builder: (context, snapshot) {
          log.i(snapshot.data);
          log.i(snapshot.error);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return AlertDialog(
              title: Text('Seguidores'),
              content: Text('Erro ao carregar seguidores.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))],
            );
          }

          final followers = snapshot.data as List;

          if (followers.isEmpty) {
            return AlertDialog(
              title: Text('Seguidores'),
              content: Text('Este usuário ainda não tem seguidores.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))],
            );
          }

          return AlertDialog(
            title: Text('Seguidores'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final followerData = followers[index]['user_profiles'];
                  final followedAt = DateTime.parse(followers[index]['followed_at']).toLocal();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: followerData['profile_image_path'] != null
                          ? NetworkImage(followerData['profile_image_path'])
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                    title: Text(followerData['username'] ?? 'Desconhecido'),
                    subtitle: Text('Seguindo desde ${followedAt.toString().split(' ')[0]}'),
                    onTap: () {
                      Navigator.pop(context); // Fecha o dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(profileUserId: followerData['user_id']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))],
          );
        },
      );
    },
  );
}


  void _editProfile() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => EditProfileScreen()));
  }

  void _viewPosts() async {
    // Carrega os posts
    try {
      final postsResponse = await supabase
          .from('posts')
          .select('*')
          .eq('user_id', widget.profileUserId.toString());

      setState(() {
        _userPosts = postsResponse;
        _showPosts = true; // Exibe a seção de posts
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar os posts')),
      );
    }
  }

  Widget _fallbackPostWidget(String? title) {
    return Container(
      color: Colors.grey[200], // Fundo cinza claro
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_snippet, // Ícone de texto
            size: 40,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            title ?? 'Sem título', // Título ou mensagem padrão
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
            overflow: TextOverflow.ellipsis, // Evita texto muito longo
            maxLines: 2,
          ),
        ],
      ),
    );
  } 

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfileData == null) {
      return Scaffold(
        body: Center(child: Text('Erro ao carregar o perfil')),
      );
    }

    final isCurrentUser = currentUserId == widget.profileUserId;
    final username = _userProfileData?['username'] ?? '@desconhecido';
    final fullName = _userProfileData?['full_name'] ?? 'Usuário';
    final bio = _userProfileData?['bio'] ?? '';
    final createdAt = _userProfileData?['created_at'] ?? '';
    final profileImageUrl = _userProfileData?['profile_image_path'];

    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto e informações principais
            SizedBox(height: 16),
            CircleAvatar(
              radius: 80,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : Icon(Icons.person) as ImageProvider,
            ),
            SizedBox(height: 16),
            Text(username, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(fullName, style: TextStyle(fontSize: 18, color: Colors.grey)),
            Divider(height: 20, thickness: 2),
            // Seções horizontais
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Interesses
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true, // Garante que a lista se ajuste ao tamanho disponível
                    physics: NeverScrollableScrollPhysics(), // Evita rolagem separada
                    itemCount: _interests.length,
                    itemBuilder: (context, index) {
                      final interest = _interests[index];
                      final iconPath = interest['iconPath'];
                      final icon = (iconPath != null && iconPath.isNotEmpty)
                          ? Image.network(iconPath, height: 24, width: 24)
                          : Icon(Icons.category, size: 24);

                      return ListTile(
                        leading: icon,
                        title: Text(interest['name'] ?? 'Desconhecido'),
                        contentPadding: EdgeInsets.zero, // Remove padding extra
                        horizontalTitleGap: 8, // Ajusta espaçamento entre ícone e texto
                      );
                    },
                  ),
                ),
                VerticalDivider(),
                // Bio e data de criação
                Expanded(
                  child: Column(
                    children: [
                      Text(bio, textAlign: TextAlign.center),
                      Text('Desde ${DateTime.parse(createdAt).toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                ),
                VerticalDivider(),
                // Seguidores e posts
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _viewFollowers,
                        child: Text('$_followersCount Seguidores'),
                      ),
                      Text('$_postCount Posts'),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 20, thickness: 2),
            if (!isCurrentUser)
              ElevatedButton(
                onPressed: _toggleFollow,
                child: Text(_isFollowing ? 'Deixar de Seguir' : 'Seguir'),
              ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _viewPosts, child: Text('Incis')),
            // Posts do usuário
            if (_showPosts)
              Divider(height: 20, thickness: 2),
            if (_showPosts)
              GridView.builder(
                shrinkWrap: true,
                itemCount: _userPosts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemBuilder: (context, index) {
                  final post = _userPosts[index];
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
                    child: post['image_path'] != null && post['image_path'].isNotEmpty
                      ? Image.network(
                          post['image_path'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _fallbackPostWidget(post['title']),
                        )
                      : _fallbackPostWidget(post['title']),

                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: isCurrentUser
          ? FloatingActionButton(onPressed: _editProfile, child: Icon(Icons.edit))
          : null,
    );
  }
}
