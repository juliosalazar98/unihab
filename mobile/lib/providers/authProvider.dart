import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constantes.dart';
import '../models/usuario.dart';
import '../services/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  String? _token;
  bool _cargando = false;
  final AuthService _authService = AuthService();

  Usuario? get usuario => _usuario;
  String? get token => _token;
  bool get cargando => _cargando;
  bool get autenticado => _token != null;
  bool get esPropietario => _usuario?.rol == 'PROPIETARIO';
  bool get esAdmin => _usuario?.rol == 'ADMIN';

  bool _invitado = false;

  /// Solo es invitado mientras no haya token; al iniciar sesión
  /// o registrarse deja de serlo automáticamente.
  bool get esInvitado => _invitado && _token == null;

  void entrarComoInvitado() {
    _invitado = true;
    notifyListeners();
  }

  Future<void> cargarSesion() async {
    _token = await _authService.getToken();

    if (_token != null) {
      try {
        final res = await http.get(
          Uri.parse('${Constantes.baseUrl}/auth/perfil'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        final data = jsonDecode(res.body);
        if (data['ok'] == true) {
          _usuario = Usuario.fromJson(data['datos']);
        } else {
          _usuario = await _authService.getUsuarioGuardado();
        }
      } catch (_) {
        _usuario = await _authService.getUsuarioGuardado();
      }
    }

    notifyListeners();
  }

  void actualizarUsuario(Usuario nuevoUsuario) {
    _usuario = nuevoUsuario;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _cargando = true;
    notifyListeners();

    final data = await _authService.login(email, password);

    if (data['ok'] == true) {
      _token = data['datos']['token'];
      try {
        final res = await http.get(
          Uri.parse('${Constantes.baseUrl}/auth/perfil'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        final perfil = jsonDecode(res.body);
        if (perfil['ok'] == true) {
          _usuario = Usuario.fromJson(perfil['datos']);
        } else {
          _usuario = Usuario.fromJson(data['datos']['usuario']);
        }
      } catch (_) {
        _usuario = Usuario.fromJson(data['datos']['usuario']);
      }
    }

    _cargando = false;
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> registrar(
      String nombre, String email, String password, String rol,
      {String? telefono}) async {
    _cargando = true;
    notifyListeners();

    final data = await _authService.registrar(nombre, email, password, rol,
        telefono: telefono);

    if (data['ok'] == true) {
      _token = data['datos']['token'];
      try {
        final res = await http.get(
          Uri.parse('${Constantes.baseUrl}/auth/perfil'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        final perfil = jsonDecode(res.body);
        if (perfil['ok'] == true) {
          _usuario = Usuario.fromJson(perfil['datos']);
        } else {
          _usuario = Usuario.fromJson(data['datos']['usuario']);
        }
      } catch (_) {
        _usuario = Usuario.fromJson(data['datos']['usuario']);
      }
    }

    _cargando = false;
    notifyListeners();
    return data;
  }

  Future<Map<String, dynamic>> loginConGoogle(String idToken) async {
    _cargando = true;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      final data = jsonDecode(res.body);

      if (data['ok'] == true) {
        _token = data['datos']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        try {
          final perfil = await http.get(
            Uri.parse('${Constantes.baseUrl}/auth/perfil'),
            headers: {'Authorization': 'Bearer $_token'},
          );
          final perfilData = jsonDecode(perfil.body);
          if (perfilData['ok'] == true) {
            _usuario = Usuario.fromJson(perfilData['datos']);
          } else {
            _usuario = Usuario.fromJson(data['datos']['usuario']);
          }
        } catch (_) {
          _usuario = Usuario.fromJson(data['datos']['usuario']);
        }
      }

      _cargando = false;
      notifyListeners();
      return data;
    } catch (e) {
      _cargando = false;
      notifyListeners();
      return {'ok': false, 'mensaje': 'Error de conexión'};
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _usuario = null;
    _invitado = false;
    notifyListeners();
  }
}
