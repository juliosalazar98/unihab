import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '/config/constantes.dart';
import '/providers/authProvider.dart';
import 'perfilEstudianteScreen.dart';

class HistorialSolicitudesScreen extends StatefulWidget {
  const HistorialSolicitudesScreen({super.key});

  @override
  State<HistorialSolicitudesScreen> createState() =>
      _HistorialSolicitudesScreenState();
}

class _HistorialSolicitudesScreenState
    extends State<HistorialSolicitudesScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  List<dynamic> _solicitudes = [];
  bool _cargando = true;

  Map<String, dynamic> _estadoData(String? estado) {
    switch (estado) {
      case 'RECHAZADA':
        return {
          'label': 'Rechazada',
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'icono': Icons.cancel_outlined,
        };
      case 'ATENDIDA':
      default:
        return {
          'label': 'Atendida',
          'color': _verde,
          'bg': _verdeClaro,
          'icono': Icons.check_circle_outline,
        };
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/solicitudes/atendidas'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() => _solicitudes = data['datos'] as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _contactar(String telefono, String nombre) async {
    final msg = Uri.encodeComponent(
        '¡Hola $nombre! Te contacto desde UniHab. ¿Sigues interesado en el inmueble?');
    final url = Uri.parse('https://wa.me/$telefono?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
        title: const Text('Historial de Solicitudes',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _verde))
          : _solicitudes.isEmpty
              ? _buildVacio()
              : RefreshIndicator(
                  color: _verde,
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _solicitudes.length,
                    itemBuilder: (_, i) => _buildCard(_solicitudes[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(dynamic s) {
    final arr = s['arrendatario'] as Map<String, dynamic>;
    final inm = s['inmueble'] as Map<String, dynamic>;
    final nombre = arr['nombre'] as String? ?? '';
    final email = arr['email'] as String? ?? '';
    final telefono = (arr['telefono'] ?? '').toString().trim();
    final fotoPerfil = arr['fotoPerfil'] as String?;
    final titulo = inm['titulo'] as String? ?? '';
    final zona = inm['zona'] as String? ?? '';
    final fecha = DateTime.tryParse(s['creadoEn'] ?? '');
    final fechaStr =
        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';
    final estado = _estadoData(s['estado'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilEstudianteScreen(estudiante: arr),
                  )),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: _verdeClaro,
                backgroundImage: (fotoPerfil != null && fotoPerfil.isNotEmpty)
                    ? NetworkImage(fotoPerfil)
                    : null,
                child: (fotoPerfil == null || fotoPerfil.isEmpty)
                    ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: _verdeOscuro,
                            fontWeight: FontWeight.bold,
                            fontSize: 15))
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(nombre,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro)),
                  Text(email,
                      style: const TextStyle(fontSize: 11, color: _gris)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estado['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (estado['color'] as Color).withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(estado['icono'] as IconData,
                      size: 11, color: estado['color'] as Color),
                  const SizedBox(width: 4),
                  Text(estado['label'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: estado['color'] as Color)),
                ]),
              ),
              if (fechaStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(fechaStr,
                    style: const TextStyle(fontSize: 10, color: _gris)),
              ],
            ]),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.home_work_outlined, size: 13, color: _gris),
            const SizedBox(width: 6),
            Expanded(
                child: Text(titulo,
                    style: const TextStyle(fontSize: 12, color: _textoOscuro),
                    overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13, color: _gris),
            const SizedBox(width: 6),
            Text(zona, style: const TextStyle(fontSize: 12, color: _gris)),
          ]),
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _contactar(telefono, nombre),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _verdeClaro,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _verde.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_outlined, size: 15, color: _verdeOscuro),
                  const SizedBox(width: 6),
                  Text(telefono,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _verdeOscuro,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      const Text('Sin historial todavía',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280))),
      const SizedBox(height: 8),
      Text('Las solicitudes atendidas aparecerán aquí.',
          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
    ]));
  }
}
