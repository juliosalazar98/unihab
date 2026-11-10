import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/inmueble.dart';
import '../../../services/inmuebleService.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../config/constantes.dart';
import '../../../providers/authProvider.dart';
import 'favorito_sheet.dart';
import 'galeriaInmuebleScreen.dart';
import '/widgets/muroRegistro.dart';

class DetalleInmuebleScreen extends StatefulWidget {
  final int inmuebleId;
  const DetalleInmuebleScreen({super.key, required this.inmuebleId});

  @override
  State<DetalleInmuebleScreen> createState() => _DetalleInmuebleScreenState();
}

class _DetalleInmuebleScreenState extends State<DetalleInmuebleScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);
  static const _rojoBg = Color(0xFFFEF2F2);

  final InmuebleService _service = InmuebleService();
  Inmueble? _inmueble;
  bool _cargando = true;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isFavorito = false;
  int? _listaId;
  String? _nombreLista;
  bool _contactando = false; // ← nuevo estado

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final inmueble = await _service.obtenerInmueble(widget.inmuebleId);
    setState(() {
      _inmueble = inmueble;
      _cargando = false;
    });
    _registrarVisto();
    _cargarEstadoFavorito(); // ← AÑADIR
  }

  Future<void> _cargarEstadoFavorito() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.esInvitado) return;
    try {
      final res = await http.get(
        Uri.parse(
            '${Constantes.baseUrl}/favoritos/estado/${widget.inmuebleId}'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _isFavorito = data['datos']['isFavorito'] as bool;
          _listaId = data['datos']['listaId'] as int?;
          _nombreLista = data['datos']['nombreLista'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleFavoritoTap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.esInvitado) {
      mostrarMuroRegistro(
        context,
        icono: Icons.favorite_border,
        titulo: 'Guardá este inmueble',
        mensaje:
            'Creá tu cuenta para armar listas con los inmuebles que te interesan y volver a ellos cuando quieras.',
      );
      return;
    }

    final token = auth.token ?? '';

    final result = await mostrarFavoritoSheet(
      context,
      inmuebleId: widget.inmuebleId,
      token: token,
      isFavorito: _isFavorito,
      listaId: _listaId,
      nombreLista: _nombreLista,
    );

    if (result == null || !mounted) return;

    setState(() {
      if (result['action'] == 'saved') {
        _isFavorito = true;
        _listaId = result['listaId'] as int?;
        _nombreLista = result['nombreLista'] as String?;
      } else {
        _isFavorito = false;
        _listaId = null;
        _nombreLista = null;
      }
    });

    _mostrarSnackFavorito(
      context,
      guardado: result['action'] == 'saved',
      nombreLista: result['nombreLista'] as String?,
    );
  }

  void _mostrarSnackFavorito(BuildContext context,
      {required bool guardado, String? nombreLista}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: guardado ? const Color(0xFF059669) : Colors.grey[850],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          Icon(
            guardado ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              guardado
                  ? '¡Añadido a tus favoritos!'
                  : 'Inmueble eliminado de favoritos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<String> _parseReglas(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'CUARTO':
        return 'Cuarto';
      case 'DEPARTAMENTO':
        return 'Departamento';
      case 'COMPARTIDO':
        return 'Compartido';
      default:
        return tipo;
    }
  }

  String _labelGenero(String g) {
    switch (g) {
      case 'MIXTO':
        return 'Mixto';
      case 'HOMBRES':
        return 'Solo hombres';
      case 'MUJERES':
        return 'Solo mujeres';
      case 'CUALQUIERA':
        return 'Cualquiera';
      default:
        return g;
    }
  }

  Future<void> _registrarVisto() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.esInvitado) return;
    try {
      await http.post(
        Uri.parse('${Constantes.baseUrl}/favoritos/visto'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inmuebleId': widget.inmuebleId}),
      );
    } catch (_) {}
  }

  Future<void> _contactarPropietario() async {
    if (_contactando) return;

    if (Provider.of<AuthProvider>(context, listen: false).esInvitado) {
      mostrarMuroRegistro(
        context,
        icono: Icons.phone_android,
        titulo: 'Contactá al propietario',
        mensaje:
            'Creá tu cuenta para enviar tu solicitud y hablar con el propietario por WhatsApp. Es gratis y toma menos de un minuto.',
      );
      return;
    }

    setState(() => _contactando = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/solicitudes'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inmuebleId': widget.inmuebleId}),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (data['ok'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al procesar'),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      final telefono = (data['datos']['telefono'] ?? '').toString().trim();

      if (telefono.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Tu interés fue registrado. El propietario aún no tiene teléfono cargado.',
          ),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      final titulo = _inmueble?.titulo ?? 'el inmueble';
      final mensaje = Uri.encodeComponent(
        '¡Hola! Vi tu publicación "$titulo" Te acabo de enviar mi solicitud formal por la app. '
        '¿Puedes darme más información?',
      );
      final telefonoWa = telefono.replaceAll('+', '');
      final url = Uri.parse('https://wa.me/$telefonoWa?text=$mensaje');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error de conexión'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _contactando = false);
    }
  }

  Future<void> _compartirInmueble(Inmueble i) async {
    final tipo = _labelTipo(i.tipo);
    final precio = i.tipoOferta == 'ANTICRETICO'
        ? 'Bs. ${_formatearMiles(i.precio)} (Anticrético)'
        : 'Bs. ${_formatearMiles(i.precio)}/mes';

    final servicios = <String>[
      if (i.internetIncluido) 'Internet',
      if (i.luzIncluida) 'Luz',
      if (i.aguaIncluida) 'Agua',
      if (i.gasIncluido) 'Gas',
    ];

    final texto = StringBuffer()
      ..writeln('🏠 ${i.titulo}')
      ..writeln()
      ..writeln('💰 $precio')
      ..writeln('📍 ${i.zona} — ${i.direccion}')
      ..writeln('🏷️ $tipo');

    if (servicios.isNotEmpty) {
      texto.writeln('✅ Incluye: ${servicios.join(', ')}');
    }

    if (i.latitud != null && i.longitud != null) {
      texto
        ..writeln()
        ..writeln(
            '🗺️ Ver ubicación: https://www.google.com/maps?q=${i.latitud},${i.longitud}');
    }

    texto
      ..writeln()
      ..writeln('Encontrado en UniHab — alojamiento estudiantil en Cochabamba');

    await Share.share(texto.toString(), subject: i.titulo);
  }

  static const _motivosReporte = [
    'Precio Falso',
    'Inmueble no existe',
    'Contacto agresivo',
    'Fotos falsas o engañosas',
    'Otro',
  ];

  void _reportarInmueble() {
    if (Provider.of<AuthProvider>(context, listen: false).esInvitado) {
      mostrarMuroRegistro(
        context,
        icono: Icons.flag_outlined,
        titulo: 'Reportar una publicación',
        mensaje:
            'Creá tu cuenta para denunciar publicaciones sospechosas. Así podemos darle seguimiento a tu reporte.',
      );
      return;
    }

    String? motivoSeleccionado;
    final comentarioCtrl = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.flag_outlined, color: _rojo),
            SizedBox(width: 8),
            Text('Reportar publicación', style: TextStyle(fontSize: 16)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccioná el motivo del reporte:',
                  style: TextStyle(fontSize: 13, color: _gris),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _motivosReporte.map((m) {
                    final activo = motivoSeleccionado == m;
                    return GestureDetector(
                      onTap: () => setDialogState(() => motivoSeleccionado = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: activo ? _rojo : _rojoBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: activo ? _rojo : _rojo.withOpacity(0.25)),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activo ? Colors.white : _rojo),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: comentarioCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Comentario adicional (opcional)',
                    hintStyle: const TextStyle(fontSize: 12, color: _gris),
                    filled: true,
                    fillColor: _grisClaro,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _rojo),
              onPressed: (enviando || motivoSeleccionado == null)
                  ? null
                  : () async {
                      setDialogState(() => enviando = true);
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      try {
                        final res = await http.post(
                          Uri.parse('${Constantes.baseUrl}/reportes'),
                          headers: {
                            'Authorization': 'Bearer ${auth.token}',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            'inmuebleId': widget.inmuebleId,
                            'motivo': motivoSeleccionado,
                            'comentario': comentarioCtrl.text.trim().isEmpty
                                ? null
                                : comentarioCtrl.text.trim(),
                          }),
                        );
                        final data = jsonDecode(res.body);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(data['ok'] == true
                              ? 'Reporte enviado. El administrador lo revisará.'
                              : (data['mensaje'] ?? 'Error al enviar reporte')),
                          backgroundColor:
                              data['ok'] == true ? _rojo : Colors.orange,
                        ));
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error de conexión'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Reportar',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCoContacto(Inmueble i) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Cómo quieres contactar?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Podés contactar al propietario solo, o invitar a tu roommate confirmado para postular juntos. '
          'Si lo invitás, la solicitud se enviará al propietario recién cuando tu roommate acepte.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(_);
              _contactarPropietario();
            },
            child: const Text('Solo'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(_);
              _seleccionarRoommate(i);
            },
            child: const Text('Con mi Roommate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarRoommate(Inmueble i) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    List<dynamic> conexiones = [];

    try {
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/convivencia/match/mis-conexiones'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) conexiones = data['datos'] as List;
    } catch (_) {}

    if (!mounted) return;

    if (conexiones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aún no tienes roommates confirmados en UniHab.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Elegí a tu roommate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ...conexiones.map((c) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _verdeClaro,
                  backgroundImage: c['fotoPerfil'] != null
                      ? NetworkImage(c['fotoPerfil'] as String)
                      : null,
                  child: c['fotoPerfil'] == null
                      ? Text(
                          (c['nombre'] as String)[0].toUpperCase(),
                          style: const TextStyle(
                              color: _verdeOscuro, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(c['nombre'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: c['institucion'] != null
                    ? Text(c['institucion'] as String,
                        style: const TextStyle(fontSize: 12))
                    : null,
                trailing: const Icon(Icons.chevron_right, color: _gris),
                onTap: () {
                  Navigator.pop(_);
                  _enviarCoSolicitud(
                      i, c['usuarioId'] as int, c['nombre'] as String);
                },
              )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Future<void> _enviarCoSolicitud(
      Inmueble i, int roommateId, String roommateNombre) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/notificaciones/co-solicitud'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inmuebleId': i.id, 'roommateId': roommateId}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Invitación enviada a $roommateNombre. Cuando acepte, la solicitud llegará al propietario.'),
          backgroundColor: _verde,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al enviar co-solicitud'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error de conexión'),
        backgroundColor: Colors.red,
      ));
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lon2 - lon1) * pi / 180;
    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatearDistancia(double metros) {
    if (metros < 1000) return 'A ${metros.round()} m';
    return 'A ${(metros / 1000).toStringAsFixed(1)} km';
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
    if (_inmueble == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Inmueble no encontrado')));
    }

    final i = _inmueble!;
    final reglas = _parseReglas(i.reglasComunes);
    final altura = MediaQuery.of(context).size.height * 0.35;
    final imagenes = i.imagenes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: altura,
                  child: imagenes.isNotEmpty
                      ? PageView.builder(
                          controller: _pageController,
                          itemCount: imagenes.length,
                          onPageChanged: (p) =>
                              setState(() => _currentPage = p),
                          itemBuilder: (_, idx) => GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GaleriaInmuebleScreen(
                                  imagenes: imagenes,
                                  indiceInicial: idx,
                                ),
                              ),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: imagenes[idx].url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.home_outlined,
                                      color: Colors.grey)),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.home_outlined,
                                size: 64, color: Colors.grey),
                          ),
                        ),
                ),
                if (imagenes.length > 1)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imagenes.length,
                        (idx) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == idx ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == idx
                                ? _verde
                                : _gris.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                _buildIdentidad(i),
                const Divider(height: 1, thickness: 0.5),
                _buildUbicacion(i),
                const Divider(height: 1, thickness: 0.5),
                _buildServicios(i),
                const Divider(height: 1, thickness: 0.5),
                _buildCaracteristicas(i),
                if (reglas.isNotEmpty) ...[
                  const Divider(height: 1, thickness: 0.5),
                  _buildReglas(reglas),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(children: [
              GestureDetector(
                onTap: () => _compartirInmueble(i),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined,
                      color: Colors.white, size: 19),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleFavoritoTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorito ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorito ? _rojo : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(i),
    );
  }

  Widget _buildIdentidad(Inmueble i) {
    final verificado = i.propietario?['verificado'] == true;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                i.tipoOferta == 'ANTICRETICO'
                    ? 'Bs. ${_formatearMiles(i.precio)}'
                    : 'Bs. ${_formatearMiles(i.precio)}/mes',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, color: _verde),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: i.tipoOferta == 'ANTICRETICO'
                      ? const Color(0xFFF5F3FF)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: i.tipoOferta == 'ANTICRETICO'
                          ? const Color(0xFF8B5CF6).withOpacity(0.3)
                          : const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Text(
                  i.tipoOferta == 'ANTICRETICO'
                      ? '🔑 Anticrético'
                      : '📋 Alquiler',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: i.tipoOferta == 'ANTICRETICO'
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: verificado ? _verdeClaro : _grisClaro,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: verificado
                        ? _verde.withOpacity(0.3)
                        : _gris.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    verificado ? Icons.verified : Icons.info_outline,
                    size: 13,
                    color: verificado ? _verdeOscuro : _gris,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    verificado ? 'Propietario verificado' : 'Sin verificar',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: verificado ? _verdeOscuro : _gris),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            i.titulo,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold, color: _textoOscuro),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _grisClaro, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _labelTipo(i.tipo),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: _gris),
                ),
              ),
              if (i.propietario != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.person_outline, size: 14, color: _gris),
                const SizedBox(width: 4),
                Text(
                  '${i.propietario!['nombre'] ?? 'Dueño'}',
                  style: const TextStyle(fontSize: 13, color: _gris),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacion(Inmueble i) {
    final tieneUbicacion = i.latitud != null && i.longitud != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ubicación',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: _gris),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${i.direccion}, ${i.zona}',
                  style: const TextStyle(fontSize: 13, color: _textoOscuro)),
            ),
          ]),
          const SizedBox(height: 12),
          if (tieneUbicacion)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: LatLng(i.latitud!, i.longitud!), zoom: 15),
                      markers: {
                        Marker(
                            markerId: const MarkerId('inmueble'),
                            position: LatLng(i.latitud!, i.longitud!)),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _MapaDetalleScreen(
                                latitud: i.latitud!,
                                longitud: i.longitud!,
                                titulo: i.titulo,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.fullscreen,
                                size: 16, color: _verdeOscuro),
                            SizedBox(width: 4),
                            Text('Ver mapa completo',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _textoOscuro)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final punto = auth.usuario?.puntoInteres;

            if (!tieneUbicacion || punto == null)
              return const SizedBox.shrink();

            final pLat = (punto['latitud'] as num).toDouble();
            final pLng = (punto['longitud'] as num).toDouble();
            final metros = _haversine(i.latitud!, i.longitud!, pLat, pLng);
            final distStr = _formatearDistancia(metros);
            final nombre = punto['nombre'] as String? ?? 'tu institución';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _verde.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.school_outlined,
                    size: 16, color: _verdeOscuro),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: _verdeOscuro),
                      children: [
                        TextSpan(
                          text: '$distStr de ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: nombre),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCaracteristicas(Inmueble i) {
    final List<Map<String, dynamic>> items = [];
    String? observaciones;

    if (i.tipo == 'CUARTO') {
      if (i.tamano != null)
        items.add({
          'icon': Icons.square_foot,
          'label': 'Tamaño',
          'valor': '${i.tamano!.toStringAsFixed(0)} m²'
        });
      if (i.piso != null)
        items.add({
          'icon': Icons.layers_outlined,
          'label': 'Piso',
          'valor': 'Piso ${i.piso}'
        });
      if (i.banoCompartido != null)
        items.add({
          'icon': Icons.bathroom_outlined,
          'label': 'Baño',
          'valor': i.banoCompartido! ? 'Compartido' : 'Privado'
        });
      if (i.generoPermitido != null)
        items.add({
          'icon': Icons.person_outline,
          'label': 'Género',
          'valor': _labelGenero(i.generoPermitido!)
        });
      if (i.amoblado != null)
        items.add({
          'icon': Icons.weekend_outlined,
          'label': 'Amoblado',
          'valor': i.amoblado! ? 'Sí' : 'No'
        });
      if (i.permiteMascotas != null)
        items.add({
          'icon': Icons.pets,
          'label': 'Mascotas',
          'valor': i.permiteMascotas! ? 'Sí' : 'No'
        });
    } else if (i.tipo == 'DEPARTAMENTO') {
      if (i.numDormitorios != null)
        items.add({
          'icon': Icons.bed_outlined,
          'label': 'Dormitorios',
          'valor': '${i.numDormitorios} cuartos'
        });
      if (i.numBanos != null)
        items.add({
          'icon': Icons.bathroom_outlined,
          'label': 'Baños',
          'valor': '${i.numBanos} baños'
        });
      if (i.piso != null)
        items.add({
          'icon': Icons.layers_outlined,
          'label': 'Piso',
          'valor': 'Piso ${i.piso}'
        });
      if (i.habitantesMax != null)
        items.add({
          'icon': Icons.people_outline,
          'label': 'Máx. Personas',
          'valor': '${i.habitantesMax} pers.'
        });
      if (i.generoPermitido != null)
        items.add({
          'icon': Icons.person_outline,
          'label': 'Género',
          'valor': _labelGenero(i.generoPermitido!)
        });
      if (i.tieneParqueo != null)
        items.add({
          'icon': Icons.local_parking,
          'label': 'Parqueo',
          'valor': i.tieneParqueo! ? 'Incluido' : 'No'
        });
      if (i.amoblado != null)
        items.add({
          'icon': Icons.weekend_outlined,
          'label': 'Amoblado',
          'valor': i.amoblado! ? 'Sí' : 'No'
        });
      if (i.permiteMascotas != null)
        items.add({
          'icon': Icons.pets,
          'label': 'Mascotas',
          'valor': i.permiteMascotas! ? 'Sí' : 'No'
        });
    } else if (i.tipo == 'COMPARTIDO') {
      if (i.habitacionesTotales != null)
        items.add({
          'icon': Icons.grid_view,
          'label': 'Hab. Totales',
          'valor': '${i.habitacionesTotales}'
        });
      if (i.habitacionesDisponibles != null)
        items.add({
          'icon': Icons.door_front_door_outlined,
          'label': 'Disponibles',
          'valor': '${i.habitacionesDisponibles} disp.'
        });
      if (i.banoCompartido != null)
        items.add({
          'icon': Icons.bathroom_outlined,
          'label': 'Baño',
          'valor': i.banoCompartido! ? 'Compartido' : 'Privado'
        });
      if (i.generoConvivientes != null)
        items.add({
          'icon': Icons.people_alt_outlined,
          'label': 'Convivientes',
          'valor': _labelGenero(i.generoConvivientes!)
        });
      if (i.generoPermitido != null)
        items.add({
          'icon': Icons.person_outline,
          'label': 'Postulante',
          'valor': _labelGenero(i.generoPermitido!)
        });
      if (i.soloEstudiantes != null)
        items.add({
          'icon': Icons.school_outlined,
          'label': 'Perfil',
          'valor': i.soloEstudiantes! ? 'Estudiantes' : 'Cualquiera'
        });
      if (i.permiteMascotas != null)
        items.add({
          'icon': Icons.pets,
          'label': 'Mascotas',
          'valor': i.permiteMascotas! ? 'Sí' : 'No'
        });
      if (i.edadMinima != null && i.edadMaxima != null)
        items.add({
          'icon': Icons.calendar_today_outlined,
          'label': 'Edades',
          'valor': '${i.edadMinima}–${i.edadMaxima} años'
        });
      if (i.observaciones != null && i.observaciones!.isNotEmpty)
        observaciones = i.observaciones;
    }

    if (items.isEmpty && observaciones == null) return const SizedBox.shrink();
    final chipW = (MediaQuery.of(context).size.width - 42) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Características',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map((item) => Container(
                      width: chipW,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: _grisClaro,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData,
                              size: 16, color: _gris),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item['label'] as String,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: _gris,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 1),
                                Text(
                                  item['valor'] as String,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _textoOscuro),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ))
                .toList(),
          ),
          if (observaciones != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _grisClaro, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Observaciones adicionales',
                      style: TextStyle(
                          fontSize: 11,
                          color: _gris,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(observaciones!,
                      style: const TextStyle(
                          fontSize: 13, color: _textoOscuro, height: 1.4)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildServicios(Inmueble i) {
    final servicios = <Map<String, dynamic>>[
      if (i.internetIncluido) {'icon': Icons.wifi, 'label': 'Internet'},
      if (i.luzIncluida) {'icon': Icons.bolt, 'label': 'Luz'},
      if (i.aguaIncluida) {'icon': Icons.water_drop, 'label': 'Agua'},
      if (i.gasIncluido) {'icon': Icons.local_fire_department, 'label': 'Gas'},
    ];
    if (servicios.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Servicios incluidos en el precio',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: servicios
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _verdeClaro,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _verde.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s['icon'] as IconData,
                              size: 14, color: _verdeOscuro),
                          const SizedBox(width: 6),
                          Text(s['label'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _verdeOscuro,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReglas(List<String> reglas) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reglas de la casa',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 14),
          ...reglas.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: _verdeClaro,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel_outlined,
                        size: 15,
                        color: _verdeOscuro,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textoOscuro,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Inmueble i) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: _contactando
                ? null
                : () {
                    if (i.tipo == 'COMPARTIDO' &&
                        !Provider.of<AuthProvider>(context, listen: false)
                            .esInvitado) {
                      _mostrarDialogoCoContacto(i);
                    } else {
                      _contactarPropietario();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            icon: _contactando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.phone_android,
                    size: 20, color: Colors.white),
            label: Text(
              _contactando ? 'Registrando...' : 'Contactar Propietario',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: _reportarInmueble,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _rojoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rojo.withOpacity(0.25)),
              ),
              child: const Icon(Icons.flag_outlined, color: _rojo, size: 20),
            ),
          ),
        )
      ]),
    );
  }
}

class _MapaDetalleScreen extends StatelessWidget {
  final double latitud;
  final double longitud;
  final String titulo;

  const _MapaDetalleScreen(
      {required this.latitud, required this.longitud, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: LatLng(latitud, longitud), zoom: 16),
        markers: {
          Marker(
              markerId: const MarkerId('inmueble'),
              position: LatLng(latitud, longitud),
              infoWindow: InfoWindow(title: titulo)),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}
