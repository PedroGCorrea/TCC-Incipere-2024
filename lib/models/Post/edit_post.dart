import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:incipere/services/edit_creative_process_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; 
import 'package:uuid/uuid.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;

  const EditPostScreen({super.key, required this.postId});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _workingTimeController = TextEditingController(); //refazer isso pra mudar a logica
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? postDetails;
  String? selectedWorkType;
  final List<Map<String, dynamic>> workTypes = [];
  Uint8List? _webImage;
  io.File? _selectedImage;
  String? _currentCoverUrl;

  final Map<String, TextEditingController> controllers = {};
  final List<Map<String, dynamic>> images = [];
  bool _isLoading = true;
  Map<String, dynamic> creativeProcess = {'elements': []};
  final uuid = Uuid();
  

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
    _fetchWorkTypes();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('post_id', widget.postId)
          .single();

      setState(() {
        postDetails = response;
        selectedWorkType = response['work_type'].toString();
        _titleController.text = response['title'] ?? '';
        _workingTimeController.text = response['working_time'] ?? '';
        creativeProcess = jsonDecode(response['description']) ?? {};
        _currentCoverUrl = response['image_path'];
        selectedWorkType = response['work_type_id'];
      });
    } catch (e) {
      debugPrint('Error loading post details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWorkTypes() async {
    try {
      final supabaseClient = Supabase.instance.client;
      final response = await supabaseClient.from('worktypes').select();
      setState(() {
        workTypes.addAll(List<Map<String, dynamic>>.from(response));
      });
    } catch (e) {
      debugPrint('Error fetching work types: $e');
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

  Widget _buildImagePreview() {
    final bool isWebImage = _webImage != null;
    final bool isSelectedImage = _selectedImage != null;

    return GestureDetector(
      onTap: _pickImage, // Permite selecionar nova imagem ao tocar na prévia
      child: Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: isWebImage
            ? Image.memory(_webImage!, fit: BoxFit.cover)
            : isSelectedImage
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : _currentCoverUrl != null
                    ? Image.network(_currentCoverUrl!, fit: BoxFit.cover)
                    : const Center(child: Text('Selecione uma imagem de capa')),
      ),
    );
  }


  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O título é obrigatório.')),
      );
      return;
    }

    if (selectedWorkType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um tipo de trabalho.')),
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
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Atualização da imagem de capa
      String? coverImagePath = _currentCoverUrl;
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

      // Atualização do processo criativo
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

            try {
              await supabaseClient.storage.from('postimages').uploadBinary(
                imageName,
                fileBytes,
                fileOptions: const FileOptions(upsert: true),
              );

              final imagePath = supabaseClient.storage.from('postimages').getPublicUrl(imageName);
              element['content'] = imagePath;
            } catch (e) {
              throw Exception('Erro no upload da imagem do processo criativo: $e');
            }
          }
        }
        updatedElements.add(element);
      }
      creativeProcess['elements'] = updatedElements;

      // Atualização no banco de dados
      await supabaseClient.from('posts').update({
        'title': _titleController.text,
        'image_path': coverImagePath,
        'description': jsonEncode(creativeProcess), // Converte o processo criativo para JSON
        'working_time': _workingTimeController.text,
        'work_type': selectedWorkType,
      }).eq('post_id', widget.postId);

      // Sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post atualizado com sucesso!')),
      );

      if (mounted) {
        Navigator.pop(context); // Fecha a tela se necessário
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editCreativeProcess() {
    showDialog(
      context: context,
      builder: (context) => EditCreativeProcessModal(
        data: creativeProcess,
        images: images,
        controllers: controllers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Exibe o indicador de carregamento enquanto os dados estão sendo carregados
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Post'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),

            // Working Time Field
            TextField(
              controller: _workingTimeController,
              decoration: const InputDecoration(labelText: 'Tempo de Trabalho'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Work Type Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de Trabalho'),
              items: workTypes.map((type) {
                return DropdownMenuItem(
                  value: type['type_id'].toString(),
                  child: Text(type['name']),
                );
              }).toList(),
              value: selectedWorkType ?? 
                (workTypes.isNotEmpty ? workTypes.first['type_id'].toString() : null),
              onChanged: (value) {
                setState(() {
                  selectedWorkType = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Cover Image Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Imagem de Capa', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                _buildImagePreview(),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(height: 16),

            // Creative Process Modal Button
            ElevatedButton(
              onPressed: _editCreativeProcess,
              child: const Text('Editar Processo Criativo'),
            ),

            const SizedBox(height: 32),

            // Save Changes Button
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
