import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '/../../services/ubicacionService.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  final LatLng? ubicacionInicial;

  const SeleccionarUbicacionScreen({super.key, this.ubicacionInicial});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  static const Color _cafe = Color(0xFF5C3D2E);

  GoogleMapController? _mapController;
  final UbicacionService _ubicacionService = UbicacionService();
  LatLng? _ubicacionSeleccionada;
  bool _cargando = true;
  LatLng _centro = UbicacionService.centroCochabamba;

  @override
  void initState() {
    super.initState();
    if (widget.ubicacionInicial != null) {
      _ubicacionSeleccionada = widget.ubicacionInicial;
      _centro = widget.ubicacionInicial!;
      _cargando = false;
    } else {
      _obtenerUbicacion();
    }
  }

  Future<void> _obtenerUbicacion() async {
    final pos = await _ubicacionService.obtenerUbicacionActual();
    if (pos != null && mounted) {
      setState(() {
        _centro = LatLng(pos.latitude, pos.longitude);
      });
    }
    setState(() => _cargando = false);
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
          'Seleccionar ubicación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centro,
                    zoom: 15,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: (latLng) =>
                      setState(() => _ubicacionSeleccionada = latLng),
                  markers: _ubicacionSeleccionada != null
                      ? {
                          Marker(
                            markerId: const MarkerId('seleccionado'),
                            position: _ubicacionSeleccionada!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueOrange,
                            ),
                          )
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_outlined, color: _cafe, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tocá el mapa para marcar la ubicación del inmueble',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: _ubicacionSeleccionada != null ? 120 : 24,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      await _obtenerUbicacion();
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_centro, 15),
                      );
                    },
                    child: Icon(Icons.my_location, color: _cafe),
                  ),
                ),
                if (_ubicacionSeleccionada != null)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _cafe.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(Icons.location_on, color: _cafe, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ubicación seleccionada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lat: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(6)}\nLng: ${_ubicacionSeleccionada!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, _ubicacionSeleccionada),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cafe,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: const Text(
                              'Confirmar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
