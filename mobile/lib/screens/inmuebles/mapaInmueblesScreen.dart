import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/inmueble.dart';
import '../../services/inmuebleService.dart';
import '../../services/ubicacionService.dart';
import 'arrendatario/detalleInmuebleScreen.dart';

class MapaInmueblesScreen extends StatefulWidget {
  const MapaInmueblesScreen({super.key});

  @override
  State<MapaInmueblesScreen> createState() => _MapaInmueblesScreenState();
}

class _MapaInmueblesScreenState extends State<MapaInmueblesScreen> {
  static const Color _cafe = Color(0xFF5C3D2E);

  GoogleMapController? _mapController;
  final InmuebleService _service = InmuebleService();
  final UbicacionService _ubicacionService = UbicacionService();

  Set<Marker> _marcadores = {};
  List<Inmueble> _inmuebles = [];
  Inmueble? _inmuebleSeleccionado;
  bool _cargando = true;
  LatLng _centro = UbicacionService.centroCochabamba;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _obtenerUbicacion();
    await _cargarInmuebles();
  }

  Future<void> _obtenerUbicacion() async {
    final pos = await _ubicacionService.obtenerUbicacionActual();
    if (pos != null) {
      setState(() => _centro = LatLng(pos.latitude, pos.longitude));
    }
  }

  Future<void> _cargarInmuebles() async {
    final resultado = await _service.obtenerInmuebles();
    final inmuebles = resultado['inmuebles'] as List<Inmueble>;

    final marcadores = <Marker>{};

    for (final i in inmuebles) {
      if (i.latitud != null && i.longitud != null) {
        marcadores.add(
          Marker(
            markerId: MarkerId(i.id.toString()),
            position: LatLng(i.latitud!, i.longitud!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () => setState(() => _inmuebleSeleccionado = i),
          ),
        );
      }
    }

    setState(() {
      _inmuebles = inmuebles;
      _marcadores = marcadores;
      _cargando = false;
    });
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'DEPARTAMENTO':
        return Colors.green;
      case 'CUARTO':
        return Colors.orange;
      case 'COMPARTIDO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'DEPARTAMENTO':
        return 'Departamento';
      case 'CUARTO':
        return 'Cuarto';
      case 'COMPARTIDO':
        return 'Compartido';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _cafe,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mapa de inmuebles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () async {
              await _obtenerUbicacion();
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_centro, 14),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centro,
                    zoom: 13,
                  ),
                  markers: _marcadores,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) => setState(() => _inmuebleSeleccionado = null),
                ),
          if (_inmuebleSeleccionado != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleInmuebleScreen(
                      inmuebleId: _inmuebleSeleccionado!.id,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _inmuebleSeleccionado!.imagenes.isNotEmpty
                            ? Image.network(
                                _inmuebleSeleccionado!.imagenes.first.url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(Icons.home_outlined,
                                    color: Colors.grey[400]),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _colorTipo(_inmuebleSeleccionado!.tipo)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _labelTipo(_inmuebleSeleccionado!.tipo),
                                style: TextStyle(
                                  color:
                                      _colorTipo(_inmuebleSeleccionado!.tipo),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _inmuebleSeleccionado!.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 13, color: Colors.grey[500]),
                                const SizedBox(width: 3),
                                Text(
                                  _inmuebleSeleccionado!.zona,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bs. ${_inmuebleSeleccionado!.precio.toStringAsFixed(0)}/mes',
                              style: TextStyle(
                                color: _cafe,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Text(
                '${_marcadores.length} inmuebles en mapa',
                style: TextStyle(
                  color: _cafe,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
