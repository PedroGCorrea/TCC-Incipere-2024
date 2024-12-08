import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:incipere/models/Post/edit_comment.dart';
import 'package:incipere/models/Post/edit_post.dart';
import 'package:incipere/screens/Profile/main_profile.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // Para manipular arquivos
import 'dart:io' as io; // Apenas para dispositivos móveis
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final TextEditingController _commentController = TextEditingController();
  Uint8List? _webImage;
  io.File? _selectedImage;
  List<dynamic> _comments = [];
  bool _isLoadingComments = false;
  final ImagePicker _picker = ImagePicker();
  bool _isFavorited = false;
  bool isLiked = false;
  int likeCount = 0;
  late Object currentUserId;

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      return;
    }
    currentUserId = currentUser.id;
    fetchPostDetails();
    _fetchComments();
    _checkIfFavorited();
    _fetchLikeStatus();

  }

  Future<void> _fetchLikeStatus() async {
    var log = Logger();
    final response = await supabase
        .from('likes')
        .select()
        .eq('user_id', currentUserId.toString())
        .eq('post_id', widget.postId)
        .maybeSingle();
    log.i(response);

    final countResponse = await supabase
        .from('likes')
        .count()
        .eq('post_id', widget.postId);
    log.i(countResponse);

    setState(() {
      isLiked = response != null;
      likeCount = countResponse;
    });
  }

  Future<void> _toggleLike() async {
    if (isLiked) {
      // Remover like
      await supabase
          .from('likes')
          .delete()
          .eq('user_id', currentUserId)
          .eq('post_id', widget.postId);
      setState(() {
        isLiked = false;
        likeCount -= 1;
      });
    } else {
      // Adicionar like
      await supabase.from('likes').insert({
        'user_id': currentUserId,
        'post_id': widget.postId,
      });
      setState(() {
        isLiked = true;
        likeCount += 1;
      });
    }
  }

  Future<void> _showLikesDialog() async {
    final likeData = await supabase
        .from('likes')
        .select('user_profiles(user_id, username, profile_image_path)')
        .eq('post_id', widget.postId)
        .order('liked_at', ascending: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Curtidas'),
          content: likeData.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, // Defina uma altura fixa para evitar problemas
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: likeData.length,
                  itemBuilder: (context, index) {
                    final user = likeData[index]['user_profiles'];
                    return ListTile(
                      leading: user['profile_image_path'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(user['profile_image_path']),
                            )
                          : CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text('@${user['username']}'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              profileUserId: user['user_id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            : Text('Nenhum like neste post.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkIfFavorited() async {
    final response = await supabase
        .from('favorites')
        .select()
        .eq('user_id', currentUserId)
        .eq('post_id', widget.postId)
        .maybeSingle();
    setState(() {
      _isFavorited = response != null;
    });
  }

  Future<void> _toggleFavorite() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final currentUserId = currentUser.id;

    if (_isFavorited) {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', currentUserId)
          .eq('post_id', widget.postId);
    } else {
      await supabase.from('favorites').insert({
        'user_id': currentUserId,
        'post_id': widget.postId,
      });
    }
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final response = await supabase
          .from('comments')
          .select('*, user_profiles(username, profile_image_path)')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);
      setState(() => _comments = response);
    } catch (e) {
      print('Erro ao carregar comentários: $e');
    }
    setState(() => _isLoadingComments = false);
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty && _webImage == null && _selectedImage == null) return;

    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    String? coverImagePath;
    try {
      if (_webImage != null || _selectedImage != null) {
        final imageName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final fileBytes = _webImage ?? await _selectedImage!.readAsBytes();

        try {
          await supabase.storage.from('commentsimages').uploadBinary(
            imageName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

          coverImagePath = supabase.storage.from('commentsimages').getPublicUrl(imageName);
        } catch (e) {
          throw Exception('Erro no upload da imagem de capa: $e');
        }
      }
    } catch (e) {
      print('Erro ao postar comentário: $e');
    }

    try {
      await supabase.from('comments').insert({
        'post_id': widget.postId,
        'user_id': currentUser.id,
        'content': _commentController.text.trim(),
        'image_path': coverImagePath,
      });
      _commentController.clear();
      _selectedImage = null;
      _webImage = null;
      await _fetchComments();
    } catch (e) {
      print('Erro ao postar comentário: $e');
    }
  }

  String _formatCommentDate(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inHours < 24) {
      return timeago.format(dateTime, locale: 'pt_BR');
    }
    return DateFormat('dd/MM/yyyy').format(dateTime);
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, usamos bytes diretamente
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null; // Certifique-se de limpar a imagem nativa
          });
        } else {
          // Para dispositivos móveis, usamos o caminho do arquivo
          setState(() {
            _selectedImage = io.File(pickedFile.path);
            _webImage = null; // Certifique-se de limpar a imagem da web
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  /*Future<void> _captureImage() async {
    final picker = ImagePicker();
    final capturedFile = await picker.pickImage(source: ImageSource.camera);

    if (capturedFile != null) {
      setState(() {
        _selectedImage = io.File(capturedFile.path);
      });
    }
  }*/

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

  Future<void> _deleteComment(String commentId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir comentário'),
        content: Text('Tem certeza de que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await supabase.from('comments').delete().eq('comment_id', commentId);
      _fetchComments(); // Recarrega os comentários após excluir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comentário excluído com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (postDetails == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAuthor = currentUserId == postDetails!['user_id'];
    final postImagePath = postDetails!['image_path'];
    final descriptionJson = postDetails!['description'];
    final List<dynamic> descriptionElements =
        descriptionJson != null ? jsonDecode(descriptionJson)['elements'] : [];

    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  postDetails!['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (!isAuthor)
                  IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border, // Ícone dinâmico
                      color: _isFavorited ? Colors.red : Colors.grey, // Cor dinâmica
                    ),
                    onPressed: _toggleFavorite,
                  ),
                
              ],
            ),
            // Post Title
            
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
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(),
                ),
                GestureDetector(
                  onTap: _showLikesDialog, // Abre a tela sobreposta com a lista de usuários que deram like
                  child: Text('$likeCount Likes'),
                ),
              ],
            ),

            const Divider(),

            // Seção de comentários
              Text('Comentários', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Campo para adicionar novo comentário
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: null, // Permite múltiplas linhas dinamicamente
                      keyboardType: TextInputType.multiline, // Define o teclado como multilinha
                      decoration: InputDecoration(
                        hintText: 'Adicione um comentário...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.image),
                        onPressed: _pickImage, // Abre a galeria para selecionar uma imagem
                      ),
                      if (_webImage != null || _selectedImage != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _webImage = null;
                              _selectedImage = null; // Permite limpar a imagem
                            });
                          },
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: _webImage != null
                                    ? Image.memory(
                                        _webImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              if (_webImage == null && _selectedImage == null && _commentController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Adicione uma imagem ou escreva um comentário.")),
                              );
                              return;
                              }
                              _postComment(); // Função para salvar o comentário no banco de dados
                            },
                          child: Text('POSTAR'),
                        ),
                    ],
                  )
                ],
              ),

              Divider(),

              // Lista de comentários
              if (_isLoadingComments)
                Center(child: CircularProgressIndicator())
              else if (_comments.isEmpty)
                Center(child: Text('Sem comentários ainda.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final user = comment['user_profiles'];
                    final isCurrentUser = comment['user_id'] == supabase.auth.currentUser?.id;

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: {'profileUserId': comment['user_id']},
                          );
                        },
                        child: CircleAvatar(
                          backgroundImage: user['profile_image_path'] != null
                              ? NetworkImage(user['profile_image_path'])
                              : AssetImage('assets/default_avatar.png') as ImageProvider,
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: {'profileUserId': comment['user_id']},
                          );
                        },
                        child: Text('@${user['username'] ?? 'Desconhecido'}'),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (comment['image_path'] != null)
                            Image.network(
                              comment['image_path'],
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width * 0.1,
                              fit: BoxFit.cover,
                            ),
                          if (comment['content'] != null)
                            Text(comment['content'] ?? ''),
                        ],
                      ),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isCurrentUser)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditCommentScreen(
                                          commentId: comment['comment_id'],
                                          initialText: comment['content'] ?? '',
                                          initialImagePath: comment['image_path'],
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      _fetchComments(); // Recarrega os comentários após editar
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteComment(comment['comment_id']),
                                ),
                              ],
                            ),

                          Text(_formatCommentDate(comment['created_at'])),
                        ],
                      ),
                    );
                  },
                ),
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
