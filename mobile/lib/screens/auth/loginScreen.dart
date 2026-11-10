import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/authProvider.dart';
import '../../config/constantes.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _verPassword = false;
  int _tabSeleccionado = 0;

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validarEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  Future<void> _loginConGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId:
            '338158048579-vkl2mjprf7qia4vv4r17f5naj0neuu95.apps.googleusercontent.com',
      );

      // Limpia la sesión cacheada para que siempre muestre el selector de cuentas.
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // usuario canceló

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
        _snack(data['mensaje'] ?? 'Error al iniciar sesión con Google');
      }
    } catch (e) {
      _snack('Error al iniciar sesión con Google');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Completá todos los campos');
      return;
    }
    if (!_validarEmail(email)) {
      _snack('Ingresá un correo válido (ej: tu@email.com)');
      return;
    }
    if (password.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await auth.login(email, password);
    if (!mounted) return;

    if (data['ok'] == true) {
      if (auth.esPropietario) {
        Navigator.pushReplacementNamed(context, '/propietario-home');
      } else {
        Navigator.pushReplacementNamed(context, '/arrendatario-home');
      }
    } else {
      _snack(data['mensaje'] ?? 'Correo o contraseña incorrectos');
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

  void _mostrarOlvidePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _OlvidePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _verde,
      body: Column(children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            color: _verde,
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/milogo.png',
                  width: 160,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 1),
                Text('Encontrá tu espacio ideal',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 16)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 8,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    _tabBtn('Iniciar sesión', 0),
                    _tabBtn('Registrarse', 1),
                  ]),
                ),
                const SizedBox(height: 28),
                if (_tabSeleccionado == 0) ...[
                  _label('Correo electrónico'),
                  const SizedBox(height: 8),
                  _campo(
                    controller: _emailController,
                    hint: 'tu@email.com',
                    tipo: TextInputType.emailAddress,
                    icono: Icons.email_outlined,
                  ),
                  const SizedBox(height: 18),
                  _label('Contraseña'),
                  const SizedBox(height: 8),
                  _campoPassword(
                    controller: _passwordController,
                    ver: _verPassword,
                    onToggle: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _mostrarOlvidePassword,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                            color: _verde,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: auth.cargando ? null : _login,
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
                          : const Text('Iniciar sesión',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _dividerO(),
                  const SizedBox(height: 16),
                  _botonGoogle(),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                      'Creá tu cuenta como estudiante con Google,\no registrate con correo para elegir tu rol',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  _botonGoogle(),
                  const SizedBox(height: 16),
                  _dividerO(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/registro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verde,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Registrarse con email',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Al registrarte aceptás nuestros Términos y Condiciones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400], height: 1.5)),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _tabBtn(String texto, int index) {
    final sel = _tabSeleccionado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabSeleccionado = index),
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
                    fontSize: 14,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? _verdeOscuro : _gris)),
          ),
        ),
      ),
    );
  }

  Widget _label(String texto) => Align(
        alignment: Alignment.centerLeft,
        child: Text(texto,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textoOscuro)),
      );

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    TextInputType tipo = TextInputType.text,
    IconData? icono,
  }) =>
      TextField(
        controller: controller,
        keyboardType: tipo,
        style: const TextStyle(fontSize: 14, color: _textoOscuro),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
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
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      );

  Widget _campoPassword({
    required TextEditingController controller,
    required bool ver,
    required VoidCallback onToggle,
  }) =>
      TextField(
        controller: controller,
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
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          suffixIcon: IconButton(
            icon: Icon(ver ? Icons.visibility_off : Icons.visibility,
                color: _gris, size: 20),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _dividerO() => Row(children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('O', style: TextStyle(color: Colors.grey[400])),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ]);

  Widget _botonGoogle() => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _loginConGoogle,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
      );
}

class _OlvidePasswordSheet extends StatefulWidget {
  const _OlvidePasswordSheet();

  @override
  State<_OlvidePasswordSheet> createState() => _OlvidePasswordSheetState();
}

class _OlvidePasswordSheetState extends State<_OlvidePasswordSheet> {
  static const _verde = Color(0xFF10B981);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _grisClaro = Color(0xFFF3F4F6);

  final _emailCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();

  int _paso = 0;
  bool _enviando = false;
  bool _verPass = false;
  String? _error;
  String? _exito;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaPassCtrl.dispose();
    super.dispose();
  }

  void _mostrarError(String msg) {
    setState(() {
      _error = msg;
      _exito = null;
    });
  }

  void _mostrarExito(String msg) {
    setState(() {
      _exito = msg;
      _error = null;
    });
  }

  Future<void> _enviarCodigo() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _mostrarError('Ingresá tu correo');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _paso = 1);
        _mostrarExito('Código enviado a $email ✓');
      } else {
        _mostrarError(data['mensaje'] ?? 'Error al enviar el código');
      }
    } catch (_) {
      _mostrarError('Error de conexión');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _resetearPassword() async {
    final codigo = _codigoCtrl.text.trim();
    final nuevaPass = _nuevaPassCtrl.text.trim();
    if (codigo.length != 6) {
      _mostrarError('El código debe tener 6 dígitos');
      return;
    }
    if (nuevaPass.length < 6) {
      _mostrarError('Mínimo 6 caracteres');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'codigo': codigo,
          'nuevaPassword': nuevaPass,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['ok'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Contraseña actualizada correctamente ✓'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      } else {
        _mostrarError(data['mensaje'] ?? 'Código inválido o expirado');
      }
    } catch (_) {
      _mostrarError('Error de conexión');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.lock_reset_outlined, color: _verde, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            _paso == 0 ? 'Recuperar contraseña' : 'Ingresá el código',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _textoOscuro),
          ),
          const SizedBox(height: 6),
          Text(
            _paso == 0
                ? 'Te enviaremos un código de 6 dígitos a tu correo.'
                : 'Revisá tu bandeja de entrada. El código expira en 15 min.',
            style: const TextStyle(fontSize: 13, color: _gris, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          if (_exito != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _verde.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: _verde, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_exito!,
                      style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          if (_paso == 0) ...[
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 14, color: _textoOscuro),
              decoration: InputDecoration(
                hintText: 'tu@email.com',
                hintStyle: const TextStyle(color: _gris, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.email_outlined, size: 18, color: _gris),
                filled: true,
                fillColor: _grisClaro,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _verde, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  disabledBackgroundColor: _gris,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Enviar código',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
              ),
            ),
          ] else ...[
            TextField(
              controller: _codigoCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                  color: _textoOscuro),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: const TextStyle(
                    color: _gris, letterSpacing: 10, fontSize: 28),
                filled: true,
                fillColor: _grisClaro,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _verde, width: 1.5)),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nuevaPassCtrl,
              obscureText: !_verPass,
              style: const TextStyle(fontSize: 14, color: _textoOscuro),
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                hintStyle: const TextStyle(color: _gris, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.lock_outline, size: 18, color: _gris),
                filled: true,
                fillColor: _grisClaro,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _verde, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                suffixIcon: IconButton(
                  icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility,
                      color: _gris, size: 20),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _resetearPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  disabledBackgroundColor: _gris,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Actualizar contraseña',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: _enviando
                    ? null
                    : () => setState(() {
                          _paso = 0;
                          _error = null;
                          _exito = null;
                        }),
                child: const Text('¿No recibiste el código? Reenviar',
                    style: TextStyle(
                        color: _verde,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icono) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 18, color: _gris),
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
      );
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
