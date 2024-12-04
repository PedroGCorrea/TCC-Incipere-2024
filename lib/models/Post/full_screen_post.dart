import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:incipere/models/Post/edit_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PostFullscreen extends StatefulWidget {
  final String postId;

  const PostFullscreen({super.key, required this.postId});

  @override
  State<PostFullscreen> createState() => _PostFullscreenState();
}

class _PostFullscreenState extends State<PostFullscreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? postDetails;
  String? authorUsername;
  String? workTypeName;
  bool showFabOptions = false;

  @override
  void initState() {
    super.initState();
    fetchPostDetails();
  }

  void _confirmDeletePost() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja deletar este post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Não deletar
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar exclusão
              },
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deletePost(); // Chama a função de deletar
    }
  }

  void _deletePost() async {
    try {
      await supabase
          .from('posts')
          .delete()
          .eq('post_id', widget.postId); // Deletar o post pelo ID
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deletado com sucesso!')),
        );
        Navigator.pop(context); // Voltar à tela anterior após deletar
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar post: $error')),
      );
    }
  }

  Future<void> fetchPostDetails() async {
    try {
      final postResponse = await supabase
          .from('posts')
          .select()
          .eq('post_id', widget.postId)
          .single();

      final userId = postResponse['user_id'];
      final workTypeId = postResponse['work_type'];

      final userResponse = await supabase
          .from('user_profiles')
          .select('username')
          .eq('user_id', userId)
          .single();

      final workTypeResponse = await supabase
          .from('worktypes')
          .select('name')
          .eq('type_id', workTypeId)
          .single();

      setState(() {
        postDetails = postResponse;
        authorUsername = userResponse['username'];
        workTypeName = workTypeResponse['name'];
      });
    } catch (e) {
      debugPrint('Error fetching post details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (postDetails == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAuthor = supabase.auth.currentUser?.id == postDetails!['user_id'];
    final postImagePath = postDetails!['image_path'];
    final descriptionJson = postDetails!['description'];
    final List<dynamic> descriptionElements =
        descriptionJson != null ? jsonDecode(descriptionJson)['elements'] : [];
    final likes = postDetails!['likes'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Title
            Text(
              postDetails!['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Author
            Text('Author: ${authorUsername ?? 'Unknown'}'),
            const SizedBox(height: 8),

            // Work Type
            Text('Work Type: ${workTypeName ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Working Time: ${postDetails!['working_time'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            const Divider(),

            // Post Image
            if (postImagePath != null && postImagePath.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.black,
                child: Image.network(
                  postImagePath,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'Imagem não disponível',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),

            // Description
            const SizedBox(height: 16),
            Container(
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1), // 10% de cada lado
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // O elemento ocupa toda a largura do container
                children: descriptionElements
                    .map((element) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildElement(element), // Alinhamento tratado aqui
                        ))
                    .toList(),
              ),
            ),

            const Divider(),

            // Like Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    // Like button functionality to be added later
                  },
                ),
                Text('$likes Likes'),
              ],
            ),

            const Divider(),

            // Comments Placeholder
            const Text('Comentários:', style: TextStyle(fontSize: 18)),
            const Placeholder(fallbackHeight: 100),
          ],
        ),
      ),
      floatingActionButton: isAuthor
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showFabOptions) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  heroTag: 'deletePost',
                  onPressed: _confirmDeletePost,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  heroTag: 'editPost',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditPostScreen(postId: widget.postId),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit),
                ),
              ),
            ],
            FloatingActionButton(
              heroTag: 'mainFab',
              onPressed: () {
                setState(() {
                  showFabOptions = !showFabOptions;
                });
              },
              child: Icon(showFabOptions ? Icons.close : Icons.more_vert),
            ),
          ],
        )
      : null,
    );
  }

  Widget _buildElement(Map<String, dynamic> element) {
    final align = _getTextAlign(element['align']);
    switch (element['type']) {
      case 'text':
        return Align(
          alignment: _getAlignment(align), // Converte para Align
          child: Text(
            element['content'] ?? '',
            textAlign: _getTextAlign(element['align']),
            style: TextStyle(
              fontSize: 16,
              fontWeight: _getFontWeight(element['format']),
              fontStyle: _getFontStyle(element['format']),
              color: _getTextColor(element['color']),
            ),
          ),
        );
      case 'caption':
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              element['content'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          )
        );
      case 'quote':
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(61, 243, 243, 243),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${element['content'] ?? ''}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      case 'link':
        return Center(
          child: ElevatedButton(
            onPressed: () {
              final url = element['content'];
              if (url != null) {
                _launchURL(url);
              }
            },
            child: Text(element['title'] ?? 'Abrir link'),
          ),
        );
      case 'image':
        return Align(
          alignment: _getAlignment(align), // Imagem respeita o alinhamento
          child: Image.network(
            element['content'] ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text('Erro ao carregar imagem'),
          ),
        );
      default:
        return const SizedBox.shrink(); // Elemento desconhecido
    }
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Alignment.centerLeft; // Alinhado à esquerda
      case TextAlign.center:
        return Alignment.center; // Centralizado
      case TextAlign.right:
        return Alignment.centerRight; // Alinhado à direita
      default:
        return Alignment.center; // Padrão: centralizado
    }
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Não foi possível abrir o link: $url');
    }
  }

  TextAlign _getTextAlign(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  FontWeight _getFontWeight(String? format) {
    return format == 'bold' ? FontWeight.bold : FontWeight.normal;
  }

  FontStyle _getFontStyle(String? format) {
    return format == 'italic' ? FontStyle.italic : FontStyle.normal;
  }

  Color? _getTextColor(String? color) {
    if (color == null || color == '#000000') return null;
    return Color(int.parse(color.replaceFirst('#', '0xFF')));
  }
}
