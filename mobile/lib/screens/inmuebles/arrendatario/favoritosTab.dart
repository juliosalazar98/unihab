import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../providers/authProvider.dart';
import 'detalleInmuebleScreen.dart';
import 'listaFavoritosScreen.dart';
import 'vistosScreen.dart';

class FavoritosTab extends StatefulWidget {
  const FavoritosTab({super.key});

  @override
  State<FavoritosTab> createState() => _FavoritosTabState();
}

class _FavoritosTabState extends State<FavoritosTab> {
  static const _verde = Color(0xFF10B981);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  List<Map<String, dynamic>> _vistosGrupos = [];
  List<Map<String, dynamic>> _listas = [];
  bool _cargando = true;
  bool _modoEdicion = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) setState(() => _cargando = true);
    await Future.wait([_cargarVistos(), _cargarListas()]);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarVistos() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/favoritos/vistos'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _vistosGrupos = List<Map<String, dynamic>>.from(data['datos']);
      }
    } catch (_) {}
  }

  Future<void> _cargarListas() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/favoritos/listas'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _listas = List<Map<String, dynamic>>.from(data['datos']);
      }
    } catch (_) {}
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
          final grupo = _vistosGrupos.firstWhere((g) => g['fecha'] == fecha);
          (grupo['items'] as List).removeAt(idx);
          if ((grupo['items'] as List).isEmpty) {
            _vistosGrupos.removeWhere((g) => g['fecha'] == fecha);
          }
          if (_vistosGrupos.isEmpty) _modoEdicion = false;
        });
      }
    } catch (_) {}
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

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _verde));
    }

    return RefreshIndicator(
      color: _verde,
      onRefresh: _cargar,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Favoritos',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
            ),
          ),
          if (_vistosGrupos.isNotEmpty)
            SliverToBoxAdapter(child: _buildEntradaVistos()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: const Text('Mis listas',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
            ),
          ),
          if (_listas.isEmpty)
            SliverToBoxAdapter(child: _buildListasVacias())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildListaCard(_listas[i]),
                  childCount: _listas.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildEntradaVistos() {
    final todosLosItems = _vistosGrupos
        .expand((g) => (g['items'] as List).cast<Map<String, dynamic>>())
        .toList();
    final total = todosLosItems.length;
    final thumbnails =
        todosLosItems.take(3).map((i) => i['thumbnail'] as String?).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VistosScreen(grupos: List.from(_vistosGrupos)),
          ),
        ).then((_) => _cargar()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            SizedBox(
              width: thumbnails.length > 1
                  ? 48.0 + (thumbnails.length - 1) * 22.0
                  : 48,
              height: 48,
              child: Stack(
                children: List.generate(thumbnails.length, (i) {
                  final url = thumbnails[i];
                  return Positioned(
                    left: i * 22.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                        color: _grisClaro,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url != null
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.home_outlined,
                                color: _gris, size: 20),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vistos recientemente',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro)),
                  const SizedBox(height: 2),
                  Text(
                    '$total inmueble${total == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: _gris),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _gris),
          ]),
        ),
      ),
    );
  }

  Widget _buildVistosHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
      child: Row(children: [
        const Text('Vistos recientemente',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const Spacer(),
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
      ]),
    );
  }

  Widget _buildVistosCard(Map<String, dynamic> item, String fecha, int idx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetalleInmuebleScreen(inmuebleId: item['inmuebleId'] as int),
          ),
        ).then((_) => _cargarVistos().then((_) => setState(() {}))),
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
                    child: const Icon(Icons.home_outlined, color: _gris)),
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
                margin: const EdgeInsets.only(left: 8),
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

  Widget _buildListaCard(Map<String, dynamic> lista) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListaFavoritosScreen(listaId: lista['id'] as int),
        ),
      ).then((_) => _cargarListas().then((_) => setState(() {}))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: lista['thumbnail'] != null
                      ? CachedNetworkImage(
                          imageUrl: lista['thumbnail'] as String,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          color: _grisClaro,
                          child: const Center(
                              child: Icon(Icons.home_outlined,
                                  size: 40, color: _gris)),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle),
                    child:
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(lista['nombre'] as String,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(
            '${lista['total']} inmueble${(lista['total'] as int) == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: _gris),
          ),
        ],
      ),
    );
  }

  Widget _buildListasVacias() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: _grisClaro, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Icon(Icons.favorite_border, size: 48, color: _gris),
          const SizedBox(height: 12),
          const Text('Aún no tenés listas de favoritos',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Tocá el ♡ en cualquier inmueble para guardarlo en una lista.',
            style: TextStyle(fontSize: 13, color: _gris, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
