import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen4 extends StatefulWidget {
  const RegisterScreen4({super.key});

  @override
  State<RegisterScreen4> createState() => _RegisterScreen4State();
}

class _RegisterScreen4State extends State<RegisterScreen4> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  List<String> selectedCategoryIds = [];
  bool isInterestSelected = false;
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    fetchInitialCategories();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        fetchInitialCategories();
      }
    });
    _userDataFuture = _fetchUserData();
  }

  Future<void> fetchInitialCategories() async {
    final response = await supabase
        .from('categories')
        .select('category_id, name')
        .order('category_id', ascending: true)
        .limit(10);

    if (response is PostgrestResponse && response.isEmpty) {
      print('Erro ao buscar categorias: $response');
      return;
    }

    setState(() {
      categories = List<Map<String, dynamic>>.from(response as List);
    });
  }

  Future<void> searchCategories(String query) async {
    final response = await supabase
        .from('categories')
        .select('category_id, name')
        .ilike('name', '%$query%')
        .limit(10);

    if (response is PostgrestResponse && response.isEmpty) {
      print('Erro ao buscar categorias com pesquisa: $response');
      return;
    }

    setState(() {
      categories = List<Map<String, dynamic>>.from(response as List);
    });
  }



  void toggleCategorySelection(String categoryId) {
    setState(() {
      if (selectedCategoryIds.contains(categoryId)) {
        selectedCategoryIds.remove(categoryId);
      } else {
        selectedCategoryIds.add(categoryId);
      }
      isInterestSelected = selectedCategoryIds.isNotEmpty;
    });
  }

  Future<void> saveInterestsAndProceed() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    try {
      // Salva os interesses no banco de dados
      for (final categoryId in selectedCategoryIds) {
        await supabase.from('user_interests').insert({
          'user_id': user.id,
          'category_id': categoryId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Interesses salvos com sucesso!')),
      );

      // Navega para a próxima tela
      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar interesses: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture, // Função que busca os dados do usuário
      builder: (context, snapshot) {
        // Enquanto os dados estão sendo carregados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 4'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Caso haja erro na obtenção dos dados
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Criação de Conta - Parte 4'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar os dados do usuário' + snapshot.error.toString()),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Tentar novamente
                    },
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        // Dados carregados com sucesso
        final userData = snapshot.data!;
        final username = userData['username'] ?? 'Usuário';
        final fullName = userData['full_name'] ?? 'Nome completo';
        final profileImageUrl = userData['profile_image_path'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text('Criação de Conta - Parte 4'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Coluna da esquerda: Pesquisa e lista de categorias
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () {
                              searchCategories(_searchController.text.trim());
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Trending:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = selectedCategoryIds.contains(
                                category['category_id']);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  toggleCategorySelection(
                                      category['category_id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  backgroundColor: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade300,
                                ),
                                child: Text(category['name']),
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: fetchInitialCategories,
                        child: Text('See more...'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                // Coluna da direita: Informações do usuário
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.isEmpty
                          ? Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(height: 12),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isInterestSelected
                          ? saveInterestsAndProceed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInterestSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade400,
                      ),
                      child: Text(isInterestSelected ? 'Next' : 'Skip'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: Text('Just take me to the site'),
                    ),
                  ],
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

    // Buscar dados do perfil no Supabase
    final response = await supabaseClient
        .from('user_profiles')
        .select('username, full_name, profile_image_path')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      throw 'Usuário não encontrado';
    }

    return response as Map<String, dynamic>;
  }
}
