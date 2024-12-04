import 'dart:typed_data'; // Para manipular arquivos
import 'dart:io' as io; // Apenas para dispositivos móveis
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../services/creative_process_modal.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({Key? key}) : super(key: key);

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  Uint8List? _webImage;
  io.File? _selectedImage;
  String? _workType;
  Duration _workingTime = Duration(hours: 0, minutes: 0);
  final List<Map<String, dynamic>> _workTypes = [];
  final List<Map<String, dynamic>> images = [];
  final ImagePicker _picker = ImagePicker();
  final Map<String, TextEditingController> controllers = {};

  bool _isLoading = false;
  final uuid = Uuid();

  Map<String, dynamic> creativeProcess = {
    "elements": [] // Cada elemento será adicionado aqui
  };

  // Estrutura dos elementos:
  /*{
    "type": "text", // Outros valores: image, quote, caption, link
    "content": "", // O conteúdo principal
    "align": "left", // Apenas para texto: left, center, right
    "format": "normal", // Apenas para texto: normal, italic, bold
    "color": "#000000", // Apenas para texto
    "image": "", // Apenas para imagem
    "title": "", // Apenas para link
    "url": "", // Apenas para link
  }*/


  void _addCreativeProcess() {
    showDialog(
      context: context,
      builder: (context) => CreativeProcessModal(
        creativeProcess: creativeProcess,
        onSave: (updatedProcess) {
          setState(() {
            creativeProcess = updatedProcess;
          });
        },
        images: images,
        controllers: controllers,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchWorkTypes();
  }

  @override
  void dispose() {
    // Certifique-se de liberar os controladores ao sair
    controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _fetchWorkTypes() async {
    final supabaseClient = Supabase.instance.client;
    final response = await supabaseClient.from('worktypes').select();

    setState(() {
      _workTypes.addAll(List<Map<String, dynamic>>.from(response));
    });
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

  Future<void> _savePost() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O título é obrigatório.')),
      );
      return;
    }

    if (_workType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione um tipo de trabalho.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabaseClient = Supabase.instance.client;
    final currentUser = supabaseClient.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Upload das imagens
      final List<Map<String, dynamic>> updatedElements = [];
      for (final element in creativeProcess['elements']) {
        if (element['type'] == 'image') {
          final image = images.firstWhere(
            (img) => img['name'] == element['content'],
            orElse: () => <String, dynamic>{},
          );

          if (image.isNotEmpty) {
            final imageName = '${currentUser.id}_${uuid.v4()}.png';
            final fileBytes = image['content'] as Uint8List;

            // Upload da imagem
            try {
              await supabaseClient.storage.from('postimages').uploadBinary(
                imageName,
                fileBytes,
                fileOptions: const FileOptions(upsert: true),
              );

              // Atualiza o campo "content" com o caminho da imagem no bucket
              final imagePath = supabaseClient.storage.from('postimages').getPublicUrl(imageName);
              element['content'] = imagePath;
            } catch (e) {
              throw Exception('Erro no upload da imagem: $e');
            }
          }
        }
        updatedElements.add(element);
      }

      // Atualiza o processo criativo
      creativeProcess['elements'] = updatedElements;

      // Upload da imagem de capa
      String? coverImagePath;
      if (_webImage != null || _selectedImage != null) {
        final imageName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final fileBytes = _webImage ?? await _selectedImage!.readAsBytes();

        try {
          await supabaseClient.storage.from('postimages').uploadBinary(
            imageName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

          coverImagePath = supabaseClient.storage.from('postimages').getPublicUrl(imageName);
        } catch (e) {
          throw Exception('Erro no upload da imagem de capa: $e');
        }
      }

      // Inserção no banco de dados
      await supabaseClient.from('posts').insert({
        'user_id': currentUser.id,
        'title': _titleController.text,
        'image_path': coverImagePath,
        'description': jsonEncode(creativeProcess), // Converte o processo criativo para JSON
        'working_time': _workingTime.toString(),
        'work_type': _workType,
        'likes': 0,
        
      });

      // Sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post criado com sucesso!')),
      );

      // Limpa os campos após o sucesso
      setState(() {
        _titleController.clear();
        _webImage = null;
        _selectedImage = null;
        _workType = null;
        _workingTime = Duration(hours: 0);
        creativeProcess = {"elements": []};
        images.clear();
      });

      Navigator.pop(context); // Fecha a tela se necessário
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar o post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _webImage != null
                            ? MemoryImage(_webImage!)
                            : _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                        child: _webImage == null && _selectedImage == null
                            ? Icon(Icons.add_a_photo, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _workType,
                      onChanged: (value) => setState(() {
                        _workType = value;
                      }),
                      items: _workTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['type_id'].toString(),
                          child: Text(type['name']),
                        );
                      }).toList(),
                      decoration: InputDecoration(labelText: 'Tipo de Trabalho'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addCreativeProcess,
                      child: Text("Adicionar Processo Criativo"),
                    ),
                    const SizedBox(height: 16),
                    Text('Tempo de Trabalho'),
                    Slider(
                      value: _workingTime.inHours.toDouble(),
                      min: 0,
                      max: 24,
                      divisions: 24,
                      label: '${_workingTime.inHours}h',
                      onChanged: (value) {
                        setState(() {
                          _workingTime = Duration(hours: value.toInt());
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _savePost,
                      child: Text('Salvar Post'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
