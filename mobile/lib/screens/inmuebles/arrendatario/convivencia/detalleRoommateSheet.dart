import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constantes.dart';
import '../../../../models/roommateMatch.dart';
import '../../../../providers/authProvider.dart';
import 'convivenciaTab.dart'; // RoommateAvatar

class DetalleRoommateSheet extends StatefulWidget {
  final RoommateMatch match;
  const DetalleRoommateSheet({super.key, required this.match});

  @override
  State<DetalleRoommateSheet> createState() => _DetalleRoommateSheetState();
}

class _DetalleRoommateSheetState extends State<DetalleRoommateSheet> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  late String? _estadoMatch;
  late int? _matchId;
  late bool? _soyElSolicitante;
  bool _cargandoAccion = false;

  @override
  void initState() {
    super.initState();
    _estadoMatch = widget.match.estadoMatch;
    _matchId = widget.match.matchId;
    _soyElSolicitante = widget.match.soyElSolicitante;
  }

  Future<void> _solicitarConexion() async {
    setState(() => _cargandoAccion = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.post(
        Uri.parse(
            '${Constantes.baseUrl}/convivencia/match/solicitar/${widget.match.usuarioId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _matchId = data['datos']['id'] as int;
          _estadoMatch = 'PENDIENTE';
          _soyElSolicitante = true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoAccion = false);
  }

  Future<void> _responderSolicitud(String accion) async {
    if (_matchId == null) return;
    setState(() => _cargandoAccion = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.patch(
        Uri.parse(
            '${Constantes.baseUrl}/convivencia/match/$_matchId/responder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'accion': accion}),
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          if (accion == 'ACEPTAR') {
            _estadoMatch = 'ACEPTADO';
          } else {
            _estadoMatch = null;
            _matchId = null;
            _soyElSolicitante = null;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoAccion = false);
  }

  Future<void> _cancelarSolicitud() async {
    if (_matchId == null) return;
    setState(() => _cargandoAccion = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.delete(
        Uri.parse('${Constantes.baseUrl}/convivencia/match/$_matchId/cancelar'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _estadoMatch = null;
          _matchId = null;
          _soyElSolicitante = null;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoAccion = false);
  }

  Future<void> _conectarWhatsApp() async {
    if (widget.match.telefono == null) return;
    final num = widget.match.telefono!.replaceAll('+', '').replaceAll(' ', '');
    final msg = Uri.encodeComponent(
        '¡Hola ${widget.match.nombre}! Te encontré en UniHab y creo que '
        'podríamos ser buenos roommates 🏠');
    final url = Uri.parse('https://wa.me/$num?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Widget _buildBotonAccion() {
    if (_estadoMatch == 'ACEPTADO') {
      return Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _verdeClaro,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _verde.withOpacity(0.3)),
          ),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 15, color: _verdeOscuro),
            SizedBox(width: 6),
            Text('¡Conexión aceptada! 🎉 Ahora pueden chatear',
                style: TextStyle(
                    fontSize: 12,
                    color: _verdeOscuro,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        if (widget.match.telefono != null)
          ElevatedButton.icon(
            onPressed: _conectarWhatsApp,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Chatear por WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          )
        else
          _buildSinTelefono(),
      ]);
    }
    if (_estadoMatch == 'PENDIENTE' && _soyElSolicitante == true) {
      return Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: _grisClaro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: _gris),
            ),
            SizedBox(width: 10),
            Text('Solicitud enviada, esperando respuesta...',
                style: TextStyle(
                    color: _gris, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _cargandoAccion ? null : _cancelarSolicitud,
          child: Text(
            _cargandoAccion ? 'Cancelando...' : 'Cancelar solicitud',
            style: TextStyle(
              fontSize: 12,
              color: _cargandoAccion ? _gris : _rojo,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]);
    }
    if (_estadoMatch == 'PENDIENTE' && _soyElSolicitante == false) {
      return Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.6)),
          ),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.notifications_active_outlined,
                size: 16, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Flexible(
              child: Text('¡Este estudiante quiere conectar contigo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cargandoAccion
                  ? null
                  : () => _responderSolicitud('RECHAZAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _rojo,
                side: BorderSide(color: _rojo.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Rechazar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _cargandoAccion ? null : () => _responderSolicitud('ACEPTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _cargandoAccion
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Aceptar',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ]);
    }
    return ElevatedButton.icon(
      onPressed: _cargandoAccion ? null : _solicitarConexion,
      icon: _cargandoAccion
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.person_add_outlined, size: 18),
      label: Text(
          _cargandoAccion ? 'Enviando solicitud...' : 'Solicitar Conexión',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSinTelefono() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _grisClaro, borderRadius: BorderRadius.circular(14)),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone_disabled_outlined, color: _gris, size: 16),
        SizedBox(width: 8),
        Text('Este estudiante aún no registró su teléfono',
            style: TextStyle(fontSize: 13, color: _gris)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Center(
              child: Column(children: [
                RoommateAvatar(
                    nombre: widget.match.nombre,
                    fotoPerfil: widget.match.fotoPerfil,
                    size: 80),
                const SizedBox(height: 14),
                Text(widget.match.nombre,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textoOscuro)),
                if (widget.match.institucion != null) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.school_outlined, size: 14, color: _gris),
                    const SizedBox(width: 4),
                    Text(widget.match.institucion!,
                        style: const TextStyle(fontSize: 13, color: _gris)),
                  ]),
                ],
                if (widget.match.carrera != null) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📖', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(widget.match.carrera!,
                        style: const TextStyle(fontSize: 13, color: _gris)),
                  ]),
                ],
                if (widget.match.ciudadOrigen != null ||
                    widget.match.genero != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (widget.match.ciudadOrigen != null)
                        _infoChip('📍 ${widget.match.ciudadOrigen!}'),
                      if (widget.match.genero != null)
                        _infoChip('👤 ${_labelGenero(widget.match.genero!)}'),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                      color: _verde.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _verde.withOpacity(0.3))),
                  child: Text('${widget.match.afinidad}% Compatible',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _verdeOscuro)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _grisClaro, borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOBRE MÍ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _gris,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Text(widget.match.descripcionSobreMi,
                        style: const TextStyle(
                            fontSize: 14, color: _textoOscuro, height: 1.55)),
                  ]),
            ),
            if (widget.match.zonasPreferidas.isNotEmpty ||
                widget.match.tienePresupuesto) ...[
              const SizedBox(height: 24),
              const Text('Búsqueda de vivienda',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textoOscuro)),
              const SizedBox(height: 12),
              if (widget.match.tienePresupuesto)
                _habitoRow(
                    '💰', 'Presupuesto mensual', widget.match.presupuestoTexto),
              if (widget.match.zonasPreferidas.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('📍', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 14),
                        const Text('Zonas que busca',
                            style: TextStyle(
                                fontSize: 11,
                                color: _gris,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.match.zonasPreferidas.map((z) {
                          final comun = widget.match.zonasEnComun.contains(z);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: comun ? _verdeClaro : _grisClaro,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: comun
                                      ? _verde.withOpacity(0.4)
                                      : Colors.transparent),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              if (comun) ...[
                                const Icon(Icons.check,
                                    size: 12, color: _verdeOscuro),
                                const SizedBox(width: 4),
                              ],
                              Text(z,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: comun ? _verdeOscuro : _textoOscuro,
                                    fontWeight: comun
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ]),
                          );
                        }).toList(),
                      ),
                      if (widget.match.zonasEnComun.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.match.zonasEnComun.length == 1
                              ? 'Coinciden en 1 zona'
                              : 'Coinciden en ${widget.match.zonasEnComun.length} zonas',
                          style: const TextStyle(
                              fontSize: 11,
                              color: _verdeOscuro,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 24),
            const Text('Hábitos de convivencia',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
            const SizedBox(height: 12),
            _habitoRow('🐾', 'Mascotas',
                _labelMascota(widget.match.perfil['aceptaMascotas'] ?? '')),
            _habitoRow('🚬', 'Tabaco',
                _labelTabaco(widget.match.perfil['fumaTabaco'] ?? '')),
            _habitoRow('⏰', 'Horario',
                _labelCronotipo(widget.match.perfil['cronotipo'] ?? '')),
            _habitoRow('📚', 'Estudio',
                _labelAmbiente(widget.match.perfil['ambienteEstudio'] ?? '')),
            _habitoRow('🚪', 'Visitas',
                _labelVisitas(widget.match.perfil['politicaVisitas'] ?? '')),
            _habitoRow('🧹', 'Orden',
                _labelOrden(widget.match.perfil['nivelOrden'] ?? '')),
            const SizedBox(height: 28),
            _buildBotonAccion(),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(texto,
          style: const TextStyle(fontSize: 12, color: _textoOscuro)),
    );
  }

  String _labelGenero(String v) {
    switch (v) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      case 'OTRO':
        return 'Otro';
      default:
        return v;
    }
  }

  Widget _habitoRow(String emoji, String categoria, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(categoria,
              style: const TextStyle(
                  fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  fontSize: 14,
                  color: _textoOscuro,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  String _labelMascota(String v) {
    switch (v) {
      case 'SI':
        return 'Tiene o planea tener mascotas';
      case 'NO_TOLERO':
        return 'No tolera vivir con mascotas';
      case 'INDIFERENTE':
        return 'No tiene, pero le es indiferente';
      default:
        return v;
    }
  }

  String _labelTabaco(String v) {
    switch (v) {
      case 'SI':
        return 'Fuma habitualmente';
      case 'NO_TOLERO':
        return 'No fuma y no tolera que se fume';
      case 'INDIFERENTE':
        return 'No fuma, pero le es indiferente';
      default:
        return v;
    }
  }

  String _labelCronotipo(String v) => v == 'DIURNO'
      ? 'Diurno ☀️  (mañana/tarde)'
      : 'Nocturno 🌙  (trasnochador)';

  String _labelAmbiente(String v) {
    switch (v) {
      case 'SILENCIO':
        return 'Silencio absoluto';
      case 'ACTIVO':
        return 'Ambiente activo (música/ruido)';
      default:
        return v;
    }
  }

  String _labelVisitas(String v) {
    switch (v) {
      case 'FRECUENTE':
        return 'Visitas frecuentes (vida social)';
      case 'MODERADO':
        return 'Visitas moderadas (programadas)';
      case 'RESTRINGIDO':
        return 'Restringido (solo descanso)';
      default:
        return v;
    }
  }

  String _labelOrden(String v) => v == 'RIGUROSO'
      ? 'Riguroso (todo en su lugar)'
      : 'Relajado (limpia cuando puede)';
}
