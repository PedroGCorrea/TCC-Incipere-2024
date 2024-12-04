/*import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> signUp(String email, String password) async {
  final response = await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
  );
  if (response.error != null) {
    if (kDebugMode) {
      print('Erro: ${response.error!.message}');
    }
  } else {
    if (kDebugMode) {
      print('Usuário cadastrado com sucesso!');
    }
  }
}*/

import 'package:supabase_flutter/supabase_flutter.dart';

Supabase supabaseClient = Supabase.instance.client as Supabase;

