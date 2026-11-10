import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/constantes.dart';
import '../../../models/inmueble.dart';
import '../../../providers/authProvider.dart';
import '../secciones/seccionCuarto.dart';
import '../secciones/seccionDepartamento.dart';
import '../secciones/seccionCompartido.dart';
import 'seleccionarUbicacionScreen.dart';

class EditarInmuebleScreen extends StatefulWidget {
  final Inmueble inmueble;
  const EditarInmuebleScreen({super.key, required this.inmueble});

  @override
  State<EditarInmuebleScreen> createState() => _EditarInmuebleScreenState();
}

class _EditarInmuebleScreenState extends State<EditarInmuebleScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  late final TextEditingController _titulo;
  late final TextEditingController _precio;
  late final TextEditingController _zona;
  late final TextEditingController _direccion;
  late Map<String, dynamic> _datosTipo;
  late Map<String, bool> _servicios;
  static const _serviciosLabels = {
    'luzIncluida': '💡 Luz',
    'aguaIncluida': '💧 Agua',
    'internetIncluido': '📶 Internet',
    'gasIncluido': '🔥 Gas',
  };
  late List<Imagen> _imagenesActuales;
  final List<File> _nuevasImagenes = [];
  final Set<int> _eliminandoIds = {};
  LatLng? _ubicacionSeleccionada;

  bool _cargando = false;
  late String _tipoOferta;
  List<String> _parseReglas(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    final i = widget.inmueble;

    _titulo = TextEditingController(text: i.titulo);
    _precio = TextEditingController(text: i.precio.toStringAsFixed(0));
    _zona = TextEditingController(text: i.zona);
    _direccion = TextEditingController(text: i.direccion);

    if (i.latitud != null && i.longitud != null) {
      _ubicacionSeleccionada = LatLng(i.latitud!, i.longitud!);
    }

    _imagenesActuales = List.from(i.imagenes);
    _tipoOferta = i.tipoOferta;

    _servicios = {
      'luzIncluida': i.luzIncluida,
      'aguaIncluida': i.aguaIncluida,
      'internetIncluido': i.internetIncluido,
      'gasIncluido': i.gasIncluido,
    };
    switch (i.tipo) {
      case 'CUARTO':
        _datosTipo = {
          'tamano': i.tamano?.toString() ?? '',
          'piso': i.piso?.toString() ?? '',
          'banoCompartido': i.banoCompartido == true ? 'true' : 'false',
          'generoPermitido': i.generoPermitido ?? 'CUALQUIERA',
          'amoblado': i.amoblado ?? false,
          'permiteMascotas': i.permiteMascotas ?? false,
        };
        break;

      case 'DEPARTAMENTO':
        _datosTipo = {
          'numDormitorios': i.numDormitorios?.toString() ?? '',
          'numBanos': i.numBanos?.toString() ?? '',
          'piso': i.piso?.toString() ?? '',
          'habitantesMax': i.habitantesMax?.toString() ?? '',
          'generoPermitido': i.generoPermitido ?? 'CUALQUIERA',
          'tieneParqueo': i.tieneParqueo ?? false,
          'amoblado': i.amoblado ?? false,
          'permiteMascotas': i.permiteMascotas ?? false,
        };
        break;

      case 'COMPARTIDO':
        _datosTipo = {
          'habitacionesTotales': i.habitacionesTotales?.toString() ?? '',
          'habitacionesDisponibles':
              i.habitacionesDisponibles?.toString() ?? '',
          'banoCompartido': i.banoCompartido == true ? 'true' : 'false',
          'generoConvivientes': i.generoConvivientes ?? 'MIXTO',
          'generoPermitido': i.generoPermitido ?? 'CUALQUIERA',
          'rangoEdad': RangeValues(
            (i.edadMinima ?? 18).toDouble(),
            (i.edadMaxima ?? 40).toDouble(),
          ),
          'reglasMarcadas': _parseReglas(i.reglasComunes),
          'soloEstudiantes': i.soloEstudiantes ?? false,
          'permiteMascotas': i.permiteMascotas ?? false,
          'observaciones': i.observaciones ?? '',
        };
        break;

      default:
        _datosTipo = {};
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _precio.dispose();
    _zona.dispose();
    _direccion.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? Colors.red[700] : _verde,
      behavior: SnackBarBehavior.floating,
      content: Text(msg),
    ));
  }

  Future<void> _eliminarImagen(Imagen img) async {
    setState(() => _eliminandoIds.add(img.id));
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.delete(
        Uri.parse('${Constantes.baseUrl}/inmuebles/imagenes/${img.id}'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _imagenesActuales.removeWhere((x) => x.id == img.id));
      } else {
        _snack('Error al eliminar imagen', error: true);
      }
    } catch (_) {
      _snack('Error de conexión', error: true);
    }
    if (mounted) setState(() => _eliminandoIds.remove(img.id));
  }

  void _confirmarEliminarImagen(Imagen img) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar foto', style: TextStyle(fontSize: 16)),
        content: const Text('¿Seguro que querés eliminar esta foto?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _eliminarImagen(img);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarImagenes() async {
    final total = _imagenesActuales.length + _nuevasImagenes.length;
    if (total >= 5) {
      _snack('Máximo 5 imágenes en total');
      return;
    }
    final picker = ImagePicker();
    final sel = await picker.pickMultiImage(imageQuality: 80);
    setState(() => _nuevasImagenes.addAll(
          sel.take(5 - total).map((x) => File(x.path)),
        ));
  }

  Future<void> _guardar() async {
    if (_titulo.text.trim().isEmpty ||
        _precio.text.trim().isEmpty ||
        _zona.text.trim().isEmpty ||
        _direccion.text.trim().isEmpty) {
      _snack('Completá los campos obligatorios', error: true);
      return;
    }
    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${Constantes.baseUrl}/inmuebles/${widget.inmueble.id}'),
      );
      request.headers['Authorization'] = 'Bearer ${auth.token}';
      request.fields['titulo'] = _titulo.text.trim();
      request.fields['precio'] = _precio.text.trim();
      request.fields['zona'] = _zona.text.trim();
      request.fields['direccion'] = _direccion.text.trim();
      request.fields['tipoOferta'] = _tipoOferta;
      if (_ubicacionSeleccionada != null) {
        request.fields['latitud'] = _ubicacionSeleccionada!.latitude.toString();
        request.fields['longitud'] =
            _ubicacionSeleccionada!.longitude.toString();
      }
      _servicios.forEach((k, v) => request.fields[k] = v.toString());
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
      for (final img in _nuevasImagenes) {
        request.files
            .add(await http.MultipartFile.fromPath('imagenes', img.path));
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (!mounted) return;
      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(
                child: Text(
              'Cambios guardados. La publicación volverá a revisión por el administrador.',
              style: TextStyle(fontSize: 13),
            )),
          ]),
        ));
        Navigator.pop(context);
      } else {
        _snack(data['mensaje'] ?? 'Error al guardar', error: true);
      }
    } catch (_) {
      _snack('Error de conexión', error: true);
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.inmueble.tipo;
    final totalFotos = _imagenesActuales.length + _nuevasImagenes.length;

    return Scaffold(
      backgroundColor: _grisClaro,
      appBar: AppBar(
        backgroundColor: _verde,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar publicación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _cargando ? null : _guardar,
            child: const Text('Guardar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                  'Al guardar, la publicación volverá a revisión del administrador.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _seccion('Fotos del inmueble'),
                    Text('$totalFotos/5',
                        style: TextStyle(
                          color: totalFotos >= 3 ? _verde : _gris,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    ..._imagenesActuales.map((img) => Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: img.url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                            ),
                          ),
                          if (_eliminandoIds.contains(img.id))
                            Positioned.fill(
                                child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                  child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )),
                            )),
                          if (!_eliminandoIds.contains(img.id))
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _confirmarEliminarImagen(img),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                        ])),
                    ..._nuevasImagenes
                        .asMap()
                        .entries
                        .map((e) => Stack(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(e.value,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _nuevasImagenes.removeAt(e.key)),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ])),
                    if (totalFotos < 5)
                      GestureDetector(
                        onTap: _agregarImagenes,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _verdeClaro,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _verde.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  color: _verde, size: 28),
                              const SizedBox(height: 4),
                              Text('Agregar',
                                  style: TextStyle(
                                      color: _verdeOscuro,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            )),
            const SizedBox(height: 12),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _seccion('Tipo de inmueble'),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _grisClaro,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock_outline,
                          size: 11, color: Color(0xFF9CA3AF)),
                      SizedBox(width: 3),
                      Text('No editable',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                AbsorbPointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: Row(children: [
                      _tipoBloqueado('CUARTO', 'Cuarto', '🛏', tipo),
                      const SizedBox(width: 8),
                      _tipoBloqueado(
                          'DEPARTAMENTO', 'Departamento', '🏢', tipo),
                      const SizedBox(width: 8),
                      _tipoBloqueado('COMPARTIDO', 'Compartido', '🤝', tipo),
                    ]),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 12),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _seccion('Información básica'),
                const SizedBox(height: 14),
                Row(children: [
                  _ofertaChip('ALQUILER', '📋 Alquiler'),
                  const SizedBox(width: 10),
                  _ofertaChip('ANTICRETICO', '🔑 Anticrético'),
                ]),
                const SizedBox(height: 14),
                _campo(_titulo, 'Título del anuncio', icono: Icons.title),
                const SizedBox(height: 12),
                _campo(
                  _precio,
                  _tipoOferta == 'ANTICRETICO'
                      ? 'Monto total del Anticrético (Bs.)'
                      : 'Precio mensual (Bs.)',
                  icono: Icons.attach_money,
                  tipo: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _campo(_zona, 'Zona', icono: Icons.location_city_outlined),
                const SizedBox(height: 12),
                _campo(_direccion, 'Dirección', icono: Icons.pin_drop_outlined),
              ],
            )),
            const SizedBox(height: 12),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _seccion('Ubicación en el mapa'),
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
                    if (resultado != null)
                      setState(() => _ubicacionSeleccionada = resultado);
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
                    child: Row(children: [
                      Icon(
                        _ubicacionSeleccionada != null
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        color: _ubicacionSeleccionada != null ? _verde : _gris,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                        _ubicacionSeleccionada != null
                            ? 'Lat: ${_ubicacionSeleccionada!.latitude.toStringAsFixed(5)}, Lng: ${_ubicacionSeleccionada!.longitude.toStringAsFixed(5)}'
                            : 'Tocar para marcar en el mapa',
                        style: TextStyle(
                          color: _ubicacionSeleccionada != null
                              ? _verdeOscuro
                              : _gris,
                          fontSize: 13,
                        ),
                      )),
                      if (_ubicacionSeleccionada != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _ubicacionSeleccionada = null),
                          child: Icon(Icons.close, color: _gris, size: 18),
                        ),
                    ]),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 12),
            _card(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _seccion('Servicios incluidos'),
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
                              color: activo ? _verde : _gris.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Text(_serviciosLabels[k]!.split(' ')[0],
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(_serviciosLabels[k]!.split(' ')[1],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: activo ? _verdeOscuro : _gris)),
                          const Spacer(),
                          Icon(
                              activo
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: activo ? _verde : _gris,
                              size: 18),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )),
            const SizedBox(height: 12),
            _card(child: _buildSeccionEspecifica(tipo)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Guardar cambios',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionEspecifica(String tipo) {
    switch (tipo) {
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

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: child,
      );

  Widget _seccion(String texto) => Text(texto,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)));

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    TextInputType tipo = TextInputType.text,
    IconData? icono,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _gris, fontSize: 13),
          prefixIcon:
              icono != null ? Icon(icono, color: _gris, size: 20) : null,
          filled: true,
          fillColor: _grisClaro,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5)),
          floatingLabelStyle: const TextStyle(color: _verdeOscuro),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      );

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

  Widget _tipoBloqueado(
      String valor, String label, String icono, String actual) {
    final sel = actual == valor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? _verde : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: sel ? _verdeOscuro : _gris.withOpacity(0.4)),
        ),
        child: Column(children: [
          Text(icono, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : Colors.grey[600])),
        ]),
      ),
    );
  }
}
