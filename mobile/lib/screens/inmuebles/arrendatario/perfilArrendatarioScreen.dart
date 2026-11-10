import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/constantes.dart';
import '../../../models/usuario.dart';
import '../../../providers/authProvider.dart';
import '../propietario/configuracionScreen.dart';
import 'misSolicitudesArrendatarioScreen.dart';
import 'MisDatosArrendatarioScreen.dart';

class PerfilArrendatarioScreen extends StatefulWidget {
  const PerfilArrendatarioScreen({super.key});

  @override
  State<PerfilArrendatarioScreen> createState() =>
      _PerfilArrendatarioScreenState();
}

class _PerfilArrendatarioScreenState extends State<PerfilArrendatarioScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  bool _subiendoFoto = false;
  bool _eliminandoFoto = false;

  Future<void> _subirFoto() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _subiendoFoto = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final request = http.MultipartRequest(
          'PATCH', Uri.parse('${Constantes.baseUrl}/auth/foto-perfil'))
        ..headers['Authorization'] = 'Bearer ${auth.token}'
        ..files.add(await http.MultipartFile.fromPath('foto', file.path,
            contentType: MediaType('image', 'jpeg')));
      final res = await request.send();
      final body = jsonDecode(await res.stream.bytesToString());
      if (body['ok'] == true && mounted) {
        Provider.of<AuthProvider>(context, listen: false)
            .actualizarUsuario(Usuario.fromJson(body['datos']));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto de perfil actualizada ✓'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al subir la foto'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _subiendoFoto = false);
    }
  }

  Future<void> _eliminarFoto() async {
    setState(() => _eliminandoFoto = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.delete(
        Uri.parse('${Constantes.baseUrl}/auth/foto-perfil'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final body = jsonDecode(res.body);
      if (body['ok'] == true && mounted) {
        auth.actualizarUsuario(Usuario.fromJson(body['datos']));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto de perfil eliminada'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(body['mensaje'] ?? 'Error al quitar la foto'),
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
      if (mounted) setState(() => _eliminandoFoto = false);
    }
  }

  void _confirmarEliminarFoto() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_outlined, color: _rojo, size: 20),
          SizedBox(width: 8),
          Text('Quitar foto', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text('¿Seguro que querés quitar tu foto de perfil?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarFoto();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Quitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcionesFoto(bool tieneFoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: _verdeOscuro),
              title: const Text('Cambiar foto',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _subirFoto();
              },
            ),
            if (tieneFoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _rojo),
                title: const Text('Quitar foto',
                    style:
                        TextStyle(color: _rojo, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminarFoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;
    final nombre = usuario?.nombre ?? '';
    final email = usuario?.email ?? '';
    final foto = usuario?.fotoPerfil;

    return RefreshIndicator(
      color: _verde,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [
          Center(
            child: Column(children: [
              GestureDetector(
                onTap: (_subiendoFoto || _eliminandoFoto)
                    ? null
                    : () =>
                        _mostrarOpcionesFoto(foto != null && foto.isNotEmpty),
                child: Stack(alignment: Alignment.center, children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _verdeClaro,
                    backgroundImage: (foto != null && foto.isNotEmpty)
                        ? NetworkImage(foto)
                        : null,
                    child: (foto == null || foto.isEmpty)
                        ? Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _verdeOscuro))
                        : null,
                  ),
                  if (_subiendoFoto || _eliminandoFoto)
                    const Positioned.fill(
                        child: CircularProgressIndicator(
                            color: _verdeOscuro, strokeWidth: 2)),
                  if (!_subiendoFoto && !_eliminandoFoto)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: _verde, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              Text(nombre,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 13, color: _gris)),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: _verdeClaro,
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('ARRENDATARIO',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _verdeOscuro)),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(children: [
              _buildTile(
                icono: Icons.person_outline,
                label: 'Mis Datos Personales',
                subtitulo: 'Información académica y contacto',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MisDatosArrendatarioScreen(usuario: usuario),
                    )),
              ),
              const Divider(height: 1, indent: 56),
              _buildTile(
                icono: Icons.send_outlined,
                label: 'Mis Solicitudes',
                subtitulo: 'Estado de tus postulaciones enviadas',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MisSolicitudesArrendatarioScreen(),
                    )),
              ),
              const Divider(height: 1, indent: 56),
              _buildTile(
                icono: Icons.settings_outlined,
                label: 'Configuración',
                subtitulo: 'Notificaciones y preferencias',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConfiguracionScreen())),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.logout, color: _rojo, size: 18),
              ),
              title: const Text('Cerrar Sesión',
                  style: TextStyle(
                      color: _rojo, fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () => _confirmarLogout(context),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('UniHab v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icono,
    required String label,
    required String subtitulo,
    VoidCallback? onTap,
    Color? color,
  }) {
    final c = color ?? _textoOscuro;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: _grisClaro, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: c, size: 18),
      ),
      title: Text(label,
          style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c)),
      subtitle:
          Text(subtitulo, style: const TextStyle(fontSize: 12, color: _gris)),
      trailing:
          onTap != null ? const Icon(Icons.chevron_right, color: _gris) : null,
      onTap: onTap,
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout, color: _rojo, size: 20),
          SizedBox(width: 8),
          Text('Cerrar sesión', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text('¿Estás seguro de que querés cerrar sesión?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
