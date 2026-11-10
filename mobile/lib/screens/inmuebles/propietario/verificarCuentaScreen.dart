import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '/config/constantes.dart';
import '/providers/authProvider.dart';

class VerificarCuentaScreen extends StatefulWidget {
  const VerificarCuentaScreen({super.key});

  @override
  State<VerificarCuentaScreen> createState() => _VerificarCuentaScreenState();
}

class _VerificarCuentaScreenState extends State<VerificarCuentaScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  static const _extensiones = [
    'CB',
    'LP',
    'SC',
    'OR',
    'PT',
    'CH',
    'TJ',
    'BE',
    'PD'
  ];

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ciCtrl = TextEditingController();
  String _extension = 'CB';
  File? _fotoAnverso;
  File? _fotoReverso;
  File? _fotoRostro;
  bool _enviando = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(bool esAnverso) async {
    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF10B981)),
              title: const Text('Tomar foto',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF10B981)),
              title: const Text('Elegir de galería',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );

    if (opcion == null) return;

    final xFile = await _picker.pickImage(
      source: opcion,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() {
        if (esAnverso)
          _fotoAnverso = File(xFile.path);
        else
          _fotoReverso = File(xFile.path);
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoAnverso == null || _fotoReverso == null || _fotoRostro == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debés subir las 3 fotos requeridas'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _enviando = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${Constantes.baseUrl}/verificacion/solicitar'),
      )
        ..headers['Authorization'] = 'Bearer ${auth.token}'
        ..fields['nombre'] = _nombreCtrl.text.trim()
        ..fields['ci'] = _ciCtrl.text.trim()
        ..fields['extension'] = _extension
        ..files.add(await http.MultipartFile.fromPath(
            'fotoAnverso', _fotoAnverso!.path))
        ..files.add(await http.MultipartFile.fromPath(
            'fotoReverso', _fotoReverso!.path))
        ..files.add(
            await http.MultipartFile.fromPath('fotoRostro', _fotoRostro!.path));

      final streamedRes = await req.send();
      final statusCode = streamedRes.statusCode;

      if (!mounted) return;

      if (statusCode == 200 || statusCode == 201) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: _verdeClaro, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline,
                    color: _verde, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('¡Solicitud enviada!',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
              const SizedBox(height: 10),
              const Text(
                'Tus datos están siendo revisados por el equipo de UniHab. '
                'El proceso toma hasta 24 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _gris, height: 1.5),
              ),
            ]),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // cierra dialog
                    Navigator.pop(context); // vuelve al perfil
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _verde,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text('Entendido',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al enviar. Intentá de nuevo.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
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
        title: const Text('Verificar mi Cuenta',
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _verdeClaro,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _verde.withOpacity(0.3))),
              child: const Row(children: [
                Icon(Icons.info_outline, color: _verdeOscuro, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La verificación te otorga la insignia de Propietario Verificado '
                    'y genera más confianza en los estudiantes.',
                    style: TextStyle(
                        fontSize: 12, color: _verdeOscuro, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _seccion('Datos personales'),
            const SizedBox(height: 12),
            _campo(
              controller: _nombreCtrl,
              label: 'Nombre completo',
              icono: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 3,
                child: _campo(
                  controller: _ciCtrl,
                  label: 'Número de C.I.',
                  icono: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _extension,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, color: _textoOscuro),
                      items: _extensiones
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _extension = v ?? 'CB'),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            _seccion('Carnet de Identidad'),
            const SizedBox(height: 4),
            Text('Asegurate de que las fotos sean nítidas y legibles.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _contenedorFoto(
                foto: _fotoAnverso,
                label: 'Anverso',
                onTap: () => _seleccionarFoto(true),
                onQuitar: () => setState(() => _fotoAnverso = null),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _contenedorFoto(
                foto: _fotoReverso,
                label: 'Reverso',
                onTap: () => _seleccionarFoto(false),
                onQuitar: () => setState(() => _fotoReverso = null),
              )),
            ]),
            const SizedBox(height: 12),
            _contenedorRostro(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enviar para revisión',
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

  Widget _seccion(String titulo) => Text(titulo,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: _textoOscuro));

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _verde, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _contenedorFoto({
    required File? foto,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onQuitar,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: foto == null ? onTap : null,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: foto != null ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: foto != null ? _verde : const Color(0xFFE5E7EB),
                width: foto != null ? 2 : 1.5,
              ),
              image: foto != null
                  ? DecorationImage(image: FileImage(foto), fit: BoxFit.cover)
                  : null,
            ),
            child: foto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          color: _gris, size: 30),
                      const SizedBox(height: 8),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _textoOscuro)),
                      const SizedBox(height: 2),
                      const Text('Toca para seleccionar',
                          style: TextStyle(fontSize: 11, color: _gris)),
                    ],
                  )
                : null,
          ),
        ),
        if (foto != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onQuitar,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 15),
              ),
            ),
          ),
        if (foto != null)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration:
                  const BoxDecoration(color: _verde, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _contenedorRostro() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _fotoRostro == null ? () => _seleccionarFotoRostro() : null,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _fotoRostro != null ? Colors.transparent : _grisClaro,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _fotoRostro != null ? _verde : _verde.withOpacity(0.5),
                width: _fotoRostro != null ? 2 : 1.5,
              ),
              image: _fotoRostro != null
                  ? DecorationImage(
                      image: FileImage(_fotoRostro!), fit: BoxFit.cover)
                  : null,
            ),
            child: _fotoRostro == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_box_rounded,
                          color: _verde.withOpacity(0.7), size: 36),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Subir foto de tu rostro\nsosteniendo tu C.I. al lado',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _textoOscuro,
                              height: 1.4),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (_fotoRostro != null)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration:
                  const BoxDecoration(color: _verde, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ),
        if (_fotoRostro != null)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => setState(() => _fotoRostro = null),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 15),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _seleccionarFotoRostro() async {
    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _verde),
              title: const Text('Tomar foto',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _verde),
              title: const Text('Elegir de galería',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );

    if (opcion == null) return;
    final xFile = await _picker.pickImage(source: opcion, imageQuality: 85);
    if (xFile != null && mounted) {
      setState(() => _fotoRostro = File(xFile.path));
    }
  }
}
