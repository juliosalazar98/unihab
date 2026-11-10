import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '/config/constantes.dart';
import '/models/inmueble.dart';
import '/models/notificacion.dart';
import '/providers/authProvider.dart';
import '/services/inmuebleService.dart';
import '/widgets/inmuebleCard.dart';
import '../arrendatario/detalleInmuebleScreen.dart';
import 'perfilArrendatarioScreen.dart';
import 'misSolicitudesArrendatarioScreen.dart';
import 'mapaArrendatarioScreen.dart';
import 'convivencia/convivenciaTab.dart';
import 'favorito_sheet.dart';
import 'favoritosTab.dart';
import '/widgets/muroRegistro.dart';

class ArrendatarioHomeScreen extends StatefulWidget {
  const ArrendatarioHomeScreen({super.key});

  @override
  State<ArrendatarioHomeScreen> createState() => _ArrendatarioHomeScreenState();
}

class _ArrendatarioHomeScreenState extends State<ArrendatarioHomeScreen> {
  static const _verde = Color(0xFF10B981);
  static const _gris = Color(0xFF9CA3AF);

  int _tabActual = 0;
  int _notificacionesNoLeidas = 0;
  Timer? _timerNotificaciones;

  final _convivenciaKey = GlobalKey<ConvivenciaTabState>();

  static const _iconos = [
    Icons.travel_explore,
    Icons.location_on_outlined,
    Icons.people_alt_outlined,
    Icons.favorite_border,
    Icons.account_circle_outlined,
  ];
  static const _labels = [
    'Explorar',
    'Mapa',
    'Convivencia',
    'Favoritos',
    'Perfil'
  ];

  bool get _esInvitado =>
      Provider.of<AuthProvider>(context, listen: false).esInvitado;

  static const _tabsBloqueadas = {2, 3, 4};

  @override
  void initState() {
    super.initState();
    if (Provider.of<AuthProvider>(context, listen: false).esInvitado) return;

    _cargarBadgeNotificaciones();
    _timerNotificaciones = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cargarBadgeNotificaciones(),
    );
  }

  void _muroDeTab(int i) {
    final datos = {
      2: [
        Icons.people_alt_outlined,
        'Encontrá tu roommate',
        'Creá tu cuenta para hacer el test de convivencia y conectar con estudiantes compatibles con tu estilo de vida.',
      ],
      3: [
        Icons.favorite_border,
        'Guardá tus favoritos',
        'Creá tu cuenta para armar listas con los inmuebles que te interesan y volver a ellos cuando quieras.',
      ],
      4: [
        Icons.account_circle_outlined,
        'Tu perfil en UniHab',
        'Creá tu cuenta para registrar tu institución, ver la distancia a cada inmueble y seguir tus solicitudes.',
      ],
    }[i]!;

    mostrarMuroRegistro(
      context,
      icono: datos[0] as IconData,
      titulo: datos[1] as String,
      mensaje: datos[2] as String,
    );
  }

  @override
  void dispose() {
    _timerNotificaciones?.cancel();
    super.dispose();
  }

  Future<void> _cargarBadgeNotificaciones() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/notificaciones'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(
            () => _notificacionesNoLeidas = data['datos']['noLeidas'] as int);
      }
    } catch (_) {}
  }

  void _abrirNotificaciones() async {
    _timerNotificaciones?.cancel();
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificacionesSheet(
        token: token,
        onIrAConvivencia: () {
          setState(() => _tabActual = 2);
          // La pestaña ya existe en el IndexedStack, hay que pedirle los datos.
          _convivenciaKey.currentState?.recargar();
        },
      ),
    );
    if (mounted) setState(() => _notificacionesNoLeidas = 0);
    _timerNotificaciones = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _cargarBadgeNotificaciones(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'UniHab',
          style: TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        actions: [
          if (_esInvitado)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/registro'),
                style: TextButton.styleFrom(foregroundColor: _verde),
                child: const Text('Crear cuenta',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Color(0xFF1F2937)),
                    onPressed: _abrirNotificaciones,
                  ),
                  if (_notificacionesNoLeidas > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          _notificacionesNoLeidas > 9
                              ? '9+'
                              : '$_notificacionesNoLeidas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _tabActual,
        children: _esInvitado
            ? const [
                _ExplorarTab(),
                MapaArrendatarioScreen(),
                SizedBox.shrink(),
                SizedBox.shrink(),
                SizedBox.shrink(),
              ]
            : [
                const _ExplorarTab(),
                const MapaArrendatarioScreen(),
                ConvivenciaTab(key: _convivenciaKey),
                const FavoritosTab(),
                const PerfilArrendatarioScreen(),
              ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 8,
      ),
      child: Row(
        children: List.generate(_iconos.length, (i) {
          final activo = _tabActual == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_esInvitado && _tabsBloqueadas.contains(i)) {
                  _muroDeTab(i);
                  return;
                }
                setState(() => _tabActual = i);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: activo
                          ? _verde.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_iconos[i],
                        color: activo ? _verde : _gris, size: 22),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: activo ? _verde : _gris,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NotificacionesSheet extends StatefulWidget {
  final String token;
  final VoidCallback onIrAConvivencia;
  const _NotificacionesSheet({
    required this.token,
    required this.onIrAConvivencia,
  });

  @override
  State<_NotificacionesSheet> createState() => _NotificacionesSheetState();
}

class _NotificacionesSheetState extends State<_NotificacionesSheet> {
  static const _verde = Color(0xFF10B981);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _gris = Color(0xFF9CA3AF);

  List<Notificacion> _notificaciones = [];
  bool _cargando = true;
  final Set<int> _expandidas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/notificaciones'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _notificaciones = (data['datos']['notificaciones'] as List)
            .map((e) => Notificacion.fromJson(e))
            .toList();
        _marcarTodasLeidas();
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _marcarTodasLeidas() async {
    try {
      await http.patch(
        Uri.parse('${Constantes.baseUrl}/notificaciones/leer-todas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
    } catch (_) {}
  }

  Future<void> _eliminar(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${Constantes.baseUrl}/notificaciones/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() => _notificaciones.removeWhere((n) => n.id == id));
      }
    } catch (_) {}
  }

  String _tiempoAtras(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return 'Hace ${diff.inDays ~/ 7} sem';
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'MATCH_SOLICITUD':
        return Icons.person_add_outlined;
      case 'MATCH_ACEPTADO':
        return Icons.handshake_outlined;
      case 'CO_SOLICITUD':
        return Icons.home_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo) {
      case 'MATCH_SOLICITUD':
        return Colors.blue;
      case 'MATCH_ACEPTADO':
        return _verde;
      case 'CO_SOLICITUD':
        return Colors.purple;
      default:
        return _gris;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
          child: Row(children: [
            const Text('Notificaciones',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
            const Spacer(),
            if (_notificaciones.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _marcarTodasLeidas();
                  for (final n in List.from(_notificaciones)) {
                    await _eliminar(n.id);
                  }
                },
                child: const Text('Limpiar todo',
                    style: TextStyle(color: _gris, fontSize: 13)),
              ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: _verde))
              : _notificaciones.isEmpty
                  ? _buildVacio()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _notificaciones.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (_, i) => _buildItem(_notificaciones[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildItem(Notificacion n) {
    final color = _colorPorTipo(n.tipo);
    return Dismissible(
      key: Key('n_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFEF4444),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _eliminar(n.id),
      child: InkWell(
        onTap: () => _abrirDestino(n),
        child: Container(
          color: n.leido ? Colors.white : const Color(0xFFFFFBEB),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconoPorTipo(n.tipo), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(n.titulo,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                n.leido ? FontWeight.w500 : FontWeight.bold,
                            color: _textoOscuro)),
                  ),
                  if (!n.leido)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: Colors.orange, shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 3),
                LayoutBuilder(builder: (_, restricciones) {
                  const estilo = TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280), height: 1.4);
                  final expandida = _expandidas.contains(n.id);

                  // Mide el texto para saber si realmente excede las 3 líneas.
                  final medidor = TextPainter(
                    text: TextSpan(text: n.mensaje, style: estilo),
                    maxLines: 3,
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: restricciones.maxWidth);
                  final desborda = medidor.didExceedMaxLines;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.mensaje,
                        maxLines: expandida ? null : 3,
                        overflow: expandida
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: estilo,
                      ),
                      if (desborda) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() {
                            if (expandida) {
                              _expandidas.remove(n.id);
                            } else {
                              _expandidas.add(n.id);
                            }
                          }),
                          child: Text(
                            expandida ? 'Ver menos' : 'Ver más',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _verde,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 5),
                Text(_tiempoAtras(n.creadoEn),
                    style: const TextStyle(fontSize: 11, color: _gris)),
              ],
            )),
            GestureDetector(
              onTap: () => _eliminar(n.id),
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close, size: 15, color: _gris),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _abrirDestino(Notificacion n) {
    const tiposNavegables = {
      'CO_SOLICITUD',
      'MATCH_SOLICITUD',
      'MATCH_ACEPTADO',
    };

    if (!tiposNavegables.contains(n.tipo)) return;

    Navigator.pop(context);

    if (n.tipo == 'CO_SOLICITUD') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const MisSolicitudesArrendatarioScreen()),
      );
    } else {
      widget.onIrAConvivencia();
    }
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.notifications_off_outlined,
              size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Sin notificaciones',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 8),
          Text('Aquí verás los avisos de tu actividad en UniHab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[400], height: 1.5)),
        ]),
      ),
    );
  }
}

class _ExplorarTab extends StatefulWidget {
  const _ExplorarTab();

  @override
  State<_ExplorarTab> createState() => _ExplorarTabState();
}

class _ExplorarTabState extends State<_ExplorarTab> {
  final InmuebleService _service = InmuebleService();
  final _zonaController = TextEditingController();
  List<Inmueble> _inmuebles = [];
  bool _cargando = true;
  String? _tipoSeleccionado;
  String? _tipoOfertaSeleccionado; // null = todos
  String _orden = 'recientes';
  final Set<String> _servicios = {};
  int _pagina = 1;
  int _totalPaginas = 1;

  static const _serviciosLabels = {
    'luz': '💡 Luz',
    'agua': '💧 Agua',
    'internet': '📶 Internet',
    'gas': '🔥 Gas',
  };

  static const _ordenes = {
    'recientes': 'Más recientes',
    'precio_asc': 'Menor precio',
    'precio_desc': 'Mayor precio',
    'distancia': 'Más cerca',
  };

  final List<String> _tipos = ['TODOS', 'CUARTO', 'DEPARTAMENTO', 'COMPARTIDO'];
  Map<int, Map<String, dynamic>> _favoritosMap = {};

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarEstadoFavoritos(); // ← AÑADIR
  }

  @override
  void dispose() {
    _zonaController.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool reset = false}) async {
    if (reset) _pagina = 1;
    setState(() => _cargando = true);

    final porDistancia = _orden == 'distancia';

    final resultado = await _service.obtenerInmuebles(
      zona: _zonaController.text.trim(),
      tipo: _tipoSeleccionado == 'TODOS' ? null : _tipoSeleccionado,
      tipoOferta: _tipoOfertaSeleccionado,
      orden: porDistancia ? null : _orden,
      servicios: _servicios.isEmpty ? null : _servicios,
      page: porDistancia ? 1 : _pagina,
      limit: porDistancia ? 100 : 10,
    );

    List<Inmueble> lista = resultado['inmuebles'];
    if (porDistancia) lista = _ordenarPorDistancia(lista);

    setState(() {
      _inmuebles = lista;
      _totalPaginas = porDistancia ? 1 : resultado['totalPaginas'];
      _cargando = false;
    });
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

  List<Inmueble> _ordenarPorDistancia(List<Inmueble> lista) {
    final punto =
        Provider.of<AuthProvider>(context, listen: false).usuario?.puntoInteres;
    if (punto == null) return lista;

    final lat = (punto['latitud'] as num).toDouble();
    final lng = (punto['longitud'] as num).toDouble();

    final conCoords = lista.where((i) => i.latitud != null).toList();
    final sinCoords = lista.where((i) => i.latitud == null).toList();

    conCoords.sort((a, b) {
      final da = _haversine(a.latitud!, a.longitud!, lat, lng);
      final db = _haversine(b.latitud!, b.longitud!, lat, lng);
      return da.compareTo(db);
    });

    return [...conCoords, ...sinCoords];
  }

  void _mostrarSelectorOrden() {
    final tieneInstitucion = Provider.of<AuthProvider>(context, listen: false)
            .usuario
            ?.puntoInteres !=
        null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
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
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Ordenar por',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            ..._ordenes.entries.map((e) {
              final deshabilitado = e.key == 'distancia' && !tieneInstitucion;
              final activo = _orden == e.key;
              final esPorDefecto = e.key == 'recientes';

              return ListTile(
                enabled: !deshabilitado,
                leading: Icon(
                  activo
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: activo ? const Color(0xFF10B981) : Colors.grey[400],
                  size: 20,
                ),
                title: Text(e.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                    )),
                subtitle: deshabilitado
                    ? const Text('Registrá tu institución en el perfil',
                        style: TextStyle(fontSize: 11))
                    : (activo && !esPorDefecto
                        ? const Text('Toca de nuevo para quitar este orden',
                            style: TextStyle(fontSize: 11))
                        : null),
                onTap: () {
                  // Tocar la opción activa devuelve al orden por defecto.
                  final nuevo = activo ? 'recientes' : e.key;
                  Navigator.pop(sheetCtx);
                  if (nuevo == _orden) return;
                  setState(() => _orden = nuevo);
                  _cargar(reset: true);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarEstadoFavoritos() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.esInvitado) return;
    try {
      final token = auth.token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/favoritos/estado'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        final mapa = <int, Map<String, dynamic>>{};
        for (final f in data['datos'] as List) {
          mapa[f['inmuebleId'] as int] = {
            'listaId': f['listaId'],
            'nombreLista': f['nombreLista'],
          };
        }
        setState(() => _favoritosMap = mapa);
      }
    } catch (_) {}
  }

  void _mostrarSnackFavorito(BuildContext context,
      {required bool guardado, String? nombreLista}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: guardado
            ? const Color(0xFF059669) // Verde esmeralda oscuro
            : Colors.grey[850], // Gris oscuro elegante
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
          if (guardado && nombreLista != null)
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text(
                'Modificar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _handleFavoritoTap(int inmuebleId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.esInvitado) {
      mostrarMuroRegistro(
        context,
        icono: Icons.favorite_border,
        titulo: 'Guardá tus favoritos',
        mensaje:
            'Creá tu cuenta para armar listas con los inmuebles que te interesan.',
      );
      return;
    }
    final token = auth.token ?? '';
    final favInfo = _favoritosMap[inmuebleId];

    final result = await mostrarFavoritoSheet(
      context,
      inmuebleId: inmuebleId,
      token: token,
      isFavorito: favInfo != null,
      listaId: favInfo?['listaId'] as int?,
      nombreLista: favInfo?['nombreLista'] as String?,
    );

    if (result == null || !mounted) return;

    if (result['action'] == 'saved') {
      setState(() => _favoritosMap[inmuebleId] = {
            'listaId': result['listaId'],
            'nombreLista': result['nombreLista'],
          });
    } else {
      setState(() => _favoritosMap.remove(inmuebleId));
    }

    final msg = result['action'] == 'saved'
        ? 'Guardado en ${result['nombreLista']}'
        : 'Eliminado de ${result['nombreLista']}';

    if (mounted) {
      _mostrarSnackFavorito(
        context,
        guardado: result['action'] == 'saved',
        nombreLista: result['nombreLista'] as String?,
      );
    }
  }

  int get _filtrosActivos =>
      _servicios.length + (_tipoOfertaSeleccionado != null ? 1 : 0);

  void _mostrarPanelFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                const Text('Filtros',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_filtrosActivos > 0)
                  TextButton(
                    onPressed: () {
                      setSheet(() {
                        _servicios.clear();
                        _tipoOfertaSeleccionado = null;
                      });
                      setState(() {});
                      _cargar(reset: true);
                    },
                    child: const Text('Limpiar',
                        style:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                  ),
              ]),
              const SizedBox(height: 18),
              const Text('Tipo de oferta',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                _chipPanel(
                  label: 'Todos',
                  activo: _tipoOfertaSeleccionado == null,
                  onTap: () {
                    setSheet(() => _tipoOfertaSeleccionado = null);
                    setState(() {});
                    _cargar(reset: true);
                  },
                ),
                _chipPanel(
                  label: 'Alquiler',
                  activo: _tipoOfertaSeleccionado == 'ALQUILER',
                  onTap: () {
                    setSheet(() => _tipoOfertaSeleccionado = 'ALQUILER');
                    setState(() {});
                    _cargar(reset: true);
                  },
                ),
                _chipPanel(
                  label: 'Anticrético',
                  activo: _tipoOfertaSeleccionado == 'ANTICRETICO',
                  onTap: () {
                    setSheet(() => _tipoOfertaSeleccionado = 'ANTICRETICO');
                    setState(() {});
                    _cargar(reset: true);
                  },
                ),
              ]),
              const SizedBox(height: 22),
              const Text('Servicios incluidos',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _serviciosLabels.entries.map((e) {
                  return _chipPanel(
                    label: e.value,
                    activo: _servicios.contains(e.key),
                    onTap: () {
                      setSheet(() {
                        _servicios.contains(e.key)
                            ? _servicios.remove(e.key)
                            : _servicios.add(e.key);
                      });
                      setState(() {});
                      _cargar(reset: true);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipPanel({
    required String label,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFECFDF5) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: activo ? const Color(0xFF10B981) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? const Color(0xFF059669) : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(children: [
          TextField(
            controller: _zonaController,
            decoration: InputDecoration(
              hintText: 'Buscar por zona (Cala Cala, Quillacollo...)',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: _mostrarPanelFiltros,
                  ),
                  if (_filtrosActivos > 0)
                    Positioned(
                      right: 8,
                      top: 10,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: Color(0xFF10B981), shape: BoxShape.circle),
                        child: Center(
                          child: Text('$_filtrosActivos',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            onSubmitted: (_) => _cargar(reset: true),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tipos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tipo = _tipos[i];
                    final sel = _tipoSeleccionado == tipo ||
                        (tipo == 'TODOS' && _tipoSeleccionado == null);
                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                            _tipoSeleccionado = tipo == 'TODOS' ? null : tipo);
                        _cargar(reset: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              sel ? const Color(0xFF10B981) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo == 'TODOS'
                              ? 'Todos'
                              : tipo[0] + tipo.substring(1).toLowerCase(),
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _mostrarSelectorOrden,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _orden == 'recientes'
                      ? Colors.grey[100]
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _orden == 'recientes'
                        ? Colors.transparent
                        : const Color(0xFF10B981),
                  ),
                ),
                child: Icon(Icons.swap_vert,
                    size: 18,
                    color: _orden == 'recientes'
                        ? Colors.black87
                        : const Color(0xFF059669)),
              ),
            ),
          ]),
        ]),
      ),
      Expanded(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : _inmuebles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No se encontraron inmuebles',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF10B981),
                    onRefresh: () => _cargar(reset: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _inmuebles.length,
                      itemBuilder: (_, i) => InmuebleCard(
                        inmueble: _inmuebles[i],
                        isFavorito: _favoritosMap
                            .containsKey(_inmuebles[i].id), // ← nuevo
                        onFavoritoTap: () =>
                            _handleFavoritoTap(_inmuebles[i].id), // ← nuevo
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleInmuebleScreen(
                                inmuebleId: _inmuebles[i].id),
                          ),
                        ).then((_) => _cargarEstadoFavoritos()),
                      ),
                    ),
                  ),
      ),
      if (_totalPaginas > 1)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _pagina > 1
                    ? () {
                        setState(() => _pagina--);
                        _cargar();
                      }
                    : null,
              ),
              Text('$_pagina de $_totalPaginas'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _pagina < _totalPaginas
                    ? () {
                        setState(() => _pagina++);
                        _cargar();
                      }
                    : null,
              ),
            ],
          ),
        ),
    ]);
  }
}

class _ProximamenteTab extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descripcion;

  const _ProximamenteTab({
    required this.icon,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
                color: Color(0xFFECFDF5), shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: const Color(0xFF10B981)),
          ),
          const SizedBox(height: 20),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Próximamente',
                style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          Text(descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: 13, height: 1.6)),
        ]),
      ),
    );
  }
}
