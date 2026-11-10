import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '/../../providers/authProvider.dart';
import '/../../config/constantes.dart';
import '../secciones/seccionCuarto.dart';
import '../secciones/seccionDepartamento.dart';
import '../secciones/seccionCompartido.dart';
import 'seleccionarUbicacionScreen.dart';

class _TipoInmueble {
  final String valor;
  final String label;
  final IconData icono;
  const _TipoInmueble(this.valor, this.label, this.icono);
}

class CrearInmuebleScreen extends StatefulWidget {
  const CrearInmuebleScreen({super.key});

  @override
  State<CrearInmuebleScreen> createState() => _CrearInmuebleScreenState();
}

class _CrearInmuebleScreenState extends State<CrearInmuebleScreen> {
  static const Color _verde = Color(0xFF10B981);
  static const Color _grisF = Color(0xFF9CA3AF); // esmeralda principal
  static const Color _verdeOscuro =
      Color.fromARGB(255, 23, 26, 25); // esmeralda oscuro
  static const Color _verdeClaro = Color(0xFFECFDF5); // esmeralda muy claro
  static const Color _gris = Color(0xFF9CA3AF); // gris medio
  static const Color _grisClaro = Color(0xFFF3F4F6); // gris claro

  final _tituloController = TextEditingController();
  final _precioController = TextEditingController();
  final _zonaController = TextEditingController();
  final _direccionController = TextEditingController();
  String _tipoSeleccionado = 'CUARTO';
  String _tipoOferta = 'ALQUILER';
  List<File> _imagenes = [];
  bool _cargando = false;
  bool _geocodificando = false;
  LatLng? _ubicacionSeleccionada;

  Map<String, bool> _servicios = {
    'luzIncluida': false,
    'aguaIncluida': false,
    'internetIncluido': false,
    'gasIncluido': false,
  };

  Map<String, dynamic> _datosTipo = {
    'banoCompartido': 'false',
    'generoPermitido': 'CUALQUIERA',
    'generoConvivientes': 'MIXTO',
    'amoblado': false,
    'permiteMascotas': false,
    'tieneParqueo': false,
    'soloEstudiantes': false,
    'rangoEdad': const RangeValues(18, 40),
    'reglasMarcadas': <String>[],
    'observaciones': '',
  };

  static const List<_TipoInmueble> _tipos = [
    _TipoInmueble('CUARTO', 'Cuarto', Icons.bed_outlined),
    _TipoInmueble('DEPARTAMENTO', 'Departamento', Icons.apartment_outlined),
    _TipoInmueble('COMPARTIDO', 'Compartido', Icons.people_outline),
  ];

  final Map<String, String> _serviciosLabels = {
    'luzIncluida': '💡 Luz',
    'aguaIncluida': '💧 Agua',
    'internetIncluido': '📶 Internet',
    'gasIncluido': '🔥 Gas',
  };

  @override
  void dispose() {
    _tituloController.dispose();
    _precioController.dispose();
    _zonaController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagenes() async {
    if (_imagenes.length >= 5) {
      _snack('Máximo 5 imágenes permitidas');
      return;
    }
    final picker = ImagePicker();
    final seleccionadas = await picker.pickMultiImage(imageQuality: 80);
    final disponibles = 5 - _imagenes.length;
    final nuevas =
        seleccionadas.take(disponibles).map((x) => File(x.path)).toList();
    setState(() => _imagenes.addAll(nuevas));
  }

  Future<void> _autocompletarDesdeCoordenadas(LatLng punto) async {
    setState(() => _geocodificando = true);
    try {
      final marcas = await placemarkFromCoordinates(
        punto.latitude,
        punto.longitude,
      );

      print('GEOCODING → ${marcas.length} resultados');
      if (marcas.isEmpty || !mounted) return;
      final m = marcas.first;
      print('  subLocality: ${m.subLocality}');
      print('  locality: ${m.locality}');
      print('  thoroughfare: ${m.thoroughfare}');
      print('  subThoroughfare: ${m.subThoroughfare}');

      final zona = [
        m.subLocality,
        m.locality
      ].firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);

      final partesDireccion = [
        m.thoroughfare,
        m.subThoroughfare,
      ].where((v) => v != null && v.trim().isNotEmpty).join(' ');

      setState(() {
        if (zona != null && zona.trim().isNotEmpty) {
          _zonaController.text = zona.trim();
        }
        if (partesDireccion.isNotEmpty) {
          _direccionController.text = partesDireccion.trim();
        }
      });

      if (zona != null || partesDireccion.isNotEmpty) {
        _snack('Ubicación detectada. Revisá y corregí si hace falta.');
      }
    } catch (_) {
      // Si falla el geocodificador, el usuario completa a mano
    } finally {
      if (mounted) setState(() => _geocodificando = false);
    }
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _geocodificando = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _geocodificando = false);
          _snack('Necesitamos permiso de ubicación para usar esta opción',
              error: true);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      final punto = LatLng(pos.latitude, pos.longitude);
      setState(() => _ubicacionSeleccionada = punto);
      await _autocompletarDesdeCoordenadas(punto);
    } catch (_) {
      if (mounted) {
        setState(() => _geocodificando = false);
        _snack('No pudimos obtener tu ubicación', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? Colors.red[700] : _verdeOscuro,
      content: Text(msg),
    ));
  }

  Widget _buildSeccionEspecifica() {
    switch (_tipoSeleccionado) {
      case 'CUARTO':
        return SeccionCuarto(
          datos: _datosTipo,
          onCambio: (k, v) => setState(() => _datosTipo[k] = v),
        );
      case 'DEPARTAMENTO':
        return SeccionDepartamento(
          datos: _datosTipo,
          onCambio: (k, v) => setState(() => _datosTipo[k] = v),
        );
      case 'COMPARTIDO':
        return SeccionCompartido(
          datos: _datosTipo,
          onCambio: (k, v) => setState(() => _datosTipo[k] = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _publicar() async {
    if (_tituloController.text.trim().isEmpty ||
        _precioController.text.trim().isEmpty ||
        _zonaController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty) {
      _snack('Completá todos los campos obligatorios', error: true);
      return;
    }

    final precio = double.tryParse(_precioController.text.trim());
    if (precio == null || precio <= 0) {
      _snack('Ingresá un precio válido mayor a 0', error: true);
      return;
    }

    if (_imagenes.length < 3) {
      _snack('Debes subir mínimo 3 fotos del inmueble', error: true);
      return;
    }

    if (_tipoSeleccionado == 'COMPARTIDO') {
      final totales =
          int.tryParse(_datosTipo['habitacionesTotales']?.toString() ?? '');
      final disp =
          int.tryParse(_datosTipo['habitacionesDisponibles']?.toString() ?? '');
      if (totales != null && disp != null && disp > totales) {
        _snack('Las habitaciones disponibles no pueden superar el total',
            error: true);
        return;
      }
    }

    if (_tipoSeleccionado == 'CUARTO') {
      final tamanoTexto = _datosTipo['tamano']?.toString().trim() ?? '';
      if (tamanoTexto.isNotEmpty && double.tryParse(tamanoTexto) == null) {
        _snack('Ingresá un tamaño válido en m²', error: true);
        return;
      }
    }

    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constantes.baseUrl}/inmuebles'),
      );

      request.headers['Authorization'] = 'Bearer ${auth.token}';
      request.fields['titulo'] = _tituloController.text.trim();
      request.fields['precio'] = precio.toString();
      request.fields['tipo'] = _tipoSeleccionado;
      request.fields['tipoOferta'] = _tipoOferta;
      request.fields['zona'] = _zonaController.text.trim();
      request.fields['direccion'] = _direccionController.text.trim();

      _servicios.forEach((k, v) => request.fields[k] = v.toString());

      if (_ubicacionSeleccionada != null) {
        request.fields['latitud'] = _ubicacionSeleccionada!.latitude.toString();
        request.fields['longitud'] =
            _ubicacionSeleccionada!.longitude.toString();
      }

      _datosTipo.forEach((k, v) {
        if (v is RangeValues) {
          request.fields['edadMinima'] = v.start.round().toString();
          request.fields['edadMaxima'] = v.end.round().toString();
        } else if (v is List) {
          request.fields[k] = jsonEncode(v);
        } else if (v != null) {
          request.fields[k] = v.toString();
        }
      });

      if (_datosTipo['reglasMarcadas'] != null) {
        request.fields['reglasComunes'] =
            jsonEncode(_datosTipo['reglasMarcadas']);
      }

      for (final img in _imagenes) {
        request.files
            .add(await http.MultipartFile.fromPath('imagenes', img.path));
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (!mounted) return;

      if (data['ok'] == true) {
        _snack('¡Inmueble publicado! Pendiente de aprobación.');
        Navigator.pop(context);
      } else {
        _snack(data['mensaje'] ?? 'Error al publicar', error: true);
      }
    } catch (e) {
      _snack('Error de conexión', error: true);
    }

    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF10B981), // gris slate para el AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Publicar inmueble',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)], // gris muy suave
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Tipo de inmueble'),
                    const SizedBox(height: 12),
                    Row(
                      children: _tipos.map((t) {
                        final sel = _tipoSeleccionado == t.valor;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tipoSeleccionado = t.valor;
                              _datosTipo = {
                                'banoCompartido': 'false',
                                'generoPermitido': 'CUALQUIERA',
                                'generoConvivientes': 'MIXTO',
                                'amoblado': false,
                                'permiteMascotas': false,
                                'tieneParqueo': false,
                                'soloEstudiantes': false,
                                'rangoEdad': const RangeValues(18, 40),
                                'reglasMarcadas': <String>[],
                                'observaciones': '',
                              };
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: sel ? _verde : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: sel
                                      ? _verdeOscuro
                                      : _gris.withOpacity(0.4),
                                  width: sel ? 2 : 1,
                                ),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: _verde.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    t.icono,
                                    color: sel ? Colors.white : _gris,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : _gris,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _tituloSeccion('Fotos del inmueble'),
                        Text(
                          '${_imagenes.length}/5',
                          style: TextStyle(
                            color: _imagenes.length >= 3 ? _grisF : _gris,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mínimo 3 fotos requeridas',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        ..._imagenes.asMap().entries.map((e) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    e.value,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _imagenes.removeAt(e.key)),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        if (_imagenes.length < 5)
                          GestureDetector(
                            onTap: _seleccionarImagenes,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _verdeClaro,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _verde.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined,
                                      color: _grisF, size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    '+ Agregar\nfotos',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _verdeOscuro,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Información básica'),
                    const SizedBox(height: 14),
                    Row(children: [
                      _ofertaChip('ALQUILER', '📋 Alquiler'),
                      const SizedBox(width: 10),
                      _ofertaChip('ANTICRETICO', '🔑 Anticrético'),
                    ]),
                    const SizedBox(height: 14),
                    _floatingField(
                      controller: _tituloController,
                      label: 'Título del anuncio',
                      hint: 'Ej: Cuarto amplio cerca de la UMSS',
                      icono: Icons.title,
                    ),
                    const SizedBox(height: 14),
                    _floatingField(
                      controller: _precioController,
                      label: _tipoOferta == 'ANTICRETICO'
                          ? 'Monto total del Anticrético (Bs.)'
                          : 'Precio mensual (Bs.)',
                      hint: _tipoOferta == 'ANTICRETICO'
                          ? 'Ej: 15000'
                          : 'Ej: 450',
                      icono: Icons.attach_money,
                      tipo:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _floatingField(
                      controller: _zonaController,
                      label: 'Zona',
                      hint: 'Ej: Cala Cala, Quillacollo...',
                      icono: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 14),
                    _floatingField(
                      controller: _direccionController,
                      label: 'Dirección',
                      hint: 'Ej: Calle Sucre #123',
                      icono: Icons.pin_drop_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Ubicación en el mapa'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final resultado = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeleccionarUbicacionScreen(
                              ubicacionInicial: _ubicacionSeleccionada,
                            ),
                          ),
                        );
                        if (resultado != null) {
                          setState(() => _ubicacionSeleccionada = resultado);
                          _autocompletarDesdeCoordenadas(resultado);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _ubicacionSeleccionada != null
                              ? _verdeClaro
                              : _grisClaro,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ubicacionSeleccionada != null
                                ? _verde
                                : _gris.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _ubicacionSeleccionada != null
                                  ? Icons.location_on
                                  : Icons.location_on_outlined,
                              color: _ubicacionSeleccionada != null
                                  ? _verde
                                  : _gris,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _geocodificando
                                    ? 'Detectando zona y dirección...'
                                    : _ubicacionSeleccionada != null
                                        ? 'Lat: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(5)}, Lng: ${_ubicacionSeleccionada!.longitude.toStringAsFixed(5)}'
                                        : 'Tocar para marcar en el mapa',
                                style: TextStyle(
                                  color: _ubicacionSeleccionada != null
                                      ? _verdeOscuro
                                      : _gris,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (_geocodificando)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _verde),
                              ),
                            if (_ubicacionSeleccionada != null)
                              GestureDetector(
                                onTap: () => setState(
                                    () => _ubicacionSeleccionada = null),
                                child:
                                    Icon(Icons.close, color: _gris, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Divider(color: _gris.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o',
                            style: TextStyle(fontSize: 12, color: _gris)),
                      ),
                      Expanded(child: Divider(color: _gris.withOpacity(0.3))),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _geocodificando ? null : _usarUbicacionActual,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _verde,
                          side: BorderSide(color: _verde.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Usar mi ubicación actual',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSeccion('Servicios incluidos'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: _servicios.keys.map((k) {
                        final activo = _servicios[k]!;
                        return GestureDetector(
                          onTap: () => setState(() => _servicios[k] = !activo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: activo ? _verdeClaro : _grisClaro,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: activo ? _verde : _gris.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(_serviciosLabels[k]!.split(' ')[0],
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  _serviciosLabels[k]!.split(' ')[1],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: activo ? _verdeOscuro : _gris,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  activo
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: activo ? _verde : _gris,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(child: _buildSeccionEspecifica()),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _cargando ? null : _publicar,
          backgroundColor: _cargando ? _gris : _verde,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          label: _cargando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Publicar Ahora',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gris.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tituloSeccion(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _ofertaChip(String valor, String label) {
    final sel = _tipoOferta == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoOferta = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? _verde : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? _verde : _gris.withOpacity(0.4),
              width: sel ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _gris)),
          ),
        ),
      ),
    );
  }

  Widget _floatingField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icono,
    TextInputType tipo = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: _gris, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icono, color: _gris, size: 20),
        filled: true,
        fillColor: _grisClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gris.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _gris.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _grisF, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(color: _verdeOscuro),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
