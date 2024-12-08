import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:incipere/screens/Profile/edit_profile_interests.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _profileImageUrl;
  List<String> selectedCategoryIds = [];
  List<Map<String, dynamic>> categories = [];

  Uint8List? _webImage; // Usado para armazenar imagens na web
  io.File? _selectedImage; // Usado para dispositivos móveis e desktop
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final response = await supabase
        .from('user_profiles')
        .select()
        .eq('user_id', user.id)
        .single();

      final profile = response;
      _usernameController.text = profile['username'];
      _fullNameController.text = profile['full_name'];
      _bioController.text = profile['bio'] ?? '';
      _profileImageUrl = profile['profile_image_path'];
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $error')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final interestsResponse = await supabase
          .from('user_interests')
          .select('category_id')
          .eq('user_id', user.id);

      setState(() {
        selectedCategoryIds = List<String>.from(interestsResponse.map((item) => item['category_id']));
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar interesses: $error')),
      );
      Navigator.pop(context);
      return;
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

  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _webImage == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final fileName = '${user.id}.png';

      final Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = _webImage!; // Para a web (Uint8List)
      } else {
        fileBytes = await _selectedImage!.readAsBytes(); // Para dispositivos móveis
      }

      final response1 = await supabase.storage
          .from('userprofilepictures')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      var log = Logger();
      log.i(response1);

      final publicUrl = supabase.storage
          .from('userprofilepictures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer upload da imagem: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null || _webImage != null) {
      imageUrl = await _uploadImage();
    }

    try {
      await supabase.from('user_profiles').update({
        'username': _usernameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        if (_profileImageUrl != null) 'profile_image_path': imageUrl,
      }).eq('user_id', user.id);

      // Atualizar interesses
      await supabase.from('user_interests').delete().eq('user_id', user.id);
      for (final categoryId in selectedCategoryIds) {
        await supabase.from('user_interests').insert({
          'user_id': user.id,
          'category_id': categoryId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o perfil: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _openInterestSelection() async {
    final updatedInterests = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => InterestSelectionScreen(selectedCategoryIds: selectedCategoryIds),
      ),
    );

    if (updatedInterests != null) {
      setState(() {
        selectedCategoryIds = updatedInterests;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) // Imagem selecionada em mobile
                    : (_webImage != null
                        ? MemoryImage(_webImage!) // Imagem selecionada em web
                        : (_profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!) // URL da imagem existente
                            : null)),
                child: _selectedImage == null &&
                        _webImage == null &&
                        _profileImageUrl == null
                    ? const Icon(Icons.camera_alt, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nome Completo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openInterestSelection,
              child: const Text('Selecionar Interesses'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
