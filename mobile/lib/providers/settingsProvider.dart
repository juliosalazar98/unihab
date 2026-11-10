import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyModoOscuro = 'modoOscuro';
  static const _keyNotificaciones = 'notificacionesInternas';

  bool _modoOscuro = false;
  bool _notificacionesActivas = true;
  bool _cargado = false;

  bool get modoOscuro => _modoOscuro;
  bool get notificacionesActivas => _notificacionesActivas;
  bool get cargado => _cargado;

  ThemeMode get themeMode => _modoOscuro ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    _modoOscuro = prefs.getBool(_keyModoOscuro) ?? false;
    _notificacionesActivas = prefs.getBool(_keyNotificaciones) ?? true;
    _cargado = true;
    notifyListeners();
  }

  Future<void> setNotificacionesActivas(bool valor) async {
    _notificacionesActivas = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificaciones, valor);
  }
}
