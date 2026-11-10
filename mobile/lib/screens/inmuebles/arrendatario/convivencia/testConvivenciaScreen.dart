import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config/constantes.dart';
import '../../../../providers/authProvider.dart';

class TestConvivenciaScreen extends StatefulWidget {
  const TestConvivenciaScreen({super.key});
  @override
  State<TestConvivenciaScreen> createState() => _TestConvivenciaScreenState();
}

class _TestConvivenciaScreenState extends State<TestConvivenciaScreen> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  final _pageCtrl = PageController();
  final _descCtrl = TextEditingController();
  int _paginaActual = 0;
  bool _guardando = false;
  String? _aceptaMascotas;
  String? _fumaTabaco;
  String? _cronotipo;
  String? _ambienteEstudio;
  String? _politicaVisitas;
  String? _nivelOrden;
  final Set<String> _zonas = {};
  RangeValues _presupuesto = const RangeValues(400, 1200);
  List<String> _zonasDisponibles = [];
  bool _cargandoZonas = true;

  static const int _totalPaginas = 9;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    try {
      final res =
          await http.get(Uri.parse('${Constantes.baseUrl}/inmuebles/zonas'));
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        setState(() {
          _zonasDisponibles = (data['datos'] as List).cast<String>();
          _cargandoZonas = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _cargandoZonas = false);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _paginaCompleta {
    switch (_paginaActual) {
      case 0:
        return _aceptaMascotas != null;
      case 1:
        return _fumaTabaco != null;
      case 2:
        return _cronotipo != null;
      case 3:
        return _ambienteEstudio != null;
      case 4:
        return _politicaVisitas != null;
      case 5:
        return _nivelOrden != null;
      case 6:
        return _zonas.isNotEmpty;
      case 7:
        return true;
      case 8:
        return _descCtrl.text.trim().length >= 20;
      default:
        return false;
    }
  }

  void _siguiente() {
    if (_paginaActual < _totalPaginas - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _guardar();
    }
  }

  Future<void> _guardar() async {
    if (!_paginaCompleta) return;
    setState(() => _guardando = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await http.post(
        Uri.parse('${Constantes.baseUrl}/convivencia/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'aceptaMascotas': _aceptaMascotas,
          'fumaTabaco': _fumaTabaco,
          'cronotipo': _cronotipo,
          'ambienteEstudio': _ambienteEstudio,
          'politicaVisitas': _politicaVisitas,
          'nivelOrden': _nivelOrden,
          'descripcionSobreMi': _descCtrl.text.trim(),
          'zonasPreferidas': _zonas.toList(),
          'presupuestoMin': _presupuesto.start.round(),
          'presupuestoMax': _presupuesto.end.round(),
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(res.body);
      if (data['ok'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['mensaje'] ?? 'Error al guardar')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error de conexión')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _textoOscuro),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Test de Convivencia',
            style: TextStyle(
                color: _textoOscuro,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(children: [
        _buildProgress(),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _paginaActual = i),
            children: [
              _pregunta(
                emoji: '🐾',
                titulo: 'Convivencia con Mascotas',
                subtitulo: '¿Tienés o tolerás vivir con mascotas en el hogar?',
                opciones: const [
                  _Opcion('SI', 'Sí (Tengo o planeás tener una) 🐶'),
                  _Opcion('NO_TOLERO', 'No, y no tolero vivir con mascotas'),
                  _Opcion('INDIFERENTE',
                      'No tengo, pero no me molesta convivir con ellas 😊'),
                ],
                seleccionado: _aceptaMascotas,
                onSelect: (v) => setState(() => _aceptaMascotas = v),
              ),
              _pregunta(
                emoji: '🚬',
                titulo: 'Consumo de Tabaco',
                subtitulo: '¿Fumás o tolerás que se fume dentro del hogar?',
                opciones: const [
                  _Opcion('SI', 'Sí, fumo habitualmente 🚬'),
                  _Opcion('NO_TOLERO',
                      'No fumo y no tolero que se fume dentro de la casa'),
                  _Opcion('INDIFERENTE',
                      'No fumo, pero no me molesta que mi roommate lo haga'),
                ],
                seleccionado: _fumaTabaco,
                onSelect: (v) => setState(() => _fumaTabaco = v),
              ),
              _pregunta(
                emoji: '⏰',
                titulo: 'Cronotipo y Horarios',
                subtitulo: '¿Cómo sos con tu rutina diaria?',
                opciones: const [
                  _Opcion('DIURNO',
                      '☀️  Diurno: Me levanto temprano y prefiero estudiar de mañana/tarde'),
                  _Opcion('NOCTURNO',
                      '🌙  Nocturno: Rindo mejor de noche y suelo trasnochar'),
                ],
                seleccionado: _cronotipo,
                onSelect: (v) => setState(() => _cronotipo = v),
              ),
              _pregunta(
                emoji: '📚',
                titulo: 'Entorno de Concentración',
                subtitulo: '¿Qué ambiente necesitás para estudiar o trabajar?',
                opciones: const [
                  _Opcion('SILENCIO',
                      '🤫  Silencio Absoluto: Me distraigo fácil, necesito paz total'),
                  _Opcion('ACTIVO',
                      '🎵  Ambiente Activo: Puedo estudiar con música o ruido moderado'),
                ],
                seleccionado: _ambienteEstudio,
                onSelect: (v) => setState(() => _ambienteEstudio = v),
              ),
              _pregunta(
                emoji: '🚪',
                titulo: 'Política de Visitas',
                subtitulo: '¿Con qué frecuencia recibís personas en casa?',
                opciones: const [
                  _Opcion('FRECUENTE',
                      'Frecuente: Me gusta la vida social y hacer trabajos en grupo'),
                  _Opcion('MODERADO',
                      'Moderado: Solo visitas programadas o fines de semana tranquilos'),
                  _Opcion('RESTRINGIDO',
                      'Restringido: Prefiero el hogar estrictamente para descanso total'),
                ],
                seleccionado: _politicaVisitas,
                onSelect: (v) => setState(() => _politicaVisitas = v),
              ),
              _pregunta(
                emoji: '🧹',
                titulo: 'Filosofía de Limpieza',
                subtitulo: '¿Cómo manejás el orden en los espacios comunes?',
                opciones: const [
                  _Opcion('RIGUROSO',
                      '🧹  Riguroso: Me gusta ser limpio y que todo esté en su lugar'),
                  _Opcion('RELAJADO',
                      '😌  Relajado: Soy tolerante, puedo limpiar después o el fin de semana'),
                ],
                seleccionado: _nivelOrden,
                onSelect: (v) => setState(() => _nivelOrden = v),
              ),
              _preguntaZonas(),
              _preguntaPresupuesto(),
              _preguntaDescripcion(),
            ],
          ),
        ),
        _buildBoton(),
      ]),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Pregunta ${_paginaActual + 1} de $_totalPaginas',
              style: const TextStyle(fontSize: 12, color: _gris)),
          const Spacer(),
          Text('${((_paginaActual + 1) / _totalPaginas * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: _verde)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_paginaActual + 1) / _totalPaginas,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(_verde),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _pregunta({
    required String emoji,
    required String titulo,
    required String subtitulo,
    required List<_Opcion> opciones,
    required String? seleccionado,
    required ValueChanged<String> onSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(titulo,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 6),
        Text(subtitulo, style: const TextStyle(fontSize: 14, color: _gris)),
        const SizedBox(height: 28),
        ...opciones.map((op) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OpcionTile(
                opcion: op,
                seleccionado: seleccionado == op.valor,
                onTap: () => onSelect(op.valor),
              ),
            )),
      ]),
    );
  }

  Widget _preguntaZonas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('¿En qué zonas buscás?',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 6),
        const Text(
            'Elegí todas las zonas donde te gustaría vivir. Mientras más marques, más compañeros compatibles vas a encontrar.',
            style: TextStyle(fontSize: 14, color: _gris)),
        const SizedBox(height: 24),
        if (_cargandoZonas)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: _verde),
            ),
          )
        else if (_zonasDisponibles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _grisClaro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No pudimos cargar las zonas. Revisá tu conexión y volvé a intentar.',
              style: TextStyle(fontSize: 13, color: _gris),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _zonasDisponibles.map((z) {
              final sel = _zonas.contains(z);
              return GestureDetector(
                onTap: () =>
                    setState(() => sel ? _zonas.remove(z) : _zonas.add(z)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: sel ? _verdeClaro : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: sel ? _verde : const Color(0xFFE5E7EB),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (sel) ...[
                      const Icon(Icons.check, size: 15, color: _verdeOscuro),
                      const SizedBox(width: 6),
                    ],
                    Text(z,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          color: sel ? _verdeOscuro : _textoOscuro,
                        )),
                  ]),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        if (!_cargandoZonas && _zonas.isEmpty)
          const Text('Seleccioná al menos una zona',
              style: TextStyle(fontSize: 12, color: Colors.red)),
      ]),
    );
  }

  Widget _preguntaPresupuesto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💰', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('¿Cuál es tu presupuesto?',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 6),
        const Text(
            'Cuánto podés pagar por mes. Solo te mostraremos compañeros con un presupuesto compatible con el tuyo.',
            style: TextStyle(fontSize: 14, color: _gris)),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Bs. ${_presupuesto.start.round()} – ${_presupuesto.end.round()}',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _verdeOscuro),
          ),
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _presupuesto,
          min: 200,
          max: 3000,
          divisions: 56,
          activeColor: _verde,
          inactiveColor: _verde.withOpacity(0.2),
          labels: RangeLabels(
            'Bs. ${_presupuesto.start.round()}',
            'Bs. ${_presupuesto.end.round()}',
          ),
          onChanged: (v) => setState(() => _presupuesto = v),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _grisClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: _gris),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Es lo que vos podrías aportar por mes, no el precio total del inmueble.',
                style: TextStyle(fontSize: 12, color: _gris, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _preguntaDescripcion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('✍️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('Contanos sobre vos',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 6),
        const Text(
            'Describí tu estilo de vida, expectativas y qué buscás en un roommate.',
            style: TextStyle(fontSize: 14, color: _gris)),
        const SizedBox(height: 28),
        TextField(
          controller: _descCtrl,
          maxLines: 5,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Ej: Soy estudiante de sistemas, me gusta el orden y el silencio '
                'para estudiar. Busco alguien tranquilo y responsable con los gastos comunes...',
            hintStyle: const TextStyle(fontSize: 13, color: _gris),
            filled: true,
            fillColor: _grisClaro,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _verde, width: 1.5)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (_descCtrl.text.trim().isNotEmpty &&
            _descCtrl.text.trim().length < 20)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Mínimo 20 caracteres',
                style: TextStyle(fontSize: 12, color: Colors.red)),
          ),
      ]),
    );
  }

  Widget _buildBoton() {
    final esUltima = _paginaActual == _totalPaginas - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _paginaCompleta && !_guardando ? _siguiente : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _verde,
            disabledBackgroundColor: const Color(0xFFD1FAE5),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(esUltima ? 'Guardar y ver matches  🎉' : 'Siguiente  →',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
        ),
      ),
    );
  }
}

class _Opcion {
  final String valor;
  final String etiqueta;
  const _Opcion(this.valor, this.etiqueta);
}

class _OpcionTile extends StatelessWidget {
  final _Opcion opcion;
  final bool seleccionado;
  final VoidCallback onTap;
  const _OpcionTile({
    required this.opcion,
    required this.seleccionado,
    required this.onTap,
  });

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _textoOscuro = Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: seleccionado ? _verdeClaro : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? _verde : const Color(0xFFE5E7EB),
            width: seleccionado ? 2 : 1,
          ),
          boxShadow: seleccionado
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(children: [
          Expanded(
            child: Text(opcion.etiqueta,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      seleccionado ? FontWeight.w600 : FontWeight.normal,
                  color: seleccionado ? _verdeOscuro : _textoOscuro,
                )),
          ),
          if (seleccionado)
            const Icon(Icons.check_circle, color: _verde, size: 22),
        ]),
      ),
    );
  }
}
