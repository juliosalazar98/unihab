import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constantes.dart';
import '../../../../models/perfilConvivencia.dart';
import '../../../../models/roommateMatch.dart';
import '../../../../providers/authProvider.dart';
import 'detalleRoommateSheet.dart';
import 'testConvivenciaScreen.dart';

class ConvivenciaTab extends StatefulWidget {
  const ConvivenciaTab({super.key});
  @override
  State<ConvivenciaTab> createState() => ConvivenciaTabState();
}

class ConvivenciaTabState extends State<ConvivenciaTab> {
  static const _roommate = Color.fromARGB(255, 120, 122, 121);
  static const _verde = Color(0xFF10B981);

  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  PerfilConvivencia? _miPerfil;
  List<RoommateMatch> _matches = [];
  List<RoommateMatch> _solicitudesRecibidas = [];
  List<RoommateMatch> _conexiones = [];
  bool _verTodasConexiones = false;
  bool _cargando = true;
  bool _cargandoMatches = false;
  bool _switchActivo = false;
  bool _cargandoVisibilidad = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  /// Permite que la pantalla contenedora recargue esta pestaña,
  /// por ejemplo cuando el usuario llega desde una notificación.
  Future<void> recargar() => _cargarPerfil();

  Future<void> _cargarPerfil() async {
    if (mounted) setState(() => _cargando = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/convivencia/mi-perfil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && data['datos'] != null) {
        _miPerfil = PerfilConvivencia.fromJson(data['datos']);
        _switchActivo = true;
        await Future.wait([
          _cargarMatches(),
          _cargarSolicitudesRecibidas(),
          _cargarConexiones(),
        ]);
      } else {
        // Sin perfil propio igual puede recibir solicitudes directas.
        _miPerfil = null;
        await _cargarSolicitudesRecibidas();
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarMatches() async {
    if (mounted) setState(() => _cargandoMatches = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/convivencia/match'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _matches = (data['datos'] as List)
            .map((e) => RoommateMatch.fromJson(e))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoMatches = false);
  }

  Future<void> _cargarSolicitudesRecibidas() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse(
            '${Constantes.baseUrl}/convivencia/match/solicitudes-recibidas'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('SOLICITUDES >>> ${res.statusCode} ${res.body}');
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _solicitudesRecibidas = (data['datos'] as List).map((e) {
          final enriched = Map<String, dynamic>.from(e as Map<String, dynamic>);
          enriched['estadoMatch'] = 'PENDIENTE';
          enriched['soyElSolicitante'] = false;
          return RoommateMatch.fromJson(enriched);
        }).toList();
        print('SOLICITUDES PARSEADAS >>> ${_solicitudesRecibidas.length}');
      }
    } catch (e) {
      print('SOLICITUDES ERROR >>> $e');
    }
  }

  Future<void> _cargarConexiones() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/convivencia/match/conexiones'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _conexiones = (data['datos'] as List)
            .map((e) => RoommateMatch.fromJson(e))
            .toList();
      }
    } catch (_) {}
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<Map<String, dynamic>> _enviarConexionDirecta(String email) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/convivencia/match/directo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);
      return {
        'ok': data['ok'] == true,
        'mensaje':
            (data['mensaje'] ?? 'No se pudo enviar la solicitud') as String,
      };
    } catch (_) {
      return {'ok': false, 'mensaje': 'Sin conexión con el servidor'};
    }
  }

  Future<void> _dialogoConexionDirecta() async {
    final ctrl = TextEditingController();
    bool enviando = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> enviar() async {
            final email = ctrl.text.trim();
            if (!email.contains('@') || !email.contains('.')) {
              _toast('Escribí un correo válido', Colors.orange);
              return;
            }
            setLocal(() => enviando = true);
            final r = await _enviarConexionDirecta(email);
            if (!mounted) return;
            setLocal(() => enviando = false);
            if (r['ok'] == true) {
              Navigator.pop(ctx);
              _toast(r['mensaje'] as String, _verde);
              await _silentReloadMatches();
            } else {
              _toast(r['mensaje'] as String, Colors.redAccent);
            }
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Conectar con alguien que ya conozco',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'Escribe el correo con el que tu amigo se registró en UniHab. '
                'Le va a llegar una solicitud de conexión.',
                style: TextStyle(fontSize: 13, color: _gris, height: 1.45),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !enviando,
                decoration: InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  prefixIcon: const Icon(Icons.alternate_email, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                onPressed: enviando ? null : enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar solicitud',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConexionDirectaCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _dialogoConexionDirecta,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  color: _verdeClaro, shape: BoxShape.circle),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  size: 19, color: _verdeOscuro),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Ya tienes roommate?',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textoOscuro)),
                  SizedBox(height: 2),
                  Text('Conectá por correo sin pasar por el test',
                      style: TextStyle(fontSize: 11, color: _gris)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _gris),
          ]),
        ),
      ),
    );
  }

  Future<void> _silentReloadMatches() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/convivencia/match'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        _matches = (data['datos'] as List)
            .map((e) => RoommateMatch.fromJson(e))
            .toList();
      }
      await _cargarConexiones();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleVisibilidad(bool nuevoValor) async {
    setState(() => _cargandoVisibilidad = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.patch(
        Uri.parse('${Constantes.baseUrl}/convivencia/perfil/visibilidad'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'activo': nuevoValor}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _miPerfil = PerfilConvivencia.fromJson(data['datos']);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoVisibilidad = false);
  }

  Future<void> _responderSolicitud(
      RoommateMatch solicitud, String accion) async {
    if (solicitud.matchId == null) return;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.patch(
        Uri.parse(
            '${Constantes.baseUrl}/convivencia/match/${solicitud.matchId}/responder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'accion': accion}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _solicitudesRecibidas
              .removeWhere((s) => s.matchId == solicitud.matchId);
        });
        await _silentReloadMatches();
      }
    } catch (_) {}
  }

  Future<void> _finalizarConexion(RoommateMatch m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finalizar conexión',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        content: Text(
          'Vas a finalizar tu conexión con ${m.nombre}. Se le avisará y dejarán '
          'de verse en la lista de conexiones. Podrán volver a conectar más '
          'adelante si ambos quieren.',
          style: const TextStyle(fontSize: 13, color: _gris, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Finalizar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmado != true || m.matchId == null || !mounted) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.delete(
        Uri.parse(
            '${Constantes.baseUrl}/convivencia/match/${m.matchId}/conexion'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['ok'] == true) {
        _toast('Conexión finalizada', _verde);
        await _silentReloadMatches();
      } else {
        _toast((data['mensaje'] ?? 'No se pudo finalizar') as String,
            Colors.redAccent);
      }
    } catch (_) {
      _toast('Sin conexión con el servidor', Colors.redAccent);
    }
  }

  List<RoommateMatch> get _compatibles =>
      _matches.where((m) => m.estadoMatch != 'ACEPTADO').toList();

  Future<void> _abrirWhatsApp(RoommateMatch m) async {
    if (m.telefono == null || m.telefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este estudiante aún no registró su teléfono'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
      return;
    }
    final num = m.telefono!.replaceAll('+', '').replaceAll(' ', '');
    final msg =
        Uri.encodeComponent('¡Hola ${m.nombre}! Te escribo desde UniHab 🏠');
    final url = Uri.parse('https://wa.me/$num?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _irAlTest() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TestConvivenciaScreen()),
    );
    if (ok == true && mounted) await _cargarPerfil();
  }

  void _mostrarDetalle(RoommateMatch match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleRoommateSheet(match: match),
    ).then((_) {
      if (mounted) _silentReloadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _verde));
    }

    return RefreshIndicator(
      color: _verde,
      onRefresh: _cargarPerfil,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_miPerfil == null) ...[
            if (_solicitudesRecibidas.isNotEmpty)
              SliverToBoxAdapter(child: _buildSolicitudesSection()),
            SliverToBoxAdapter(child: _buildInvitacion()),
          ] else ...[
            if (_miPerfil!.activo)
              SliverToBoxAdapter(child: _buildVisibilidadCard()),
            if (!_miPerfil!.activo) ...[
              if (_solicitudesRecibidas.isNotEmpty)
                SliverToBoxAdapter(child: _buildSolicitudesSection()),
              SliverToBoxAdapter(child: _buildPerfilOculto()),
              SliverToBoxAdapter(child: _buildConexionDirectaCard()),
            ] else ...[
              if (_solicitudesRecibidas.isNotEmpty)
                SliverToBoxAdapter(child: _buildSolicitudesSection()),
              if (!_cargandoMatches && _conexiones.isNotEmpty)
                SliverToBoxAdapter(child: _buildConexionesSection()),
              SliverToBoxAdapter(child: _buildConexionDirectaCard()),
              SliverToBoxAdapter(child: _buildSubtitulo()),
              if (_cargandoMatches)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child:
                        Center(child: CircularProgressIndicator(color: _verde)),
                  ),
                )
              else if (_compatibles.isEmpty)
                SliverToBoxAdapter(child: _buildSinMatches())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RoommateCard(
                      match: _compatibles[i],
                      onVerPerfil: () => _mostrarDetalle(_compatibles[i]),
                    ),
                    childCount: _compatibles.length,
                  ),
                ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: _verdeClaro, borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_alt_outlined, size: 13, color: _verdeOscuro),
            SizedBox(width: 4),
            Text('Convivencia',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _verdeOscuro)),
          ]),
        ),
        const SizedBox(height: 10),
        const Text('Encontrá tu\nRoommate ideal',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _textoOscuro,
                height: 1.2)),
        const SizedBox(height: 6),
        const Text(
            'Conectá con estudiantes compatibles\ncon tu estilo de vida.',
            style: TextStyle(fontSize: 14, color: _gris, height: 1.4)),
      ]),
    );
  }

  Widget _buildPerfilOculto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: _verdeClaro,
            shape: BoxShape.circle,
            border: Border.all(color: _verde.withOpacity(0.25), width: 2),
          ),
          child:
              const Icon(Icons.visibility_off_rounded, size: 50, color: _verde),
        ),
        const SizedBox(height: 28),
        const Text(
          'Tu perfil de convivencia\nestá oculto',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textoOscuro,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Para poder explorar y conectar con otros roommates compatibles, debes activar tu perfil y permitir que la comunidad también te conozca.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: _gris, height: 1.65),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed:
              _cargandoVisibilidad ? null : () => _toggleVisibilidad(true),
          icon: _cargandoVisibilidad
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Activar mi perfil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _verde,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ]),
    );
  }

  Widget _buildVisibilidadCard() {
    final esActivo = _miPerfil!.activo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: esActivo ? _verdeClaro : _grisClaro,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                esActivo ? _verde.withOpacity(0.35) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: esActivo ? _verde.withOpacity(0.15) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              esActivo
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: esActivo ? _verdeOscuro : _gris,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esActivo ? 'Buscando Roommate' : 'Ya encontré Roommate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: esActivo ? _verdeOscuro : _textoOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  esActivo
                      ? 'Visible en la comunidad'
                      : 'Tu perfil está oculto',
                  style: TextStyle(
                    fontSize: 11,
                    color: esActivo ? _verde : _gris,
                  ),
                ),
              ],
            ),
          ),
          if (_cargandoVisibilidad)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _verde),
            )
          else
            Switch(
              value: esActivo,
              activeColor: _verde,
              onChanged: _toggleVisibilidad,
            ),
        ]),
      ),
    );
  }

  Widget _buildSolicitudesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFF59E0B), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${_solicitudesRecibidas.length} solicitud${_solicitudesRecibidas.length == 1 ? '' : 'es'} recibida${_solicitudesRecibidas.length == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _textoOscuro),
          ),
        ]),
      ),
      ..._solicitudesRecibidas.map((s) => _SolicitudCard(
            solicitud: s,
            mostrarAfinidad: _miPerfil != null,
            onAceptar: () => _responderSolicitud(s, 'ACEPTAR'),
            onRechazar: () => _responderSolicitud(s, 'RECHAZAR'),
            onVerPerfil: () => _mostrarDetalle(s),
          )),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Divider(color: Color(0xFFE5E7EB)),
      ),
    ]);
  }

  Widget _buildConexionesSection() {
    const limite = 3;
    final mostrar =
        _verTodasConexiones ? _conexiones : _conexiones.take(limite).toList();
    final ocultas = _conexiones.length - mostrar.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(children: [
          const Icon(Icons.handshake_outlined, size: 16, color: _verdeOscuro),
          const SizedBox(width: 8),
          Text(
            _conexiones.length == 1
                ? 'Mi conexión'
                : 'Mis ${_conexiones.length} conexiones',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _textoOscuro),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: mostrar.map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              decoration: BoxDecoration(
                color: _verdeClaro,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _verde.withOpacity(0.3)),
              ),
              child: Row(children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _mostrarDetalle(m),
                    child: Row(children: [
                      RoommateAvatar(
                          nombre: m.nombre, fotoPerfil: m.fotoPerfil, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nombre,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _textoOscuro),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              Text('${m.afinidad}% compatible',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _verdeOscuro,
                                      fontWeight: FontWeight.w600)),
                              if (m.institucion != null) ...[
                                const Text('  ·  ',
                                    style:
                                        TextStyle(fontSize: 11, color: _gris)),
                                Flexible(
                                  child: Text(m.institucion!,
                                      style: const TextStyle(
                                          fontSize: 11, color: _gris),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _abrirWhatsApp(m),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 18),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: _gris),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'finalizar') _finalizarConexion(m);
                    if (v == 'perfil') _mostrarDetalle(m);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'perfil',
                      child: Row(children: [
                        Icon(Icons.person_outline, size: 16, color: _gris),
                        SizedBox(width: 10),
                        Text('Ver perfil', style: TextStyle(fontSize: 13)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'finalizar',
                      child: Row(children: [
                        Icon(Icons.link_off, size: 16, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Finalizar conexión',
                            style: TextStyle(
                                fontSize: 13, color: Colors.redAccent)),
                      ]),
                    ),
                  ],
                ),
              ]),
            );
          }).toList(),
        ),
      ),
      if (_conexiones.length > limite)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                setState(() => _verTodasConexiones = !_verTodasConexiones),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Text(
                  _verTodasConexiones
                      ? 'Ver menos'
                      : 'Ver las $ocultas restantes',
                  style: const TextStyle(
                      fontSize: 13,
                      color: _verdeOscuro,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(
                  _verTodasConexiones
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _verdeOscuro,
                ),
              ]),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Divider(color: Color(0xFFE5E7EB)),
      ),
    ]);
  }

  Widget _buildInvitacion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: _verdeClaro, borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            const Icon(Icons.people_alt_rounded, size: 72, color: _verde),
            const SizedBox(height: 16),
            const Text('¿Buscás roommate?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
            const SizedBox(height: 8),
            Text(
                'Hacé el test de convivencia (2 min)\ny te mostramos estudiantes\ncompatibles con tu estilo de vida.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _gris, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: const Text('Busco compartir vivienda',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _textoOscuro)),
            subtitle: const Text('Activá para encontrar roommates compatibles',
                style: TextStyle(fontSize: 12)),
            value: _switchActivo,
            activeColor: _verde,
            onChanged: (v) {
              setState(() => _switchActivo = v);
              if (v) _irAlTest();
            },
          ),
        ),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(Icons.verified_outlined, 'Match por hábitos'),
          _chip(Icons.school_outlined, 'Solo estudiantes'),
          _chip(Icons.lock_outline, '100% Voluntario'),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: _grisClaro, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _verdeOscuro),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textoOscuro)),
      ]),
    );
  }

  Widget _buildSubtitulo() {
    final esActivo = _miPerfil?.activo ?? true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
                '${_compatibles.length} estudiante${_compatibles.length == 1 ? '' : 's'} disponible${_compatibles.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
          ),
          TextButton.icon(
            onPressed: _irAlTest,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Editar test'),
            style: TextButton.styleFrom(foregroundColor: _verde),
          ),
        ]),
        if (!esActivo)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Activá tu perfil para que otros estudiantes te puedan ver',
              style: TextStyle(fontSize: 11, color: _gris.withOpacity(0.8)),
            ),
          ),
      ]),
    );
  }

  Widget _buildSinMatches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(children: [
        const Icon(Icons.search_off_rounded, size: 64, color: _gris),
        const SizedBox(height: 16),
        const Text('Sin matches por ahora',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 8),
        Text(
            'Todavía no hay otros estudiantes con perfil activo. Si ya tenés roommate, podés conectarlo por su correo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _gris, height: 1.5)),
      ]),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final RoommateMatch solicitud;
  final bool mostrarAfinidad;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final VoidCallback onVerPerfil;

  const _SolicitudCard({
    required this.solicitud,
    this.mostrarAfinidad = true,
    required this.onAceptar,
    required this.onRechazar,
    required this.onVerPerfil,
  });

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            RoommateAvatar(
                nombre: solicitud.nombre,
                fotoPerfil: solicitud.fotoPerfil,
                size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(solicitud.nombre,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textoOscuro)),
                  if (solicitud.institucion != null)
                    Text(solicitud.institucion!,
                        style: const TextStyle(fontSize: 12, color: _gris)),
                ],
              ),
            ),
            if (mostrarAfinidad)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _verde.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${solicitud.afinidad}%',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _verdeOscuro)),
                  const Text('Match',
                      style: TextStyle(fontSize: 9, color: _verde)),
                ]),
              ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRechazar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.black26),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rechazar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onAceptar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Aceptar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onVerPerfil,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 13, color: _verde),
                SizedBox(width: 4),
                Text('Ver perfil completo',
                    style: TextStyle(
                        fontSize: 12,
                        color: _verde,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoommateCard extends StatelessWidget {
  final RoommateMatch match;
  final VoidCallback onVerPerfil;

  const _RoommateCard({required this.match, required this.onVerPerfil});

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  Widget? _buildEstadoBadge() {
    if (match.estadoMatch == 'ACEPTADO') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: _verde.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: const Text('Conectados 🤝',
            style: TextStyle(
                fontSize: 10,
                color: _verdeOscuro,
                fontWeight: FontWeight.w600)),
      );
    }
    if (match.estadoMatch == 'PENDIENTE' && match.soyElSolicitante == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: _grisClaro, borderRadius: BorderRadius.circular(10)),
        child: const Text('⏳ Enviada',
            style: TextStyle(
                fontSize: 10, color: _gris, fontWeight: FontWeight.w600)),
      );
    }
    if (match.estadoMatch == 'PENDIENTE' && match.soyElSolicitante == false) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5))),
        child: const Text('📩 Te escribió',
            style: TextStyle(
                fontSize: 10,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600)),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estadoBadge = _buildEstadoBadge();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RoommateAvatar(
                  nombre: match.nombre, fotoPerfil: match.fotoPerfil, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(match.nombre,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textoOscuro)),
                      ),
                      if (estadoBadge != null) estadoBadge,
                    ]),
                    if (match.institucion != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.school_outlined,
                            size: 12, color: _gris),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(match.institucion!,
                                style:
                                    const TextStyle(fontSize: 12, color: _gris),
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Text(match.descripcionSobreMi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: _gris, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Builder(builder: (_) {
                final a = match.afinidad;
                final c = a >= 80
                    ? const Color(0xFF059669)
                    : a >= 60
                        ? const Color(0xFFD97706)
                        : const Color(0xFF6B7280);
                final etiqueta = a >= 80
                    ? 'Alta'
                    : a >= 60
                        ? 'Media'
                        : 'Baja';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.withOpacity(0.35))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$a%',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: c)),
                    Text(etiqueta,
                        style: TextStyle(
                            fontSize: 9,
                            color: c,
                            fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              if (match.zonasEnComun.isNotEmpty)
                _chipDestacado(
                  match.zonasEnComun.length == 1
                      ? match.zonasEnComun.first
                      : '${match.zonasEnComun.first} +${match.zonasEnComun.length - 1}',
                  Icons.place_outlined,
                ),
              if (match.tienePresupuesto)
                _habitoChip(match.presupuestoTexto,
                    Icons.account_balance_wallet_outlined),
              _habitoChip(_labelCronotipo(match.perfil['cronotipo'] ?? ''),
                  Icons.wb_sunny_outlined),
              _habitoChip(_labelOrden(match.perfil['nivelOrden'] ?? ''),
                  Icons.cleaning_services_outlined),
              _habitoChip(_labelVisitas(match.perfil['politicaVisitas'] ?? ''),
                  Icons.door_front_door_outlined),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _verde,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Ver Perfil de Convivencia',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chipDestacado(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _verde.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: _verdeOscuro),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: _verdeOscuro,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _habitoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: _grisClaro, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: _gris),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _textoOscuro)),
      ]),
    );
  }

  String _labelCronotipo(String v) =>
      v == 'DIURNO' ? 'Diurno ☀️' : 'Nocturno 🌙';
  String _labelOrden(String v) =>
      v == 'RIGUROSO' ? 'Ordenado 🧹' : 'Relajado 😌';
  String _labelVisitas(String v) {
    switch (v) {
      case 'FRECUENTE':
        return 'Visitas frecuentes';
      case 'MODERADO':
        return 'Visitas moderadas';
      case 'RESTRINGIDO':
        return 'Pocas visitas';
      default:
        return v;
    }
  }
}

class RoommateAvatar extends StatelessWidget {
  final String nombre;
  final String? fotoPerfil;
  final double size;

  const RoommateAvatar({
    super.key,
    required this.nombre,
    this.fotoPerfil,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoPerfil != null && fotoPerfil!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(fotoPerfil!),
        backgroundColor: const Color(0xFFECFDF5),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFECFDF5),
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF059669),
        ),
      ),
    );
  }
}
