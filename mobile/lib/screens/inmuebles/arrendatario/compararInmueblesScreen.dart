import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/inmueble.dart';
import '../../../providers/authProvider.dart';
import '../../../services/inmuebleService.dart';
import 'detalleInmuebleScreen.dart';

class CompararInmueblesScreen extends StatefulWidget {
  final List<int> ids;
  const CompararInmueblesScreen({super.key, required this.ids});

  @override
  State<CompararInmueblesScreen> createState() =>
      _CompararInmueblesScreenState();
}

class _CompararInmueblesScreenState extends State<CompararInmueblesScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  final InmuebleService _service = InmuebleService();
  List<Inmueble> _inmuebles = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultados = await Future.wait(
      widget.ids.map((id) => _service.obtenerInmueble(id)),
    );
    if (!mounted) return;
    setState(() {
      _inmuebles = resultados.whereType<Inmueble>().toList();
      _cargando = false;
    });
  }

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final p1 = lat1 * pi / 180, p2 = lat2 * pi / 180;
    final dP = (lat2 - lat1) * pi / 180;
    final dL = (lon2 - lon1) * pi / 180;
    final a = sin(dP / 2) * sin(dP / 2) +
        cos(p1) * cos(p2) * sin(dL / 2) * sin(dL / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String? _distancia(Inmueble i) {
    final punto =
        Provider.of<AuthProvider>(context, listen: false).usuario?.puntoInteres;
    if (punto == null || i.latitud == null) return null;
    final m = _haversine(
      i.latitud!,
      i.longitud!,
      (punto['latitud'] as num).toDouble(),
      (punto['longitud'] as num).toDouble(),
    );
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _labelTipo(String t) =>
      {
        'CUARTO': 'Cuarto',
        'DEPARTAMENTO': 'Depto.',
        'COMPARTIDO': 'Compartido',
      }[t] ??
      t;

  int _serviciosCount(Inmueble i) => [
        i.luzIncluida,
        i.aguaIncluida,
        i.internetIncluido,
        i.gasIncluido,
      ].where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: _textoOscuro,
          title: const Text('Comparar',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
        ),
        body: const Center(child: CircularProgressIndicator(color: _verde)),
      );
    }

    if (_inmuebles.length < 2) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: _textoOscuro,
          title: const Text('Comparar'),
        ),
        body: const Center(
          child: Text('No se pudieron cargar los inmuebles',
              style: TextStyle(color: _gris)),
        ),
      );
    }

    final precios = _inmuebles.map((i) => i.precio).toList();
    final precioMin = precios.reduce(min);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        title: Text('Comparar ${_inmuebles.length} inmuebles',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
        children: [
          _buildCabecera(precioMin),
          const SizedBox(height: 20),
          _seccion('Ubicación'),
          _fila('Zona', _inmuebles.map((i) => i.zona).toList()),
          _fila('Distancia a tu institución',
              _inmuebles.map((i) => _distancia(i) ?? '—').toList(),
              destacarMenor: true),
          const SizedBox(height: 18),
          _seccion('Servicios incluidos'),
          _filaBool('💡 Luz', _inmuebles.map((i) => i.luzIncluida).toList()),
          _filaBool('💧 Agua', _inmuebles.map((i) => i.aguaIncluida).toList()),
          _filaBool('📶 Internet',
              _inmuebles.map((i) => i.internetIncluido).toList()),
          _filaBool('🔥 Gas', _inmuebles.map((i) => i.gasIncluido).toList()),
          _fila('Total incluidos',
              _inmuebles.map((i) => '${_serviciosCount(i)}/4').toList(),
              destacarMayor: true),
          const SizedBox(height: 18),
          _seccion('Características'),
          _fila('Tipo', _inmuebles.map((i) => _labelTipo(i.tipo)).toList()),
          _fila(
              'Oferta',
              _inmuebles
                  .map((i) => i.tipoOferta == 'ANTICRETICO'
                      ? 'Anticrético'
                      : 'Alquiler')
                  .toList()),
          _fila(
              'Tamaño',
              _inmuebles
                  .map((i) => i.tamano != null
                      ? '${i.tamano!.toStringAsFixed(0)} m²'
                      : '—')
                  .toList()),
          _fila(
              'Piso',
              _inmuebles
                  .map((i) => i.piso != null ? 'Piso ${i.piso}' : '—')
                  .toList()),
          _fila(
              'Dormitorios',
              _inmuebles
                  .map((i) => i.numDormitorios?.toString() ?? '—')
                  .toList()),
          _fila('Baños',
              _inmuebles.map((i) => i.numBanos?.toString() ?? '—').toList()),
          _filaBool(
              'Amoblado', _inmuebles.map((i) => i.amoblado ?? false).toList()),
          _filaBool('Permite mascotas',
              _inmuebles.map((i) => i.permiteMascotas ?? false).toList()),
          _filaBool('Parqueo',
              _inmuebles.map((i) => i.tieneParqueo ?? false).toList()),
          const SizedBox(height: 24),
          _buildBotones(),
        ],
      ),
    );
  }

  Widget _buildCabecera(double precioMin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _inmuebles.map((i) {
        final esMasBarato = i.precio == precioMin;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: i.imagenes.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: i.imagenes.first.url,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 90,
                          color: _grisClaro,
                          child: const Icon(Icons.home_outlined, color: _gris),
                        ),
                      )
                    : Container(
                        height: 90,
                        color: _grisClaro,
                        child: const Icon(Icons.home_outlined, color: _gris),
                      ),
              ),
              const SizedBox(height: 8),
              Text(i.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: esMasBarato ? _verdeClaro : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bs. ${_formatearMiles(i.precio)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: esMasBarato ? _verdeOscuro : _textoOscuro),
                ),
              ),
              if (esMasBarato)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('Más barato',
                      style: TextStyle(
                          fontSize: 9,
                          color: _verdeOscuro,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(titulo.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _gris,
              letterSpacing: 0.6)),
    );
  }

  Widget _fila(String label, List<String> valores,
      {bool destacarMenor = false, bool destacarMayor = false}) {
    int? indiceDestacado;

    if (destacarMenor || destacarMayor) {
      final nums = valores.map((v) {
        final m = RegExp(r'[\d.]+').firstMatch(v.replaceAll(',', '.'));
        return m != null ? double.tryParse(m.group(0)!) : null;
      }).toList();

      final validos = nums.where((n) => n != null).cast<double>().toList();
      if (validos.length > 1) {
        final objetivo =
            destacarMenor ? validos.reduce(min) : validos.reduce(max);
        indiceDestacado = nums.indexWhere((n) => n == objetivo);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(
          children: List.generate(valores.length, (idx) {
            final destacado = indiceDestacado == idx;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  valores[idx],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
                    color: destacado ? _verdeOscuro : _textoOscuro,
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _filaBool(String label, List<bool> valores) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(
          children: valores
              .map((v) => Expanded(
                    child: Icon(
                      v ? Icons.check_circle : Icons.remove_circle_outline,
                      size: 18,
                      color: v ? _verde : const Color(0xFFD1D5DB),
                    ),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: _inmuebles.map((i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DetalleInmuebleScreen(inmuebleId: i.id)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ver',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
