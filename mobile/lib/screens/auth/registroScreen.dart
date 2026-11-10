import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/authProvider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _verPass = false;
  bool _verConfirm = false;
  bool _aceptaTerminos = false;
  String _rol = 'ARRENDATARIO';

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validarEmail(String email) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final tel = _telefonoCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (nombre.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Completá todos los campos obligatorios');
      return;
    }
    if (!_validarEmail(email)) {
      _snack('Ingresá un correo válido (ej: tu@email.com)');
      return;
    }
    if (tel.isNotEmpty && tel.length != 8) {
      _snack('El teléfono debe tener 8 dígitos');
      return;
    }
    if (pass.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (pass != confirm) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    if (!_aceptaTerminos) {
      _snack('Aceptá los Términos y Condiciones para continuar');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await auth.registrar(
      nombre,
      email,
      pass,
      _rol,
      telefono: tel.isNotEmpty ? tel : null,
    );

    if (!mounted) return;
    if (data['ok'] == true) {
      if (auth.esPropietario) {
        Navigator.pushReplacementNamed(context, '/propietario-home');
      } else {
        Navigator.pushReplacementNamed(context, '/arrendatario-home');
      }
    } else {
      _snack(data['mensaje'] ?? 'Error al registrarse');
    }
  }

  Future<void> _loginConGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            '338158048579-lngn8gvrap2k5au6a83ejnca44sasjvo.apps.googleusercontent.com',
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        _snack('Error al obtener token de Google');
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.loginConGoogle(idToken);

      if (!mounted) return;
      if (data['ok'] == true) {
        if (auth.esPropietario) {
          Navigator.pushReplacementNamed(context, '/propietario-home');
        } else {
          Navigator.pushReplacementNamed(context, '/arrendatario-home');
        }
      } else {
        _snack(data['mensaje'] ?? 'Error al registrarse con Google');
      }
    } catch (e) {
      _snack('Error al conectar con Google');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1F2937),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _verde,
      body: Column(children: [
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: _verde,
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Crear cuenta',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Registrate para encontrar tu espacio',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CustomPaint(painter: _GooglePainter()),
                                ),
                                const SizedBox(width: 12),
                                const Text('Continuar con Google',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87)),
                              ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o registrate con email',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ]),
                      const SizedBox(height: 20),
                      _label('Nombre completo *'),
                      const SizedBox(height: 8),
                      _campo(_nombreCtrl, 'Ej: Ariana López',
                          icono: Icons.person_outline),
                      const SizedBox(height: 14),
                      _label('Correo electrónico *'),
                      const SizedBox(height: 8),
                      _campo(_emailCtrl, 'tu@email.com',
                          tipo: TextInputType.emailAddress,
                          icono: Icons.email_outlined),
                      const SizedBox(height: 14),
                      _label('Teléfono / WhatsApp (opcional)'),
                      const SizedBox(height: 8),
                      _campoCelular(),
                      const SizedBox(height: 14),
                      _label('Tipo de cuenta *'),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          _rolBtn('🎓 Busco hospedaje', 'ARRENDATARIO'),
                          _rolBtn('🏠 Soy propietario', 'PROPIETARIO'),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _label('Contraseña *'),
                      const SizedBox(height: 8),
                      _campoPass(_passwordCtrl, _verPass,
                          () => setState(() => _verPass = !_verPass)),
                      const SizedBox(height: 14),
                      _label('Confirmar contraseña *'),
                      const SizedBox(height: 8),
                      _campoPass(_confirmCtrl, _verConfirm,
                          () => setState(() => _verConfirm = !_verConfirm)),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _aceptaTerminos = !_aceptaTerminos),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _aceptaTerminos,
                                activeColor: _verde,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) =>
                                    setState(() => _aceptaTerminos = v!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(TextSpan(
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.5),
                                children: [
                                  const TextSpan(
                                      text: 'Al registrarte aceptás los '),
                                  TextSpan(
                                    text: 'Términos y Condiciones',
                                    style: const TextStyle(
                                        color: _verde,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(text: ' de UniHab.'),
                                ],
                              )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: auth.cargando ? null : _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _verde,
                            disabledBackgroundColor: _gris,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: auth.cargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Crear cuenta',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Ya tenés cuenta? ',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Iniciá sesión',
                                  style: TextStyle(
                                      color: _verde,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ]),
                    ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String texto) => Text(texto,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _textoOscuro));

  Widget _campo(
    TextEditingController ctrl,
    String hint, {
    TextInputType tipo = TextInputType.text,
    IconData? icono,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        style: const TextStyle(fontSize: 14, color: _textoOscuro),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon:
              icono != null ? Icon(icono, size: 18, color: _gris) : null,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );

  Widget _campoCelular() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: const Row(children: [
              Text('🇧🇴', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('+591',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textoOscuro)),
            ]),
          ),
          Expanded(
            child: TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14, color: _textoOscuro),
              decoration: const InputDecoration(
                hintText: '78787878',
                hintStyle: TextStyle(color: _gris),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                counterText: '',
              ),
            ),
          ),
        ]),
      );

  Widget _campoPass(
    TextEditingController ctrl,
    bool ver,
    VoidCallback onToggle,
  ) =>
      TextField(
        controller: ctrl,
        obscureText: !ver,
        style: const TextStyle(fontSize: 14, color: _textoOscuro),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: _gris),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(ver ? Icons.visibility_off : Icons.visibility,
                color: _gris, size: 20),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _rolBtn(String texto, String valor) {
    final sel = _rol == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rol = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Center(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? _verdeOscuro : _gris)),
          ),
        ),
      ),
    );
  }
}

class _RegistroFormTab extends StatefulWidget {
  const _RegistroFormTab();

  @override
  State<_RegistroFormTab> createState() => _RegistroFormTabState();
}

class _RegistroFormTabState extends State<_RegistroFormTab> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _grisClaro = Color(0xFFF3F4F6);

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _verPass = false;
  bool _verConfirm = false;
  bool _aceptaTerminos = false;
  String _rol = 'ARRENDATARIO';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validarEmail(String email) =>
      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1F2937),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _loginConGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId:
            '338158048579-lngn8gvrap2k5au6a83ejnca44sasjvo.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _snack('Error al obtener token de Google');
        return;
      }

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.loginConGoogle(idToken);
      if (!mounted) return;
      if (data['ok'] == true) {
        if (auth.esPropietario) {
          Navigator.pushReplacementNamed(context, '/propietario-home');
        } else {
          Navigator.pushReplacementNamed(context, '/arrendatario-home');
        }
      } else {
        _snack(data['mensaje'] ?? 'Error al registrarse con Google');
      }
    } catch (_) {
      _snack('Error al conectar con Google');
    }
  }

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final tel = _telefonoCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (nombre.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Completá todos los campos obligatorios');
      return;
    }
    if (!_validarEmail(email)) {
      _snack('Ingresá un correo válido (ej: tu@email.com)');
      return;
    }
    if (tel.isNotEmpty && tel.length != 8) {
      _snack('El teléfono debe tener 8 dígitos');
      return;
    }
    if (pass.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (pass != confirm) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    if (!_aceptaTerminos) {
      _snack('Aceptá los Términos y Condiciones para continuar');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await auth.registrar(
      nombre,
      email,
      pass,
      _rol,
      telefono: tel.isNotEmpty ? tel : null,
    );

    if (!mounted) return;
    if (data['ok'] == true) {
      if (auth.esPropietario) {
        Navigator.pushReplacementNamed(context, '/propietario-home');
      } else {
        Navigator.pushReplacementNamed(context, '/arrendatario-home');
      }
    } else {
      _snack(data['mensaje'] ?? 'Error al registrarse');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _loginConGoogle,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: _GooglePainter())),
              const SizedBox(width: 12),
              const Text('Continuar con Google',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('o registrate con email',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ]),
        const SizedBox(height: 20),
        _label('Nombre completo *'),
        const SizedBox(height: 8),
        _campo(_nombreCtrl, 'Ej: Ariana López', icono: Icons.person_outline),
        const SizedBox(height: 14),
        _label('Correo electrónico *'),
        const SizedBox(height: 8),
        _campo(_emailCtrl, 'tu@email.com',
            tipo: TextInputType.emailAddress, icono: Icons.email_outlined),
        const SizedBox(height: 14),
        _label('Teléfono / WhatsApp (opcional)'),
        const SizedBox(height: 8),
        _campoCelular(),
        const SizedBox(height: 14),
        _label('Tipo de cuenta *'),
        const SizedBox(height: 8),
        Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _grisClaro,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            _rolBtn('🎓 Busco hospedaje', 'ARRENDATARIO'),
            _rolBtn('🏠 Soy propietario', 'PROPIETARIO'),
          ]),
        ),
        const SizedBox(height: 14),
        _label('Contraseña *'),
        const SizedBox(height: 8),
        _campoPass(_passwordCtrl, _verPass,
            () => setState(() => _verPass = !_verPass)),
        const SizedBox(height: 14),
        _label('Confirmar contraseña *'),
        const SizedBox(height: 8),
        _campoPass(_confirmCtrl, _verConfirm,
            () => setState(() => _verConfirm = !_verConfirm)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => _aceptaTerminos = !_aceptaTerminos),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _aceptaTerminos,
                activeColor: _verde,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                onChanged: (v) => setState(() => _aceptaTerminos = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(TextSpan(
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[600], height: 1.5),
                children: [
                  const TextSpan(text: 'Al registrarte aceptás los '),
                  const TextSpan(
                      text: 'Términos y Condiciones',
                      style: TextStyle(
                          color: _verde, fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' de UniHab.'),
                ],
              )),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: auth.cargando ? null : _registrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              disabledBackgroundColor: _gris,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: auth.cargando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Crear cuenta',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _label(String texto) => Text(texto,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _textoOscuro));

  Widget _campo(TextEditingController ctrl, String hint,
          {TextInputType tipo = TextInputType.text, IconData? icono}) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        style: const TextStyle(fontSize: 14, color: _textoOscuro),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon:
              icono != null ? Icon(icono, size: 18, color: _gris) : null,
          filled: true,
          fillColor: _grisClaro,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );

  Widget _campoCelular() => Container(
        decoration: BoxDecoration(
          color: _grisClaro,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: const Row(children: [
              Text('🇧🇴', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('+591',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textoOscuro)),
            ]),
          ),
          Expanded(
            child: TextField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 14, color: _textoOscuro),
              decoration: const InputDecoration(
                hintText: '78787878',
                hintStyle: TextStyle(color: _gris),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                counterText: '',
              ),
            ),
          ),
        ]),
      );

  Widget _campoPass(
          TextEditingController ctrl, bool ver, VoidCallback onToggle) =>
      TextField(
        controller: ctrl,
        obscureText: !ver,
        style: const TextStyle(fontSize: 14, color: _textoOscuro),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline, size: 18, color: _gris),
          filled: true,
          fillColor: _grisClaro,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(ver ? Icons.visibility_off : Icons.visibility,
                color: _gris, size: 20),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _rolBtn(String texto, String valor) {
    final sel = _rol == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rol = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Center(
            child: Text(texto,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? _verdeOscuro : _gris)),
          ),
        ),
      ),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    double start = -90.0;
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width * 0.36),
        start * 3.14159 / 180,
        90 * 3.14159 / 180,
        false,
        paint,
      );
      start += 90;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
