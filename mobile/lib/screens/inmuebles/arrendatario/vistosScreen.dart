import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../providers/authProvider.dart';
import 'detalleInmuebleScreen.dart';

class VistosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> grupos;
  const VistosScreen({super.key, required this.grupos});

  @override
  State<VistosScreen> createState() => _VistosScreenState();
}

class _VistosScreenState extends State<VistosScreen> {
  static const _verde = Color(0xFF10B981);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  late List<Map<String, dynamic>> _grupos;
  bool _modoEdicion = false;

  @override
  void initState() {
    super.initState();
    _grupos = widget.grupos
        .map((g) => {
              'fecha': g['fecha'],
              'items': List<Map<String, dynamic>>.from((g['items'] as List)
                  .map((i) => Map<String, dynamic>.from(i as Map))),
            })
        .toList();
  }

  Future<void> _eliminarVisto(int inmuebleId, String fecha, int idx) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await http.delete(
        Uri.parse('${Constantes.baseUrl}/favoritos/vistos/$inmuebleId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        setState(() {
          final grupo = _grupos.firstWhere((g) => g['fecha'] == fecha);
          (grupo['items'] as List).removeAt(idx);
          if ((grupo['items'] as List).isEmpty) {
            _grupos.removeWhere((g) => g['fecha'] == fecha);
          }
          if (_grupos.isEmpty) _modoEdicion = false;
        });
      }
    } catch (_) {}
  }

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _formatearFecha(String isoDate) {
    final fecha = DateTime.parse(isoDate);
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final f = DateTime(fecha.year, fecha.month, fecha.day);

    if (f == hoy) return 'Hoy';
    if (f == ayer) return 'Ayer';

    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo'
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${dias[fecha.weekday - 1]}, ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vistos recientemente',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        actions: [
          if (_grupos.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _modoEdicion = !_modoEdicion),
              child: Text(
                _modoEdicion ? 'Listo' : 'Editar',
                style: TextStyle(
                  color: _modoEdicion ? _verde : _textoOscuro,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _grupos.isEmpty
          ? _buildVacio()
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: _grupos.expand((grupo) {
                final fecha = grupo['fecha'] as String;
                final items =
                    (grupo['items'] as List).cast<Map<String, dynamic>>();
                return [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      _formatearFecha(fecha),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro),
                    ),
                  ),
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _buildItem(item, fecha, i);
                  }),
                ];
              }).toList(),
            ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, String fecha, int idx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetalleInmuebleScreen(inmuebleId: item['inmuebleId'] as int),
          ),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item['thumbnail'] != null
                ? CachedNetworkImage(
                    imageUrl: item['thumbnail'] as String,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 78,
                    height: 78,
                    color: _grisClaro,
                    child: const Icon(Icons.home_outlined, color: _gris),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['titulo'] as String,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textoOscuro),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item['tipo'] as String,
                    style: const TextStyle(fontSize: 12, color: _gris)),
                const SizedBox(height: 3),
                Text(
                  'Bs. ${_formatearMiles((item['precio'] as num).toDouble())}/mes',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro),
                ),
              ],
            ),
          ),
          if (_modoEdicion)
            GestureDetector(
              onTap: () =>
                  _eliminarVisto(item['inmuebleId'] as int, fecha, idx),
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                width: 28,
                height: 28,
                decoration:
                    BoxDecoration(color: _grisClaro, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: _textoOscuro),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Nada por aquí todavía',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 8),
          Text('Los inmuebles que visites\naparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[400], height: 1.5)),
        ],
      ),
    );
  }
}
