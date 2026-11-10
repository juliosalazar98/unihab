import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/authProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.cargarSesion();
    if (!mounted) return;

    if (auth.autenticado && auth.usuario != null) {
      final ruta =
          auth.esPropietario ? '/propietario-home' : '/arrendatario-home';
      Navigator.pushReplacementNamed(context, ruta);
    } else {
      // Token inválido/expirado sin datos de respaldo → limpia y va a bienvenida
      if (auth.autenticado) await auth.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 160, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }
}
