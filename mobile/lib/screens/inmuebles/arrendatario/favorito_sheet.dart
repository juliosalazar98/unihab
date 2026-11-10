import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../config/constantes.dart';

Future<Map<String, dynamic>?> mostrarFavoritoSheet(
  BuildContext context, {
  required int inmuebleId,
  required String token,
  bool isFavorito = false,
  int? listaId,
  String? nombreLista,
}) async {
  if (isFavorito && listaId != null) {
    try {
      final res = await http.delete(
        Uri.parse(
            '${Constantes.baseUrl}/favoritos/quitar/$listaId/$inmuebleId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        return {
          'action': 'removed',
          'listaId': listaId,
          'nombreLista': data['datos']['nombreLista'] ?? nombreLista ?? '',
        };
      }
    } catch (_) {}
    return null;
  }
  List<Map<String, dynamic>> listas = [];
  try {
    final res = await http.get(
      Uri.parse('${Constantes.baseUrl}/favoritos/listas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) {
      listas = List<Map<String, dynamic>>.from(data['datos']);
    }
  } catch (_) {}

  if (!context.mounted) return null;

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FavoritoSheet(
      inmuebleId: inmuebleId,
      listas: listas,
      token: token,
    ),
  );
}

class _FavoritoSheet extends StatefulWidget {
  final int inmuebleId;
  final List<Map<String, dynamic>> listas;
  final String token;

  const _FavoritoSheet({
    required this.inmuebleId,
    required this.listas,
    required this.token,
  });

  @override
  State<_FavoritoSheet> createState() => _FavoritoSheetState();
}

class _FavoritoSheetState extends State<_FavoritoSheet> {
  static const _verde = Color(0xFF10B981);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);

  bool _creandoNueva = false;
  final _ctrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _creandoNueva = widget.listas.isEmpty;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _guardarEnLista(int listaId, String nombreLista) async {
    setState(() => _guardando = true);
    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/favoritos/guardar'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inmuebleId': widget.inmuebleId, 'listaId': listaId}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        Navigator.pop(context, {
          'action': 'saved',
          'listaId': listaId,
          'nombreLista': nombreLista,
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _crearYGuardar() async {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    try {
      final resLista = await http.post(
        Uri.parse('${Constantes.baseUrl}/favoritos/listas'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombre': nombre}),
      );
      final dataLista = jsonDecode(resLista.body);
      if (dataLista['ok'] != true) {
        setState(() => _guardando = false);
        return;
      }
      final listaId = dataLista['datos']['id'] as int;
      await _guardarEnLista(listaId, nombre);
    } catch (_) {}
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22),
                ),
                const SizedBox(width: 14),
                const Text('Guarda en favoritos',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
            ),
            const Divider(height: 1),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _creandoNueva ? _buildFormCrear() : _buildPickerLista(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCrear() {
    return Padding(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crea una lista de favoritos',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLength: 50,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Nombre',
              filled: true,
              fillColor: _grisClaro,
              counterText: '${_ctrl.text.length}/50 caracteres',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _verde, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: widget.listas.isEmpty
                    ? () => Navigator.pop(context)
                    : () => setState(() => _creandoNueva = false),
                child: const Text('Cancelar',
                    style: TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_guardando || _ctrl.text.trim().isEmpty)
                    ? null
                    : _crearYGuardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  disabledBackgroundColor: _grisClaro,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Crear',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPickerLista() {
    return Column(
      key: const ValueKey('picker'),
      children: [
        ...widget.listas.map((lista) => ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: lista['thumbnail'] != null
                    ? CachedNetworkImage(
                        imageUrl: lista['thumbnail'] as String,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: _grisClaro,
                        child: const Icon(Icons.home_outlined, color: _gris),
                      ),
              ),
              title: Text(lista['nombre'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(
                '${lista['total']} inmueble${(lista['total'] as int) == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              onTap: _guardando
                  ? null
                  : () => _guardarEnLista(
                        lista['id'] as int,
                        lista['nombre'] as String,
                      ),
            )),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Color(0xFF1F2937)),
          ),
          title: const Text('Crear nueva lista',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          onTap: () => setState(() => _creandoNueva = true),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
