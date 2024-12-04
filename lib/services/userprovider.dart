import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _username;
  String? _fullName;
  String? _email;
  String? _profilePictureUrl;
  bool _isLoading = true;

  String? get userId => _userId;
  String? get username => _username;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get profilePictureUrl => _profilePictureUrl;
  bool get isLoading => _isLoading;

  UserProvider() {
    loadUserData();
  }

  // Salvar dados do usuário
  Future<void> saveUserData({
    required String userId, 
    required String username, 
    required String fullName,
    required String email
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('username', username);
    await prefs.setString('full_name', fullName);
    await prefs.setString('email', email);

    _userId = userId;
    _username = username;
    _fullName = fullName;
    _email = email;
    notifyListeners();
  }

  // Carregar dados do usuário
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      _username = prefs.getString('username');
      _fullName = prefs.getString('full_name');
      _email = prefs.getString('email');
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados do usuário: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpar dados do usuário
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('full_name');
    await prefs.remove('email');

    _userId = null;
    _username = null;
    _fullName = null;
    _email = null;
    notifyListeners();
  }

  Future<void> saveProfilePictureUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture_url', url);
    _profilePictureUrl = url;
    notifyListeners();
  }
}