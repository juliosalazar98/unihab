import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constantes.dart';
import '../models/usuario.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${Constantes.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['datos']['token']);
      await prefs.setString('usuario', jsonEncode(data['datos']['usuario']));
    }

    return data;
  }

  Future<Map<String, dynamic>> registrar(
      String nombre, String email, String password, String rol,
      {String? telefono}) async {
    final res = await http.post(
      Uri.parse('${Constantes.baseUrl}/auth/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
        'rol': rol,
        if (telefono != null && telefono.isNotEmpty) 'telefono': '591$telefono',
      }),
    );

    return jsonDecode(res.body);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Usuario?> getUsuarioGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioStr = prefs.getString('usuario');
    if (usuarioStr == null) return null;
    return Usuario.fromJson(jsonDecode(usuarioStr));
  }
}
