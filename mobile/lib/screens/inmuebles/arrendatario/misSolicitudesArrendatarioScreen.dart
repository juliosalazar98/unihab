import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/config/constantes.dart';
import '/providers/authProvider.dart';

class MisSolicitudesArrendatarioScreen extends StatefulWidget {
  const MisSolicitudesArrendatarioScreen({super.key});

  @override
  State<MisSolicitudesArrendatarioScreen> createState() =>
      _MisSolicitudesArrendatarioScreenState();
}

class _MisSolicitudesArrendatarioScreenState
    extends State<MisSolicitudesArrendatarioScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _rojo = Color(0xFFEF4444);

  List<dynamic> _solicitudes = [];
  List<dynamic> _invitaciones = [];
  bool _cargando = true;
  int? _respondiendo;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final headers = {'Authorization': 'Bearer ${auth.token}'};

      final resultados = await Future.wait([
        http.get(
            Uri.parse('${Constantes.baseUrl}/solicitudes/mis-postulaciones'),
            headers: headers),
        http.get(
            Uri.parse(
                '${Constantes.baseUrl}/notificaciones/co-solicitud/pendientes'),
            headers: headers),
      ]);

      final dataSol = jsonDecode(resultados[0].body);
      final dataInv = jsonDecode(resultados[1].body);

      if (mounted) {
        setState(() {
          if (dataSol['ok'] == true) _solicitudes = dataSol['datos'] as List;
          if (dataInv['ok'] == true) _invitaciones = dataInv['datos'] as List;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _responderInvitacion(int id, String accion) async {
    setState(() => _respondiendo = id);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.patch(
        Uri.parse(
            '${Constantes.baseUrl}/notificaciones/co-solicitud/$id/responder'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'accion': accion}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(accion == 'ACEPTAR'
              ? 'Solicitud conjunta enviada al propietario ✓'
              : 'Invitación rechazada'),
          backgroundColor: accion == 'ACEPTAR' ? _verde : _gris,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
        await _cargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['mensaje'] ?? 'Error al responder'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error de conexión'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _respondiendo = null);
  }

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Map<String, dynamic> _estadoData(dynamic s) {
    final inmueble = s['inmueble'] as Map<String, dynamic>;
    final aprobado = inmueble['aprobado'] as bool? ?? false;
    final disponible = inmueble['disponible'] as bool? ?? false;
    final estado = s['estado'] as String? ?? 'PENDIENTE';

    if (!aprobado && !disponible) {
      return {
        'label': 'Rechazado',
        'color': _rojo,
        'bg': const Color(0xFFFEF2F2)
      };
    }
    if (!aprobado && disponible) {
      return {
        'label': 'En revisión',
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB)
      };
    }
    if (estado == 'ATENDIDA') {
      return {'label': 'Atendida', 'color': _verde, 'bg': _verdeClaro};
    }
    if (estado == 'RECHAZADA') {
      return {
        'label': 'Rechazada',
        'color': _rojo,
        'bg': const Color(0xFFFEF2F2)
      };
    }
    return {
      'label': 'Enviada',
      'color': const Color(0xFF3B82F6),
      'bg': const Color(0xFFEFF6FF)
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _grisClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        title: const Text('Mis Solicitudes',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _verde))
          : (_solicitudes.isEmpty && _invitaciones.isEmpty)
              ? _buildVacio()
              : RefreshIndicator(
                  color: _verde,
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_invitaciones.isNotEmpty) ...[
                        Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _invitaciones.length == 1
                                ? '1 invitación para postular juntos'
                                : '${_invitaciones.length} invitaciones para postular juntos',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textoOscuro),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ..._invitaciones.map(_buildInvitacion),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      if (_solicitudes.isNotEmpty) ...[
                        const Text('Mis postulaciones',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textoOscuro)),
                        const SizedBox(height: 12),
                        ..._solicitudes.map(_buildCard),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInvitacion(dynamic inv) {
    final id = inv['id'] as int;
    final remitente = inv['remitente'] as Map<String, dynamic>;
    final inmueble = inv['inmueble'] as Map<String, dynamic>;
    final nombre = remitente['nombre'] as String? ?? '';
    final foto = remitente['fotoPerfil'] as String?;
    final titulo = inmueble['titulo'] as String? ?? '';
    final zona = inmueble['zona'] as String? ?? '';
    final precio = (inmueble['precio'] as num?)?.toDouble() ?? 0;
    final cargando = _respondiendo == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _verdeClaro,
            backgroundImage:
                (foto != null && foto.isNotEmpty) ? NetworkImage(foto) : null,
            child: (foto == null || foto.isEmpty)
                ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: _verdeOscuro, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: _textoOscuro),
                children: [
                  TextSpan(
                      text: nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' te invitó a postular juntos'),
                ],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: _gris),
              const SizedBox(width: 3),
              Text(zona, style: const TextStyle(fontSize: 11, color: _gris)),
              const Spacer(),
              Text('Bs. ${_formatearMiles(precio)}/mes',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _verdeOscuro)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  cargando ? null : () => _responderInvitacion(id, 'RECHAZAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black54,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rechazar',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  cargando ? null : () => _responderInvitacion(id, 'ACEPTAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verde,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: cargando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Aceptar',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildCard(dynamic s) {
    final inmueble = s['inmueble'] as Map<String, dynamic>;
    final titulo = inmueble['titulo'] as String? ?? '';
    final zona = inmueble['zona'] as String? ?? '';
    final precio = (inmueble['precio'] as num?)?.toDouble() ?? 0;
    final propietario = inmueble['propietario'] as Map<String, dynamic>?;
    final propNombre = propietario?['nombre'] as String? ?? '';
    final imagenes = inmueble['imagenes'] as List?;
    final imgUrl = imagenes != null && imagenes.isNotEmpty
        ? imagenes.first['url'] as String?
        : null;
    final fecha = DateTime.tryParse(s['creadoEn'] ?? '');
    final fechaStr =
        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';
    final estado = _estadoData(s);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imgUrl != null
                ? Image.network(
                    imgUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: _grisClaro,
                      child: const Icon(Icons.home_outlined, color: _gris),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            width: 70,
                            height: 70,
                            color: _grisClaro,
                          ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: _grisClaro,
                    child: const Icon(Icons.home_outlined, color: _gris)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(titulo,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textoOscuro),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estado['bg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: (estado['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Text(estado['label'] as String,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: estado['color'] as Color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: _gris),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Text(zona,
                          style: const TextStyle(fontSize: 11, color: _gris),
                          overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 12, color: _gris),
                  const SizedBox(width: 3),
                  Expanded(
                      child: Text(propNombre,
                          style: const TextStyle(fontSize: 11, color: _gris),
                          overflow: TextOverflow.ellipsis)),
                ]),
                if (s['esConjunta'] == true) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _verdeClaro,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _verde.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline,
                          size: 12, color: _verdeOscuro),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          (s['companeros'] as List?)?.isNotEmpty == true
                              ? 'Junto a ${(s['companeros'] as List).map((c) => c['nombre']).join(', ')}'
                              : 'Solicitud conjunta',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _verdeOscuro),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bs. ${_formatearMiles(precio)}/mes',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _verdeOscuro)),
                    if (fechaStr.isNotEmpty)
                      Text(fechaStr,
                          style: const TextStyle(fontSize: 10, color: _gris)),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.send_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Sin solicitudes enviadas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Text('Cuando contactes a un propietario\naparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]),
    );
  }
}
