import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/config/constantes.dart';
import '/providers/authProvider.dart';

class MisDatosPropietarioScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;
  const MisDatosPropietarioScreen({super.key, required this.perfil});

  @override
  State<MisDatosPropietarioScreen> createState() =>
      _MisDatosPropietarioScreenState();
}

class _MisDatosPropietarioScreenState extends State<MisDatosPropietarioScreen> {
  static const _verde = Color(0xFF10B981);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirm = false;
  bool _guardando = false;
  bool _cambiarPass = false;

  @override
  void initState() {
    super.initState();
    final tel = widget.perfil['telefono'] as String? ?? '';
    if (tel.startsWith('591') && tel.length == 11) {
      _telefonoCtrl.text = tel.substring(3);
    } else if (tel.startsWith('+591') && tel.length == 12) {
      _telefonoCtrl.text = tel.substring(4);
    } else {
      _telefonoCtrl.text = tel;
    }
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (_cambiarPass && _passNuevaCtrl.text.isNotEmpty) {
        final resPass = await http.patch(
          Uri.parse('${Constantes.baseUrl}/auth/cambiar-password'),
          headers: {
            'Authorization': 'Bearer ${auth.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'passwordActual': _passActualCtrl.text,
            'passwordNueva': _passNuevaCtrl.text,
          }),
        );
        final dataPass = jsonDecode(resPass.body);
        if (!mounted) return;
        if (dataPass['ok'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(dataPass['mensaje'] ?? 'Error al cambiar la contraseña'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ));
          setState(() => _guardando = false);
          return;
        }
      }

      final res = await http.patch(
        Uri.parse('${Constantes.baseUrl}/auth/perfil'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'telefono': '591${_telefonoCtrl.text.trim()}'}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Datos actualizados ✓'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al guardar'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        title: const Text('Mis Datos Personales',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seccionTitulo('Contacto'),
            const SizedBox(height: 12),
            _campoCelular(),
            const SizedBox(height: 24),
            Row(children: [
              _seccionTitulo('Cambiar contraseña'),
              const Spacer(),
              Switch(
                value: _cambiarPass,
                onChanged: (v) => setState(() => _cambiarPass = v),
                activeColor: _verde,
              ),
            ]),
            if (_cambiarPass) ...[
              const SizedBox(height: 12),
              _campoPassword(
                controller: _passActualCtrl,
                label: 'Contraseña actual',
                ver: _verActual,
                onVerTap: () => setState(() => _verActual = !_verActual),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              _campoPassword(
                controller: _passNuevaCtrl,
                label: 'Nueva contraseña',
                ver: _verNueva,
                onVerTap: () => setState(() => _verNueva = !_verNueva),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              _campoPassword(
                controller: _passConfirmCtrl,
                label: 'Confirmar contraseña',
                ver: _verConfirm,
                onVerTap: () => setState(() => _verConfirm = !_verConfirm),
                validator: (v) => v != _passNuevaCtrl.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Guardar cambios',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoCelular() {
    return FormField<String>(
      validator: (_) {
        final val = _telefonoCtrl.text.trim();
        if (val.isEmpty) return 'Requerido';
        if (val.length != 8) return 'Debe tener exactamente 8 dígitos';
        return null;
      },
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: field.hasError
                    ? const Color(0xFFEF4444)
                    : _telefonoCtrl.text.length == 8
                        ? _verde
                        : const Color(0xFFE5E7EB),
                width: _telefonoCtrl.text.length == 8 ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                  border: Border(
                    right: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                ),
                child: const Row(children: [
                  Text('🇧🇴', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('+591',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937))),
                ]),
              ),
              Expanded(
                child: TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => field.didChange(_telefonoCtrl.text),
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                  decoration: const InputDecoration(
                    hintText: 'Ej: 78787878',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    counterText: '', // oculta el contador de maxLength
                  ),
                ),
              ),
            ]),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(field.errorText!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            ),
        ],
      ),
    );
  }

  Widget _seccionTitulo(String titulo) => Text(titulo,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: _textoOscuro));

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _textoOscuro),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 18, color: _gris),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _verde, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _campoPassword({
    required TextEditingController controller,
    required String label,
    required bool ver,
    required VoidCallback onVerTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: !ver,
      style: const TextStyle(fontSize: 14, color: _textoOscuro),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: _gris),
        suffixIcon: IconButton(
          icon: Icon(
              ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: _gris),
          onPressed: onVerTap,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _verde, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
