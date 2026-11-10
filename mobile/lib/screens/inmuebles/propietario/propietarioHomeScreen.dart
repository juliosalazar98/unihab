import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'perfilEstudianteScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../arrendatario/detalleInmuebleScreen.dart';
import '/config/constantes.dart';
import '/models/inmueble.dart';
import '/models/notificacion.dart';
import '/providers/authProvider.dart';
import 'crearInmuebleScreen.dart';
import 'editarInmuebleScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'estadisticasPropietarioTab.dart';
import 'perfilPropietarioTab.dart';
import 'estadisticasPropietarioTab.dart';

class PropietarioHomeScreen extends StatefulWidget {
  const PropietarioHomeScreen({super.key});

  @override
  State<PropietarioHomeScreen> createState() => _PropietarioHomeScreenState();
}

class _PropietarioHomeScreenState extends State<PropietarioHomeScreen> {
  static const _verde = Color(0xFF10B981);
  static const _gris = Color(0xFF9CA3AF);

  int _tabActual = 0;
  int _notificacionesNoLeidas = 0;
  Timer? _timerNotificaciones;
  final GlobalKey<_MisInmueblesTabState> _misInmueblesKey =
      GlobalKey<_MisInmueblesTabState>();

  static const _iconos = [
    Icons.home_work,
    Icons.contact_mail,
    Icons.bar_chart,
    Icons.badge,
  ];
  static const _labels = ['Inmuebles', 'Solicitudes', 'Estadísticas', 'Perfil'];

  @override
  void initState() {
    super.initState();
    _cargarBadgeNotificaciones();
    _timerNotificaciones = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _cargarBadgeNotificaciones(),
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

  Future<void> _abrirNotificaciones() async {
    _timerNotificaciones?.cancel();
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificacionesPropietarioSheet(token: token),
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('UniHab',
            style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        actions: [
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
        children: [
          _MisInmueblesTab(key: _misInmueblesKey),
          const _SolicitudesTab(),
          const EstadisticasPropietarioTab(),
          const PerfilPropietarioTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _tabActual == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CrearInmuebleScreen()),
                );
                _misInmueblesKey.currentState?._cargar();
              },
              backgroundColor: _verde,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Publicar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
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
        top: 10,
      ),
      child: Row(
        children: List.generate(_iconos.length, (i) {
          final activo = _tabActual == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tabActual = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo
                          ? _verde.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_iconos[i],
                        color: activo ? _verde : _gris, size: 22),
                  ),
                  const SizedBox(height: 3),
                  Text(_labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: activo ? _verde : _gris,
                        fontWeight:
                            activo ? FontWeight.w600 : FontWeight.normal,
                      )),
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

class _NotificacionesPropietarioSheet extends StatefulWidget {
  final String token;
  const _NotificacionesPropietarioSheet({required this.token});

  @override
  State<_NotificacionesPropietarioSheet> createState() =>
      _NotificacionesPropietarioSheetState();
}

class _NotificacionesPropietarioSheetState
    extends State<_NotificacionesPropietarioSheet> {
  static const _verde = Color(0xFF10B981);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _gris = Color(0xFF9CA3AF);

  List<Notificacion> _notificaciones = [];
  bool _cargando = true;

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

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'INMUEBLE_APROBADO':
        return Icons.check_circle_outline;
      case 'INMUEBLE_RECHAZADO':
        return Icons.cancel_outlined;
      case 'VERIFICACION_REVISION':
        return Icons.hourglass_empty_outlined;
      case 'VERIFICACION_APROBADA':
        return Icons.verified_outlined;
      case 'VERIFICACION_RECHAZADA':
        return Icons.warning_amber_outlined;
      case 'NUEVA_SOLICITUD':
        return Icons.contact_mail_outlined;
      case 'CO_SOLICITUD_PROPIETARIO':
        return Icons.group_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorPorTipo(String tipo) {
    switch (tipo) {
      case 'INMUEBLE_APROBADO':
        return _verde;
      case 'INMUEBLE_RECHAZADO':
        return const Color(0xFFEF4444);
      case 'VERIFICACION_REVISION':
        return const Color(0xFFF59E0B);
      case 'VERIFICACION_APROBADA':
        return _verde;
      case 'VERIFICACION_RECHAZADA':
        return const Color(0xFFEF4444);
      case 'NUEVA_SOLICITUD':
        return const Color(0xFF8B5CF6);
      case 'CO_SOLICITUD_PROPIETARIO':
        return const Color(0xFF06B6D4);
      default:
        return _gris;
    }
  }

  String _tiempoAtras(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return 'Hace ${diff.inDays ~/ 7} sem';
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
      child: Container(
        color: n.leido ? Colors.white : const Color(0xFFFFFBEB),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
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
              Text(n.mensaje,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
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
    );
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
          Text(
              'Aquí verás el estado de tus publicaciones\ny verificación de cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[400], height: 1.5)),
        ]),
      ),
    );
  }
}

class _MisInmueblesTab extends StatefulWidget {
  const _MisInmueblesTab({super.key});

  @override
  State<_MisInmueblesTab> createState() => _MisInmueblesTabState();
}

class _MisInmueblesTabState extends State<_MisInmueblesTab> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  List<Inmueble> _inmuebles = [];
  bool _cargando = true;
  String _filtroActual = 'Todos';

  static const _filtros = ['Todos', 'Activos', 'Inactivos', 'Pendientes'];

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/inmuebles/mis-inmuebles'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() {
          _inmuebles =
              (data['datos'] as List).map((i) => Inmueble.fromJson(i)).toList();
        });
      }
    } catch (_) {}
    setState(() => _cargando = false);
  }

  List<Inmueble> get _inmueblesFiltrados {
    switch (_filtroActual) {
      case 'Activos':
        return _inmuebles.where((i) => i.aprobado && i.disponible).toList();
      case 'Inactivos':
        return _inmuebles.where((i) => i.aprobado && !i.disponible).toList();
      case 'Pendientes':
        return _inmuebles.where((i) => !i.aprobado && i.disponible).toList();
      default:
        return _inmuebles;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _verde));
    }

    final filtrados = _inmueblesFiltrados;

    return RefreshIndicator(
      color: _verde,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildMetricas(),
          const SizedBox(height: 16),
          if (_inmuebles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(children: [
                Icon(Icons.home_work_outlined,
                    size: 72, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Aún no tienes publicaciones',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
                const SizedBox(height: 8),
                Text('Tocá "Publicar" para agregar tu primer inmueble',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ]),
            )
          else ...[
            _buildFiltros(),
            const SizedBox(height: 16),
            if (filtrados.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(children: [
                  Icon(Icons.search_off_rounded,
                      size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Sin inmuebles en "$_filtroActual"',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500])),
                ]),
              )
            else
              ...filtrados
                  .map((i) => _MiInmuebleCard(inmueble: i, onRefresh: _cargar)),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricas() {
    final total = _inmuebles.length;
    final aprobados =
        _inmuebles.where((i) => i.aprobado && i.disponible).length;
    final inactivos =
        _inmuebles.where((i) => i.aprobado && !i.disponible).length;

    return Row(children: [
      Expanded(child: _metricaCard('Publicados', total, _verde, _verdeClaro)),
      const SizedBox(width: 10),
      Expanded(
          child: _metricaCard(
              'Aprobados', aprobados, _verdeOscuro, const Color(0xFFD1FAE5))),
      const SizedBox(width: 10),
      Expanded(child: _metricaCard('Inactivos', inactivos, _gris, _grisClaro)),
    ]);
  }

  Widget _metricaCard(String label, int valor, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Center(
              child: Text('$valor',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color))),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filtros.map((f) {
          final activo = _filtroActual == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f),
              selected: activo,
              onSelected: (_) => setState(() => _filtroActual = f),
              selectedColor: _verde,
              backgroundColor: _grisClaro,
              side: BorderSide(color: activo ? _verde : Colors.transparent),
              labelStyle: TextStyle(
                color: activo ? Colors.white : _textoOscuro,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiInmuebleCard extends StatelessWidget {
  final Inmueble inmueble;
  final VoidCallback onRefresh;

  const _MiInmuebleCard({required this.inmueble, required this.onRefresh});

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  _EstadoData _getEstado() {
    if (inmueble.aprobado && inmueble.disponible)
      return _EstadoData('Aprobado', _verde, const Color(0xFFECFDF5),
          Icons.check_circle_outline);
    if (!inmueble.aprobado && !inmueble.disponible)
      return _EstadoData(
          'Rechazado', _rojo, const Color(0xFFFEF2F2), Icons.cancel_outlined);
    if (inmueble.aprobado && !inmueble.disponible) {
      if (inmueble.enApelacion) {
        return _EstadoData(
          'En apelación',
          const Color(0xFF3B82F6),
          const Color(0xFFEFF6FF),
          Icons.hourglass_top_outlined,
        );
      }
      return _EstadoData('Inactivo', _gris, const Color(0xFFF3F4F6),
          Icons.pause_circle_outline);
    }
    return _EstadoData('Pendiente', const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB), Icons.schedule_outlined);
  }

  List<PopupMenuEntry<String>> _buildMenuItems(_EstadoData estado) {
    PopupMenuItem<String> item(
            String v, IconData ico, String label, Color color) =>
        PopupMenuItem(
          value: v,
          child: Row(children: [
            Icon(ico, color: color, size: 18),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w500, fontSize: 13)),
          ]),
        );

    switch (estado.label) {
      case 'Aprobado':
        return [
          item('ver', Icons.visibility_outlined, 'Ver publicación',
              const Color(0xFF1F2937)),
          item('pausar', Icons.pause_circle_outline, 'Pausar publicación',
              Colors.orange),
          item('editar', Icons.edit_outlined, 'Editar', Colors.grey.shade700),
        ];
      case 'Pendiente':
        return [
          item('editar', Icons.edit_outlined, 'Editar', Colors.grey.shade700),
          item('eliminar', Icons.delete_outline, 'Eliminar', _rojo),
        ];
      case 'Rechazado':
        return [
          item('editar', Icons.edit_outlined, 'Corregir y reenviar', _verde),
          item('eliminar', Icons.delete_outline, 'Eliminar', _rojo),
        ];
      case 'Inactivo':
      default:
        return [
          item('reactivar', Icons.play_circle_outline, 'Reactivar', _verde),
          item('editar', Icons.edit_outlined, 'Editar', Colors.grey.shade700),
          item('eliminar', Icons.delete_outline, 'Eliminar', _rojo),
        ];
    }
  }

  void _manejarAccion(BuildContext context, String accion, _EstadoData estado) {
    switch (accion) {
      case 'ver':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    DetalleInmuebleScreen(inmuebleId: inmueble.id)));
        break;
      case 'editar':
        estado.label == 'Aprobado'
            ? _mostrarAdvertencia(context)
            : _irAEditar(context);
        break;
      case 'eliminar':
        _confirmarEliminar(context);
        break;
      case 'pausar':
        _toggleDisponible(context, false);
        break;
      case 'reactivar':
        _toggleDisponible(context, true);
        break;
    }
  }

  void _mostrarAdvertencia(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text('Atención', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text(
            'Al editar esta publicación, deberá ser revisada nuevamente por el administrador.',
            style: TextStyle(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _irAEditar(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _verde),
            child: const Text('Entendido, editar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Eliminar', style: TextStyle(fontSize: 16)),
        ]),
        content: Text(
            '¿Seguro que querés eliminar "${inmueble.titulo}"? Esta acción no se puede deshacer.',
            style: const TextStyle(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminar(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _rojo),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _irAEditar(BuildContext context) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EditarInmuebleScreen(inmueble: inmueble)))
        .then((_) => onRefresh());
  }

  Future<void> _eliminar(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await http.delete(
      Uri.parse('${Constantes.baseUrl}/inmuebles/${inmueble.id}'),
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );
    final data = jsonDecode(res.body);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: data['ok'] == true ? _verde : _rojo,
      content:
          Text(data['ok'] == true ? 'Inmueble eliminado' : 'Error al eliminar'),
    ));
    if (data['ok'] == true) onRefresh();
  }

  Future<void> _toggleDisponible(BuildContext context, bool valor) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await http.patch(
      Uri.parse('${Constantes.baseUrl}/inmuebles/${inmueble.id}/disponible'),
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'disponible': valor}),
    );
    final data = jsonDecode(res.body);
    if (!context.mounted) return;

    final mensaje = data['mensaje'] as String? ??
        (valor ? 'Publicación reactivada' : 'Publicación pausada');
    final esReenvioRevision = mensaje.toLowerCase().contains('revisión');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: esReenvioRevision ? const Color(0xFFF59E0B) : _verde,
      content: Text(mensaje),
    ));
    if (data['ok'] == true) onRefresh();
  }

  bool get _esConductual {
    final m = inmueble.motivoRechazo ?? '';
    return m.contains('Contacto agresivo') || m.contains('Inmueble no existe');
  }

  Future<void> _mostrarApelacion(BuildContext context) async {
    final ctrl = TextEditingController();
    bool enviando = false;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final esContactoAgresivo =
        inmueble.motivoRechazo?.contains('Contacto agresivo') == true;
    final List<File> pruebas = [];
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                const Icon(Icons.balance, color: _rojo, size: 20),
                const SizedBox(width: 8),
                const Text('Apelar decisión',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: const Text(
                  'Tu apelación será revisada por el equipo administrativo de UniHab en un plazo máximo de 24 horas. Por favor, sé claro con tus descargos.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Escribe aquí tus argumentos o aclaraciones (ej: "El precio subió temporalmente por temporada", "Ya cambié las fotos por unas más nítidas", etc.)...',
                  hintStyle: const TextStyle(fontSize: 12, color: _gris),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _verde, width: 1.5)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (esContactoAgresivo) ...[
                const SizedBox(height: 14),
                StatefulBuilder(
                  builder: (_, setImg) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Capturas de prueba (máx. 3)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _textoOscuro)),
                          if (pruebas.length < 3)
                            GestureDetector(
                              onTap: () async {
                                final xFile = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80);
                                if (xFile != null) {
                                  setSheet(() => pruebas.add(File(xFile.path)));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _verdeClaro,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _verde.withOpacity(0.3)),
                                ),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 14, color: _verdeOscuro),
                                      SizedBox(width: 4),
                                      Text('Agregar',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: _verdeOscuro,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pruebas.isNotEmpty)
                        Row(
                          children: pruebas.asMap().entries.map((e) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                        image: FileImage(e.value),
                                        fit: BoxFit.cover),
                                    border: Border.all(
                                        color: _verde.withOpacity(0.4)),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setSheet(() => pruebas.removeAt(e.key)),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                      else
                        Text('Sin capturas adjuntadas',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (ctrl.text.trim().isEmpty) return;
                          setSheet(() => enviando = true);
                          try {
                            final request = http.MultipartRequest(
                              'POST',
                              Uri.parse(
                                  '${Constantes.baseUrl}/inmuebles/${inmueble.id}/apelar'),
                            )
                              ..headers['Authorization'] =
                                  'Bearer ${auth.token}'
                              ..fields['texto'] = ctrl.text.trim();

                            for (final file in pruebas) {
                              request.files.add(
                                  await http.MultipartFile.fromPath(
                                      'pruebas', file.path));
                            }

                            final streamed = await request.send();
                            final body = await streamed.stream.bytesToString();
                            final data = jsonDecode(body);
                            if (!context.mounted) return;
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(data['ok'] == true
                                  ? 'Apelación enviada correctamente ✓'
                                  : (data['mensaje'] ?? 'Error al enviar')),
                              backgroundColor:
                                  data['ok'] == true ? _verde : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12))),
                            ));
                          } catch (_) {
                            if (!context.mounted) return;
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Error de conexión'),
                              backgroundColor: Colors.red,
                            ));
                          } finally {
                            setSheet(() => enviando = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Enviar Apelación',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = _getEstado();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: inmueble.imagenes.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: inmueble.imagenes.first.url,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 90, height: 90, color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Icon(Icons.home_outlined,
                              color: Colors.grey)),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12)),
                      child:
                          const Icon(Icons.home_outlined, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(inmueble.titulo,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(inmueble.zona,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[400]),
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Bs. ${_formatearMiles(inmueble.precio)}/mes',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _verdeOscuro)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: estado.bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: estado.color.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(estado.icon, size: 10, color: estado.color),
                            const SizedBox(width: 3),
                            Text(estado.label,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: estado.color)),
                          ]),
                        ),
                      ]),
                ])),
            if (!inmueble.enApelacion)
              PopupMenuButton<String>(
                iconSize: 20,
                icon: const Icon(Icons.more_vert,
                    color: Color(0xFF9CA3AF), size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                onSelected: (v) => _manejarAccion(context, v, estado),
                itemBuilder: (_) => _buildMenuItems(estado),
              ),
          ]),
          if ((estado.label == 'Rechazado' || estado.label == 'Inactivo') &&
              inmueble.motivoRechazo != null &&
              inmueble.motivoRechazo!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _rojo.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.block, size: 13, color: _rojo),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Publicación dada de baja por la administración',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _rojo),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(inmueble.motivoRechazo!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7F1D1D), height: 1.4)),
                ],
              ),
            ),
            if (!_esConductual) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _irAEditar(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gris,
                    side: BorderSide(color: _gris.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Editar publicación',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Builder(builder: (context) {
              final yaApelo = inmueble.enApelacion;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: yaApelo ? null : () => _mostrarApelacion(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: yaApelo ? const Color(0xFF3B82F6) : _rojo,
                    side: BorderSide(
                        color: yaApelo
                            ? const Color(0xFF3B82F6).withOpacity(0.4)
                            : _rojo.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  icon: Icon(
                      yaApelo ? Icons.hourglass_top_outlined : Icons.balance,
                      size: 15),
                  label: Text(
                      yaApelo ? '⏳ Apelación en revisión' : 'Apelar decisión',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              );
            }),
          ],
        ]),
      ),
    );
  }
}

class _EstadoData {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _EstadoData(this.label, this.color, this.bgColor, this.icon);
}

class _ProximamenteTab extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descripcion;

  const _ProximamenteTab(
      {required this.icon, required this.titulo, required this.descripcion});

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

class _SolicitudesTab extends StatefulWidget {
  const _SolicitudesTab();

  @override
  State<_SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<_SolicitudesTab> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  List<dynamic> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/solicitudes/mis-solicitudes'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        setState(() => _solicitudes = data['datos'] as List);
      }
    } catch (_) {}
    setState(() => _cargando = false);
  }

  Future<void> _contactarEstudiante(String telefono, String nombre) async {
    final mensaje = Uri.encodeComponent(
      '¡Hola $nombre! Vi que estás interesado/a en mi publicación en UniHab. ¿En qué puedo ayudarte?',
    );
    final url = Uri.parse('https://wa.me/$telefono?text=$mensaje');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _llamarAtendida(AuthProvider auth, int id, String estado) async {
    try {
      final res = await http.patch(
        Uri.parse('${Constantes.baseUrl}/solicitudes/$id/atendida'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estado': estado}),
      );
      final data = jsonDecode(res.body);
      return data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _manejarAccionSolicitud(
      dynamic s, int index, String accion) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final id = s['id'] as int;
    final estado = accion == 'atender' ? 'ATENDIDA' : 'RECHAZADA';

    final exito = await _llamarAtendida(auth, id, estado);

    if (!mounted) return;

    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al procesar. Intentá de nuevo.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _solicitudes.removeWhere((sol) => sol['id'] == id));

    final msg =
        accion == 'atender' ? 'Solicitud atendida ✓' : 'Solicitud rechazada';
    final color = accion == 'atender' ? _verde : _rojo;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _verde));
    }

    return RefreshIndicator(
      color: _verde,
      onRefresh: _cargar,
      child: _solicitudes.isEmpty
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 100),
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.contact_mail_outlined,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aún no hay interesados',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Text('Cuando alguien contacte tus inmuebles\naparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ]),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _solicitudes.length,
              itemBuilder: (_, i) => _buildCard(_solicitudes[i], i),
            ),
    );
  }

  Widget _buildCard(dynamic s, int index) {
    final arrendatario = s['arrendatario'] as Map<String, dynamic>;
    final inmueble = s['inmueble'] as Map<String, dynamic>;
    final nombre = arrendatario['nombre'] as String? ?? 'Estudiante';
    final email = arrendatario['email'] as String? ?? '';
    final telefono = (arrendatario['telefono'] ?? '').toString().trim();
    final fotoPerfil = arrendatario['fotoPerfil'] as String?;
    final tituloInm = inmueble['titulo'] as String? ?? '';
    final zona = inmueble['zona'] as String? ?? '';
    final fecha = DateTime.tryParse(s['creadoEn'] ?? '');
    final fechaStr =
        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PerfilEstudianteScreen(estudiante: arrendatario),
                    )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _verdeClaro,
                      backgroundImage:
                          (fotoPerfil != null && fotoPerfil.isNotEmpty)
                              ? NetworkImage(fotoPerfil)
                              : null,
                      child: (fotoPerfil == null || fotoPerfil.isEmpty)
                          ? Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: _verdeOscuro,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(
                                child: Text(nombre,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _textoOscuro))),
                            const Icon(Icons.chevron_right,
                                size: 16, color: _gris),
                          ]),
                          Text(email,
                              style:
                                  const TextStyle(fontSize: 11, color: _gris)),
                        ])),
                  ]),
                ),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (fechaStr.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _grisClaro,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(fechaStr,
                      style: const TextStyle(fontSize: 10, color: _gris)),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _gris, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.white,
                onSelected: (accion) =>
                    _manejarAccionSolicitud(s, index, accion),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'atender',
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 10),
                      const Text('Marcar como atendido',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'rechazar',
                    child: Row(children: [
                      const Icon(Icons.cancel_outlined,
                          color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 10),
                      const Text('Rechazar solicitud',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ]),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 10),
          if (s['esConjunta'] == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _verde.withOpacity(0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.people_alt_outlined,
                          size: 14, color: _verdeOscuro),
                      SizedBox(width: 6),
                      Text('Solicitud conjunta',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _verdeOscuro)),
                    ]),
                    const SizedBox(height: 6),
                    ...((s['companeros'] as List?) ?? []).map((c) {
                      final n = c['nombre'] as String? ?? '';
                      final f = c['fotoPerfil'] as String?;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PerfilEstudianteScreen(
                                    estudiante:
                                        Map<String, dynamic>.from(c as Map)),
                              )),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              backgroundImage: (f != null && f.isNotEmpty)
                                  ? NetworkImage(f)
                                  : null,
                              child: (f == null || f.isEmpty)
                                  ? Text(
                                      n.isNotEmpty ? n[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: _verdeOscuro,
                                          fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Junto a $n',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _verdeOscuro,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 14, color: _verdeOscuro),
                          ]),
                        ),
                      );
                    }),
                  ]),
            ),
          ],
          Row(children: [
            const Icon(Icons.home_work_outlined, size: 14, color: _gris),
            const SizedBox(width: 6),
            Expanded(
                child: Text('Interesado en: $tituloInm',
                    style: const TextStyle(fontSize: 12, color: _textoOscuro),
                    overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: _gris),
            const SizedBox(width: 6),
            Text(zona, style: const TextStyle(fontSize: 12, color: _gris)),
          ]),
          if (telefono.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _contactarEstudiante(telefono, nombre),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_outlined,
                    color: Colors.white, size: 16),
                label: const Text('Responder por WhatsApp',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: _grisClaro, borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.info_outline, size: 12, color: _gris),
                SizedBox(width: 4),
                Text('Sin teléfono registrado',
                    style: TextStyle(fontSize: 11, color: _gris)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
