import 'package:flutter/material.dart';
import 'dart:typed_data'; // Para manipular arquivos
import 'dart:io' as io; // Apenas para dispositivos móveis
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCommentScreen extends StatefulWidget {
  final String commentId;
  final String initialText;
  final String? initialImagePath;

  const EditCommentScreen({
    required this.commentId,
    required this.initialText,
    this.initialImagePath,
  });

  @override
  _EditCommentScreenState createState() => _EditCommentScreenState();
}

class _EditCommentScreenState extends State<EditCommentScreen> {
  late TextEditingController _commentController;
  Uint8List? _webImage;
  io.File? _selectedImage;
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.initialText);
    _imagePath = widget.initialImagePath;
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

  Future<void> _saveComment() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final updatedText = _commentController.text;

    // Atualizar no banco
    await supabase.from('comments').update({
      'content': updatedText,
      if (_selectedImage != null || _webImage != null)
        'image_path': await _uploadImage(), // Fazer upload de uma nova imagem
    }).eq('comment_id', widget.commentId);

    Navigator.pop(context, true); // Retorna sucesso para a tela anterior
  }

  Future<String> _uploadImage() async {
    String? coverImagePath;
    final currentUser = supabase.auth.currentUser;
    try {
      if (_webImage != null || _selectedImage != null) {
        final imageName = '${currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}.png';
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
    return coverImagePath!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _commentController,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Editar Comentário',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            if (_imagePath != null || _selectedImage != null || _webImage != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImage = null;
                    _webImage = null; // Permite limpar a imagem
                  });
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        image: _webImage != null
                            ? DecorationImage(
                                image: MemoryImage(_webImage!),
                                fit: BoxFit.cover,
                              )
                            : _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : _imagePath != null
                                    ? DecorationImage(
                                        image: NetworkImage(_imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : null, // Fallback para ícone
                        color: _webImage == null && _selectedImage == null && _imagePath == null
                            ? Colors.grey[300] // Cor de fundo para o ícone
                            : null,
                      ),
                      child: (_webImage == null && _selectedImage == null && _imagePath == null)
                          ? Icon(Icons.image_not_supported, size: 32, color: Colors.grey)
                          : null, // Exibe o ícone apenas quando não há imagem
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                          _webImage = null; // Permite limpar a imagem
                        });
                      },
                      child: Icon(Icons.close, size: 16, color: Colors.red)
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () async {
                await _pickImage();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveComment,
        child: Icon(Icons.save),
      ),
    );
  }
}
