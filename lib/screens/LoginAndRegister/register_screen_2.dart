import 'dart:typed_data'; // Para manipular arquivos na web
import 'dart:io' as io; // Apenas para dispositivos móveis e desktop
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar a plataforma
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_routes.dart';

bool isPhotoSelected = false;

class RegisterScreen2 extends StatefulWidget {
  const RegisterScreen2({super.key});

  @override
  _RegisterScreen2State createState() => _RegisterScreen2State();
}

class _RegisterScreen2State extends State<RegisterScreen2> {
  Uint8List? _webImage; // Usado para armazenar imagens na web
  io.File? _selectedImage; // Usado para dispositivos móveis e desktop
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabaseClient = Supabase.instance.client;
  late final User ?user;
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    user = supabaseClient.auth.currentUser;
    _userDataFuture = _fetchUserData();
  }

  void onPhotoSelected() {
    setState(() {
      isPhotoSelected = true;
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
            onPhotoSelected();
          });
        } else {
          // Para dispositivos móveis, usamos o caminho do arquivo
          setState(() {
            _selectedImage = io.File(pickedFile.path);
            _webImage = null; // Certifique-se de limpar a imagem da web
            onPhotoSelected();
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  void _skipOrNext() {
    if (_webImage == null && _selectedImage == null) {
      Navigator.pushNamed(context, AppRoutes.register3);
    } else {
      _saveImageAndProceed();
    }
  }

  void _saveImageAndProceed() async {
    try {
      if(user == null) return;
      final fileName = '${user?.id}.png';

      // Dados da imagem
      final Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = _webImage!; // Para a web (Uint8List)
      } else {
        fileBytes = await _selectedImage!.readAsBytes(); // Para dispositivos móveis
      }

      await supabaseClient.storage
          .from('userprofilepictures')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabaseClient.storage
          .from('userprofilepictures')
          .getPublicUrl(fileName);

      print('Imagem salva com sucesso. URL: $publicUrl');

      // Atualizar o perfil do usuário com a URL da imagemS
      await supabaseClient
          .from('user_profiles')
          .update({'profile_image_path': publicUrl})
          .eq('user_id', user!.id);

      // Prosseguir para a próxima tela
      Navigator.pushReplacementNamed(context, AppRoutes.register3);
    } on StorageException catch (storageError) {
      print('Erro de storage: ${storageError.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar imagem. Verifique suas permissões.'),
          backgroundColor: Colors.red,
        ),
      );
    }catch (e) {
      print('Erro ao salvar a imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a imagem. Tente novamente.')),
      );
    }
  }

  void _goToHomePage() {
    Navigator.pushNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture, // Função que obtém os dados do usuário
      builder: (context, snapshot) {
        // Enquanto os dados estão sendo carregados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 2'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se houve erro ao buscar os dados
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 2'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar os dados do usuário'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Recarregar os dados
                    },
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        // Se os dados foram carregados corretamente
        final userData = snapshot.data!;
        final username = userData['username'] ?? 'Desconhecido';
        final fullName = userData['full_name'] ?? 'Desconhecido';

        return Scaffold(
          appBar: AppBar(
            title: Text('Criação de Conta - Parte 2'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nome de usuário:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            username, // Vem do snapshot
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nome completo:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            fullName, // Vem do snapshot
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: _skipOrNext,
                  child: Text(isPhotoSelected == false ? 'Pular' : 'Próximo'),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: _goToHomePage,
                  child: Text('Apenas me leve ao site'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final supabaseClient = Supabase.instance.client;

    // Obter o usuário autenticado
    final user = supabaseClient.auth.currentUser;

    if (user == null || user.isAnonymous) {
      throw 'Usuário não autenticado';
    }

    // Obter dados do perfil no Supabase
    final response = await supabaseClient
        .from('user_profiles')
        .select('username, full_name')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw 'Usuário não encontrado';
    }

    return response as Map<String, dynamic>;
  }
}
