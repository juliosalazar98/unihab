import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../models/inmueble.dart';
import '../../../providers/authProvider.dart';
import 'detalleInmuebleScreen.dart';

class MapaArrendatarioScreen extends StatefulWidget {
  const MapaArrendatarioScreen({super.key});

  @override
  State<MapaArrendatarioScreen> createState() => _MapaArrendatarioScreenState();
}

class _MapaArrendatarioScreenState extends State<MapaArrendatarioScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  static const LatLng _centroCbba = LatLng(-17.3895, -66.1568);
  final Completer<GoogleMapController> _completer = Completer();
  GoogleMapController? _ctrl;
  Set<Marker> _markers = {};
  List<Inmueble> _inmuebles = [];
  Inmueble? _seleccionado;
  bool _cargando = true;
  bool _mostrarPreview = false;
  double? _precioMax;
  String? _tipoFiltro;
  double? _radioKm;
  BitmapDescriptor? _iconUniversidad;

  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    Future.microtask(_inicializar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authProvider == null) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider!.addListener(_onAuthCambio);
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthCambio); // ← el ? evita el crash
    _ctrl?.dispose();
    super.dispose();
  }

  void _onAuthCambio() {
    if (!mounted) return;
    if (_authProvider?.usuario == null) return; // cerró sesión → salir

    final punto = _authProvider!.usuario?.puntoInteres;

    _prepararIconUniversidad().then((_) {
      if (!mounted) return;
      _construirMarcadores();
    });

    if (punto != null && _ctrl != null) {
      _ctrl!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(
          (punto['latitud'] as num).toDouble(),
          (punto['longitud'] as num).toDouble(),
        ),
        14,
      ));
    }
  }

  Future<void> _inicializar() async {
    await Future.wait([
      _cargarInmuebles(),
      _prepararIconUniversidad(),
    ]);
    await _construirMarcadores();
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarInmuebles() async {
    try {
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/inmuebles?page=1&limit=100'),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        _inmuebles = (data['datos']['inmuebles'] as List)
            .map((e) => Inmueble.fromJson(e))
            .where((i) => i.latitud != null && i.longitud != null)
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _prepararIconUniversidad() async {
    try {
      const double sz = 100; // ← era 56
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawCircle(
          const Offset(sz / 2, sz / 2 + 3),
          sz / 2 - 2,
          Paint()
            ..color = Colors.black.withOpacity(0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawCircle(const Offset(sz / 2, sz / 2), sz / 2 - 2,
          Paint()..color = _verdeOscuro);
      c.drawCircle(
          const Offset(sz / 2, sz / 2),
          sz / 2 - 2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4); // ← era 3
      final tp = TextPainter(
        text: const TextSpan(
            text: '🎓', style: TextStyle(fontSize: 60)), // ← era 26
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(sz / 2 - tp.width / 2, sz / 2 - tp.height / 2));

      final img = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      _iconUniversidad = BitmapDescriptor.fromBytes(bd!.buffer.asUint8List());
    } catch (_) {
      _iconUniversidad =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  Future<BitmapDescriptor> _burbujaPrecio(double precio,
      {bool seleccionado = false}) async {
    final texto = 'Bs. ${_formatearMiles(precio)}';

    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontSize: 41, // ← era 13
          fontWeight: FontWeight.bold,
          color: seleccionado ? Colors.white : _textoOscuro,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 36.0; // era 18
    const padV = 16.0; // era 11
    const arrow = 15.0; // era 10

    final w = tp.width + padH * 2;
    final bH = tp.height + padV * 2;
    final h = bH + arrow;
    final bg = seleccionado ? _verdeOscuro : Colors.white;

    final rec = ui.PictureRecorder();
    final c = Canvas(rec);

    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, bH),
      const Radius.circular(26), // ← era 22
    );
    c.drawRRect(
      rr.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    c.drawRRect(rr, Paint()..color = bg);
    if (!seleccionado) {
      c.drawRRect(
          rr,
          Paint()
            ..color = const Color(0xFFD1D5DB)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    c.drawPath(
      Path()
        ..moveTo(w / 2 - 8, bH)
        ..lineTo(w / 2 + 8, bH)
        ..lineTo(w / 2, h)
        ..close(),
      Paint()..color = bg,
    );

    tp.paint(c, Offset(padH, padV));

    final img = await rec.endRecording().toImage(w.ceil(), h.ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bd!.buffer.asUint8List());
  }

  Future<void> _construirMarcadores() async {
    final auth = _authProvider;
    if (auth == null) return;
    final punto = auth.usuario?.puntoInteres;
    final Set<Marker> set = {};
    if (punto != null) {
      final lat = (punto['latitud'] as num).toDouble();
      final lng = (punto['longitud'] as num).toDouble();
      set.add(Marker(
        markerId: const MarkerId('universidad'),
        position: LatLng(lat, lng),
        icon: _iconUniversidad ?? BitmapDescriptor.defaultMarker,
        infoWindow:
            InfoWindow(title: punto['nombre'] as String? ?? 'Tu institución'),
        zIndex: 3,
      ));
    }
    for (final i in _inmueblesFiltrados) {
      final sel = _seleccionado?.id == i.id;
      BitmapDescriptor icon;
      try {
        icon = await _burbujaPrecio(i.precio, seleccionado: sel);
      } catch (_) {
        icon = BitmapDescriptor.defaultMarker;
      }

      set.add(Marker(
        markerId: MarkerId('i_${i.id}'),
        position: LatLng(i.latitud!, i.longitud!),
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        zIndex: sel ? 4 : 1,
        onTap: () => _onMarcadorTap(i),
      ));
    }

    if (mounted) setState(() => _markers = set);
  }

  List<Inmueble> get _inmueblesFiltrados => _inmuebles.where((i) {
        if (_tipoFiltro != null && i.tipo != _tipoFiltro) return false;
        if (_precioMax != null && i.precio > _precioMax!) return false;
        if (_radioKm != null) {
          final punto = _authProvider?.usuario?.puntoInteres;
          if (punto == null) return true;
          final metros = _haversine(
            i.latitud!,
            i.longitud!,
            (punto['latitud'] as num).toDouble(),
            (punto['longitud'] as num).toDouble(),
          );
          if (metros > _radioKm! * 1000) return false;
        }
        return true;
      }).toList();
  void _onMarcadorTap(Inmueble i) {
    setState(() {
      _seleccionado = i;
      _mostrarPreview = true;
    });
    _construirMarcadores();
    _ctrl?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(i.latitud!, i.longitud!), 16),
    );
  }

  void _cerrarPreview() {
    setState(() {
      _mostrarPreview = false;
      _seleccionado = null;
    });
    _construirMarcadores();
  }

  void _centrarEnInstitucion() {
    final punto = _authProvider!.usuario?.puntoInteres;

    if (punto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrá tu institución en el perfil primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(
        (punto['latitud'] as num).toDouble(),
        (punto['longitud'] as num).toDouble(),
      ),
      15,
    ));
  }

  Future<void> _centrarEnGPS() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _ctrl?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15));
    } catch (_) {}
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

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _distancia(Inmueble i) {
    final auth = _authProvider;
    if (auth == null) return '';
    final punto = auth.usuario?.puntoInteres;
    if (punto == null || i.latitud == null) return '';
    final m = _haversine(
      i.latitud!,
      i.longitud!,
      (punto['latitud'] as num).toDouble(),
      (punto['longitud'] as num).toDouble(),
    );
    if (m < 1000) return 'A ${(m / 83).ceil()} min caminando';
    return 'A ${(m / 1000).toStringAsFixed(1)} km';
  }

  void _mostrarFiltroRadio() {
    final punto = _authProvider?.usuario?.puntoInteres;
    if (punto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registrá tu institución en el perfil para filtrar por distancia.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distancia máxima',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Desde ${punto['nombre'] ?? 'tu institución'}',
              style: const TextStyle(fontSize: 12, color: _gris),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [1.0, 2.0, 3.0, 5.0, 10.0].map((km) {
                final sel = _radioKm == km;
                return GestureDetector(
                  onTap: () {
                    setState(() => _radioKm = km);
                    Navigator.pop(sheetCtx);
                    _construirMarcadores();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _verde : _grisClaro,
                      borderRadius: BorderRadius.circular(30),
                      border:
                          Border.all(color: sel ? _verde : Colors.transparent),
                    ),
                    child: Text(
                      '${km.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _textoOscuro,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _radioKm = null);
                  Navigator.pop(sheetCtx);
                  _construirMarcadores();
                },
                child: const Text('Quitar filtro'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroPrecio() {
    final ctrl =
        TextEditingController(text: _precioMax?.toStringAsFixed(0) ?? '');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(_).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Precio máximo (Bs.)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ej: 800',
                prefixText: 'Bs. ',
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
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _precioMax = null);
                    Navigator.pop(_);
                    _construirMarcadores();
                  },
                  child: const Text('Quitar filtro'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(
                        () => _precioMax = double.tryParse(ctrl.text.trim()));
                    Navigator.pop(_);
                    _construirMarcadores();
                  },
                  child: const Text('Aplicar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final punto = auth.usuario?.puntoInteres;

    final LatLng inicio = punto != null
        ? LatLng((punto['latitud'] as num).toDouble(),
            (punto['longitud'] as num).toDouble())
        : _centroCbba;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: inicio, zoom: 14),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) {
              if (!_completer.isCompleted) _completer.complete(c);
              _ctrl = c;
            },
            onTap: (_) => _cerrarPreview(),
          ),
          if (_cargando)
            Container(
              color: Colors.white.withOpacity(0.65),
              child:
                  const Center(child: CircularProgressIndicator(color: _verde)),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: _buildFiltros(),
          ),
          Positioned(
            right: 16,
            bottom: _mostrarPreview ? 150 : 30,
            child: Column(
              children: [
                _botonCircular(
                  icon: Icons.school_outlined,
                  bgColor: _verde,
                  iconColor: Colors.white,
                  onTap: _centrarEnInstitucion,
                  tooltip: 'Mi institución',
                ),
                const SizedBox(height: 12),
                _botonCircular(
                  icon: Icons.my_location,
                  bgColor: Colors.white,
                  iconColor: _textoOscuro,
                  onTap: _centrarEnGPS,
                  tooltip: 'Mi ubicación',
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            bottom: _mostrarPreview ? 20 : -200,
            left: 16,
            right: 16,
            child: _seleccionado != null
                ? _buildPreview(_seleccionado!)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _botonCircular({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _chip(
          label: _precioMax != null
              ? '≤ Bs. ${_precioMax!.toStringAsFixed(0)}'
              : 'Precio máx.',
          icon: Icons.sell_outlined,
          activo: _precioMax != null,
          onTap: _mostrarFiltroPrecio,
        ),
        const SizedBox(width: 8),
        _chip(
          label: _radioKm != null
              ? 'A ${_radioKm!.toStringAsFixed(0)} km'
              : 'Distancia',
          icon: Icons.social_distance_outlined,
          activo: _radioKm != null,
          onTap: _mostrarFiltroRadio,
        ),
        const SizedBox(width: 8),
        for (final t in [
          {'label': 'Cuarto', 'tipo': 'CUARTO'},
          {'label': 'Depto.', 'tipo': 'DEPARTAMENTO'},
          {'label': 'Compartido', 'tipo': 'COMPARTIDO'},
        ]) ...[
          _chip(
            label: t['label']!,
            icon: Icons.home_outlined,
            activo: _tipoFiltro == t['tipo'],
            onTap: () {
              setState(() =>
                  _tipoFiltro = _tipoFiltro == t['tipo'] ? null : t['tipo']);
              _construirMarcadores();
            },
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool activo,
    required VoidCallback onTap,
    Color? override,
  }) {
    final bg = override ?? (activo ? _verde : Colors.white);
    final fg = override != null
        ? _textoOscuro
        : (activo ? Colors.white : _textoOscuro);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }

  Widget _buildPreview(Inmueble i) {
    final dist = _distancia(i);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DetalleInmuebleScreen(inmuebleId: i.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: i.imagenes.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: i.imagenes.first.url,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(width: 110, height: 110, color: _grisClaro),
                    errorWidget: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: _grisClaro,
                      child: const Icon(Icons.home_outlined, color: _gris),
                    ),
                  )
                : Container(
                    width: 110,
                    height: 110,
                    color: _grisClaro,
                    child: const Icon(Icons.home_outlined,
                        color: _gris, size: 32)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(i.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro)),
                  const SizedBox(height: 6),
                  Text(
                    'Bs. ${i.precio.toStringAsFixed(0)}/mes',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _verde),
                  ),
                  if (dist.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.directions_walk, size: 13, color: _gris),
                      const SizedBox(width: 4),
                      Text(dist,
                          style: const TextStyle(fontSize: 11, color: _gris)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: _gris, size: 26),
          ),
        ]),
      ),
    );
  }
}
