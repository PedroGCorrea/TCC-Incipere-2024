import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_routes.dart'; // Importa as rotas do app
import 'package:supabase_flutter/supabase_flutter.dart';

class MainAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  MainAppBarState createState() => MainAppBarState();
}

class MainAppBarState extends State<MainAppBar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final cachedImageUrl = await getCachedUserProfileImage();

    if (cachedImageUrl != null) {
      setState(() {
        profileImageUrl = cachedImageUrl;
      });
    } else {
      final fetchedImageUrl = await fetchUserProfileImageFromDatabase();
      if (fetchedImageUrl != null) {
        await cacheUserProfileImage(fetchedImageUrl);
        setState(() {
          profileImageUrl = fetchedImageUrl;
        });
      } else {
        setState(() {
          profileImageUrl =
              'https://i.pinimg.com/736x/cf/8a/61/cf8a61e3acfd3811892b36d5bf193cc7.jpg'; // Imagem padrão
        });
      }
    }
  }

  Future<void> cacheUserProfileImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', imageUrl);
  }

  Future<String?> getCachedUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_path');
  }

  Future<String?> fetchUserProfileImageFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        return '';
      }

      final response = await supabase
          .from('user_profiles')
          .select('profile_image_path')
          .eq('user_id', user.id)
          .maybeSingle();
      return response?['profile_image_path'] as String?;
    } catch (e) {
      return '';
    }
  }

  void _handleLogout(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();

    try {
      await supabase.auth.signOut();
      await prefs.clear();
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (route) => false);
    } catch (e) {
      _showErrorDialog(context, 'Erro ao sair: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.home);
            },
            child: Text(
              'InciPere', // Nome do aplicativo como logo
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: screenWidth / 3, // Barra de pesquisa ocupa 1/3 da largura
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Botão de Adicionar com opções de Post e Evento
        PopupMenuButton<String>(
          icon: Icon(Icons.add),
          tooltip: 'Adicionar',
          onSelected: (value) {
            if (value == 'post') {
              Navigator.pushNamed(context, AppRoutes.addPost);
            } else if (value == 'event') {
              Navigator.pushNamed(context, AppRoutes.addEvent);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'post',
              child: Text('Adicionar Post'),
            ),
            PopupMenuItem(
              value: 'event',
              child: Text('Adicionar Evento'),
            ),
          ],
        ),
        // Botão de Eventos
        PopupMenuButton(
          icon: Icon(Icons.event),
          tooltip: 'Eventos',
          onSelected: (value) {
            if (value == 'subscribed') {
              Navigator.pushNamed(context, AppRoutes.subscribedEvents);
            } else if (value == 'community') {
              Navigator.pushNamed(context, AppRoutes.communityEvents);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'subscribed',
              child: Text('Eventos Inscritos'),
            ),
            PopupMenuItem(
              value: 'community',
              child: Text('Eventos da Comunidade'),
            ),
          ],
        ),
        // Botão de Notificações
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        // Botão de Favoritos
        IconButton(
          icon: Icon(Icons.favorite),
          onPressed: () {
            Navigator.pushNamed(context, '/favorites');
          },
        ),
        // Botão de Perfil Rápido
        PopupMenuButton(
          icon: FutureBuilder<String?>(
            future: getCachedUserProfileImage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.account_circle,
                    size: 36,
                    color: Colors.grey[700],
                  ),
                );
              }

              return CircleAvatar(
                backgroundImage: NetworkImage(snapshot.data!),
              );
            },
          ),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.pushNamed(context, AppRoutes.profile);
            } else if (value == 'settings') {
              Navigator.pushNamed(context, AppRoutes.settings);
            } else if (value == 'logout') {
              _handleLogout(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Text('Abrir Perfil'),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Text('Configurações'),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Text('Sair'),
            ),
          ],
        ),
      ],
      backgroundColor: Colors.blue,
      elevation: 0,
    );
  }
}
