import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../providers/authProvider.dart';
import 'detalleInmuebleScreen.dart';
import 'compararInmueblesScreen.dart';

class ListaFavoritosScreen extends StatefulWidget {
  final int listaId;
  const ListaFavoritosScreen({super.key, required this.listaId});

  @override
  State<ListaFavoritosScreen> createState() => _ListaFavoritosScreenState();
}

class _ListaFavoritosScreenState extends State<ListaFavoritosScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  Map<String, dynamic>? _lista;
  List<Map<String, dynamic>> _inmuebles = [];
  bool _cargando = true;
  bool _modoComparar = false;
  final Set<int> _seleccionados = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/favoritos/listas/${widget.listaId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _lista = data['datos'];
        _inmuebles =
            List<Map<String, dynamic>>.from(data['datos']['inmuebles']);
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _quitarDeLista(int inmuebleId, int idx) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.delete(
        Uri.parse(
            '${Constantes.baseUrl}/favoritos/quitar/${widget.listaId}/$inmuebleId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() => _inmuebles.removeAt(idx));
      }
    } catch (_) {}
  }

  void _toggleSeleccion(int id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados.remove(id);
      } else {
        if (_seleccionados.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Podés comparar hasta 3 inmuebles'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ));
          return;
        }
        _seleccionados.add(id);
      }
    });
  }

  void _salirDeComparar() {
    setState(() {
      _modoComparar = false;
      _seleccionados.clear();
    });
  }

  void _abrirComparacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompararInmueblesScreen(ids: _seleccionados.toList()),
      ),
    ).then((_) => _salirDeComparar());
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2)),
          ),
          if (_inmuebles.length >= 2)
            ListTile(
              leading: const Icon(Icons.compare_arrows, color: _verdeOscuro),
              title: const Text('Comparar inmuebles',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Elegí 2 o 3 para ver sus diferencias',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(_);
                setState(() => _modoComparar = true);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Cambiar nombre',
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(_);
              _renombrarLista();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: _rojo),
            title: const Text('Eliminar lista',
                style: TextStyle(color: _rojo, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(_);
              _eliminarLista();
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _renombrarLista() {
    final ctrl =
        TextEditingController(text: _lista?['nombre'] as String? ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Nombre de la lista',
            filled: true,
            fillColor: _grisClaro,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _verde, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_), child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: _verde, elevation: 0),
            onPressed: () async {
              Navigator.pop(_);
              await _guardarNombre(ctrl.text.trim());
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarNombre(String nombre) async {
    if (nombre.isEmpty) return;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.patch(
        Uri.parse(
            '${Constantes.baseUrl}/favoritos/listas/${widget.listaId}/nombre'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombre': nombre}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() => _lista = {...?_lista, 'nombre': nombre});
      }
    } catch (_) {}
  }

  Future<void> _eliminarLista() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar lista?'),
        content: Text(
          'Se eliminará "${_lista?['nombre']}" y todos sus inmuebles guardados.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: _rojo, elevation: 0),
            onPressed: () => Navigator.pop(_, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await http.delete(
        Uri.parse('${Constantes.baseUrl}/favoritos/listas/${widget.listaId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _verde)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _modoComparar && _seleccionados.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _abrirComparacion,
              backgroundColor: _verde,
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              label: Text('Comparar (${_seleccionados.length})',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black12,
            foregroundColor: _textoOscuro,
            leading: IconButton(
              icon: Icon(_modoComparar ? Icons.close : Icons.arrow_back),
              onPressed: _modoComparar
                  ? _salirDeComparar
                  : () => Navigator.pop(context),
            ),
            actions: [
              if (!_modoComparar)
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _mostrarOpciones,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(
                _modoComparar
                    ? 'Elegí 2 o 3 inmuebles'
                    : (_lista?['nombre'] as String? ?? ''),
                style: const TextStyle(
                  color: _textoOscuro,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),
          if (_inmuebles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border, size: 56, color: _gris),
                    const SizedBox(height: 16),
                    const Text('Lista vacía',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _textoOscuro)),
                    const SizedBox(height: 8),
                    Text('Guardá inmuebles para verlos aquí.',
                        style: TextStyle(fontSize: 13, color: _gris)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(_inmuebles[i], i),
                  childCount: _inmuebles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int idx) {
    final id = item['id'] as int;

    if (_modoComparar) {
      final sel = _seleccionados.contains(id);
      return GestureDetector(
        onTap: () => _toggleSeleccion(id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: sel ? _verdeClaro : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: sel ? _verde : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: item['thumbnail'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['thumbnail'] as String,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: _grisClaro,
                          child: const Icon(Icons.home_outlined, color: _gris)),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: _grisClaro,
                      child: const Icon(Icons.home_outlined, color: _gris)),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['titulo'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _textoOscuro),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      'Bs. ${_formatearMiles((item['precio'] as num).toDouble())}/mes',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _verde),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                sel ? Icons.check_circle : Icons.circle_outlined,
                color: sel ? _verde : const Color(0xFFD1D5DB),
                size: 24,
              ),
            ),
          ]),
        ),
      );
    }

    return Dismissible(
      key: Key('fav_${item['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: _rojo, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _quitarDeLista(item['id'] as int, idx),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetalleInmuebleScreen(inmuebleId: item['id'] as int),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: item['thumbnail'] != null
                  ? CachedNetworkImage(
                      imageUrl: item['thumbnail'] as String,
                      width: 110,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 110,
                      height: 100,
                      color: _grisClaro,
                      child: const Icon(Icons.home_outlined, color: _gris)),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['titulo'] as String,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _textoOscuro),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item['zona'] as String,
                        style: const TextStyle(fontSize: 12, color: _gris)),
                    const SizedBox(height: 6),
                    Text(
                      'Bs. ${_formatearMiles((item['precio'] as num).toDouble())}/mes',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _verde),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _quitarDeLista(item['id'] as int, idx),
                child: Icon(Icons.favorite,
                    color: _rojo.withOpacity(0.8), size: 22),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
