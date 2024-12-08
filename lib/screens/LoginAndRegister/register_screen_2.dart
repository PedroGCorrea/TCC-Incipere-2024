import 'dart:typed_data'; // Para manipular arquivos na web
import 'dart:io' as io; // Apenas para dispositivos móveis e desktop
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar a plataforma
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:incipere/services/supabase.dart';
import 'package:incipere/services/userprovider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_routes.dart';
import 'package:logger/logger.dart';

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
  late UserProvider userProvider;
  late Object? userId;

  @override
  void initState() {
    super.initState();
    handleUserProvider();
  }

  void onPhotoSelected() {
    setState(() {
      isPhotoSelected = true;
    });
  }

  Future<void> handleUserProvider() async {
    var log = Logger();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if(userProvider.userId == null) {
      // Referência ao bucket no Supabase
      final supabaseClient = Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      
      if (user == null || user.isAnonymous) {
      throw 'Usuário não autenticado';
    }

      final userprofile = await supabaseClient
          .from('user_profiles')
          .select('user_id, username, full_name')
          .eq('user_id', user.id)
          .maybeSingle();

      log.d('userId: $userId');
      log.d('user: $user');

      if (userprofile != null){
        await userProvider.saveUserData(
          userId: userprofile!['user_id'],
          username: userprofile['username'],
          fullName: userprofile['full_name'],
          email: user.email.toString(),
        );
      }
    }
    
    userId = userProvider.userId!;
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
      final fileName = '$userId.png';

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

      userProvider.saveProfilePictureUrl(publicUrl);

      // Atualizar o perfil do usuário com a URL da imagemS
      await supabaseClient
          .from('user_profiles')
          .update({'profile_image_path': publicUrl})
          .eq('user_id', userId!);

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
  return Consumer<UserProvider>(
    builder: (context, userProvider, child) {
      // Se ainda estiver carregando
      if (userProvider.isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Criação de Conta - Parte 2'),
          ),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Se não há usuário carregado
      if (userProvider.username == null || userProvider.fullName == null) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Criação de Conta - Parte 2'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Não foi possível carregar os dados do usuário'),
                ElevatedButton(
                  onPressed: () {
                    // Tente recarregar ou voltar para tela anterior
                    userProvider.loadUserData();
                  },
                  child: Text('Tentar Novamente'),
                )
              ],
            ),
          ),
        );
      }

      // Conteúdo normal com dados do Provider
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
                          userProvider.username!, // Agora vem do Provider
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Nome completo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userProvider.fullName!, // Agora vem do Provider
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
}
