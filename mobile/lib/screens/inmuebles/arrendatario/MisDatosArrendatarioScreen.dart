import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/constantes.dart';
import '../../../models/usuario.dart';
import '../../../providers/authProvider.dart';

class MisDatosArrendatarioScreen extends StatefulWidget {
  final Usuario? usuario;
  const MisDatosArrendatarioScreen({super.key, this.usuario});

  @override
  State<MisDatosArrendatarioScreen> createState() =>
      _MisDatosArrendatarioScreenState();
}

class _MisDatosArrendatarioScreenState
    extends State<MisDatosArrendatarioScreen> {
  static const _verde = Color(0xFF10B981);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  static const _ciudadesBolivia = [
    'La Paz',
    'Cochabamba',
    'Santa Cruz',
    'Oruro',
    'Potosí',
    'Chuquisaca',
    'Tarija',
    'Beni',
    'Pando',
  ];

  List<dynamic> _puntos = [];
  bool _cargando = true;
  bool _guardando = false;

  String? _categoria;
  int? _puntoSeleccionadoId;
  final _carreraCtrl = TextEditingController();
  String? _genero;
  String? _ciudadOrigen;
  final _telefonoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _carreraCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res =
          await http.get(Uri.parse('${Constantes.baseUrl}/puntos-interes'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true) _puntos = data['datos'] as List;

      String tel = auth.usuario?.telefono ?? '';
      if (tel.startsWith('+591'))
        tel = tel.substring(4);
      else if (tel.startsWith('591')) tel = tel.substring(3);
      _telefonoCtrl.text = tel;

      final pId = auth.usuario?.puntoInteresId;
      if (pId != null) {
        final punto =
            _puntos.firstWhere((p) => p['id'] == pId, orElse: () => null);
        if (punto != null) {
          _categoria = punto['tipo'] as String;
          _puntoSeleccionadoId = pId;
        }
      }

      _carreraCtrl.text = auth.usuario?.carrera ?? '';
      _genero = auth.usuario?.genero;
      _ciudadOrigen = auth.usuario?.ciudadOrigen;
    } catch (_) {}
    setState(() => _cargando = false);
  }

  List<dynamic> get _puntosFiltered => _categoria == null
      ? []
      : _puntos.where((p) => p['tipo'] == _categoria).toList();

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.patch(
        Uri.parse('${Constantes.baseUrl}/auth/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'telefono': '591${_telefonoCtrl.text.trim()}',
          'puntoInteresId': _puntoSeleccionadoId,
          'carrera': _carreraCtrl.text.trim().isEmpty
              ? null
              : _carreraCtrl.text.trim(),
          'genero': _genero,
          'ciudadOrigen': _ciudadOrigen,
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        auth.actualizarUsuario(Usuario.fromJson(data['datos']));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Perfil actualizado correctamente ✓'),
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
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _grisClaro,
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _verde))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccion('Información académica'),
                  const SizedBox(height: 4),
                  Text(
                      'Usamos esto para mostrarte la distancia desde cada inmueble.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  const SizedBox(height: 12),
                  _dropdown(
                    child: DropdownButton<String?>(
                      value: _categoria,
                      isExpanded: true,
                      hint: const Text('Tipo de institución',
                          style: TextStyle(color: _gris, fontSize: 14)),
                      items: const [
                        DropdownMenuItem(
                            value: 'UNIVERSIDAD',
                            child: Text('🎓 Universidad')),
                        DropdownMenuItem(
                            value: 'INSTITUTO', child: Text('🏫 Instituto')),
                        DropdownMenuItem(
                            value: null, child: Text('— No especificar')),
                      ],
                      onChanged: (val) => setState(() {
                        _categoria = val;
                        _puntoSeleccionadoId = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _categoria != null
                        ? _dropdown(
                            key: ValueKey(_categoria),
                            child: DropdownButton<int?>(
                              value: _puntoSeleccionadoId,
                              isExpanded: true,
                              hint: const Text('Nombre de la institución',
                                  style: TextStyle(color: _gris, fontSize: 14)),
                              items: _puntosFiltered
                                  .map((p) => DropdownMenuItem<int>(
                                        value: p['id'] as int,
                                        child: Text(p['nombre'] as String,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _puntoSeleccionadoId = val),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _carreraCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco(
                        label: 'Carrera (opcional)',
                        icon: Icons.school_outlined),
                  ),
                  const SizedBox(height: 24),
                  _seccion('Sobre ti'),
                  const SizedBox(height: 14),
                  const Text('Género',
                      style: TextStyle(
                          fontSize: 12,
                          color: _gris,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _buildGeneroButtons(),
                  const SizedBox(height: 16),
                  const Text('Ciudad de origen',
                      style: TextStyle(
                          fontSize: 12,
                          color: _gris,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _dropdown(
                    child: DropdownButton<String?>(
                      value: _ciudadOrigen,
                      isExpanded: true,
                      hint: const Text('Ciudad de origen',
                          style: TextStyle(color: _gris, fontSize: 14)),
                      items: _ciudadesBolivia
                          .map((c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c,
                                    style: const TextStyle(fontSize: 14)),
                              ))
                          .toList()
                        ..add(const DropdownMenuItem(
                            value: null, child: Text('— No especificar'))),
                      onChanged: (val) => setState(() => _ciudadOrigen = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _seccion('Contacto'),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        final v = val?.trim() ?? '';
                        if (v.isEmpty) return 'El número es requerido';
                        if (v.length != 8)
                          return 'El número debe tener 8 dígitos';
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Número celular',
                        prefixText: '+591 ',
                        prefixStyle: const TextStyle(
                            color: _textoOscuro,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        counterText: '',
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: _gris, size: 20),
                        filled: true,
                        fillColor: _grisClaro,
                        labelStyle: const TextStyle(color: _gris, fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: _verde, width: 1.5)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFEF4444), width: 1.5)),
                      ),
                    ),
                  ),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneroButtons() {
    const opciones = [
      {'valor': 'MASCULINO', 'label': 'Masculino', 'icon': Icons.male},
      {'valor': 'FEMENINO', 'label': 'Femenino', 'icon': Icons.female},
      {'valor': 'OTRO', 'label': 'Otro', 'icon': Icons.transgender},
    ];
    return Row(
      children: List.generate(opciones.length, (i) {
        final op = opciones[i];
        final valor = op['valor'] as String;
        final label = op['label'] as String;
        final icon = op['icon'] as IconData;
        final activo = _genero == valor;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _genero = activo ? null : valor),
            child: Container(
              margin: EdgeInsets.only(right: i < opciones.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: activo ? _verde : _grisClaro,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: activo ? _verde : const Color(0xFFE5E7EB)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 22, color: activo ? Colors.white : _gris),
                const SizedBox(height: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: activo ? Colors.white : _textoOscuro)),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _dropdown({required Widget child, Key? key}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
          color: _grisClaro, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  InputDecoration _inputDeco({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _gris, size: 20),
      filled: true,
      fillColor: _grisClaro,
      labelStyle: const TextStyle(color: _gris, fontSize: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _verde, width: 1.5)),
    );
  }

  Widget _seccion(String texto) => Text(texto,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: _textoOscuro));
}
