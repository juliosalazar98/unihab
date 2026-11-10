import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '/config/constantes.dart';
import '/providers/authProvider.dart';

class EstadisticasPropietarioTab extends StatefulWidget {
  const EstadisticasPropietarioTab({super.key});

  @override
  State<EstadisticasPropietarioTab> createState() =>
      _EstadisticasPropietarioTabState();
}

class _EstadisticasPropietarioTabState
    extends State<EstadisticasPropietarioTab> {
  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  static const _coloresPie = [
    Color(0xFF10B981), // verde esmeralda    — 1°
    Color(0xFF6EE7B7), // verde menta claro  — 2°
    Color(0xFF374151), // gris oscuro elegante — 3°
    Color(0xFF6B7280), // gris medio         — 4°
    Color(0xFF9CA3AF), // gris claro         — 5°
    Color(0xFFD1FAE5), // verde muy suave    — 6°
  ];
  bool _cargando = true;
  int _vistas = 0;
  int _solicitudes = 0;
  double _conversion = 0;
  List<Map<String, dynamic>> _mensuales = [];
  List<Map<String, dynamic>> _popularidad = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_cargar);
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.get(
        Uri.parse('${Constantes.baseUrl}/estadisticas/propietario'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      final data = jsonDecode(res.body);
      if (data['ok'] == true && mounted) {
        final d = data['datos'] as Map<String, dynamic>;
        setState(() {
          _vistas = d['vistas'] as int;
          _solicitudes = d['solicitudes'] as int;
          _conversion = (d['conversion'] as num).toDouble();
          _mensuales =
              (d['solicitudesMensuales'] as List).cast<Map<String, dynamic>>();
          _popularidad =
              (d['popularidadInmuebles'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  String _labelMes(String mesKey) {
    const meses = {
      '01': 'Ene',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Abr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Ago',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dic',
    };
    final partes = mesKey.split('-');
    return partes.length >= 2 ? (meses[partes[1]] ?? partes[1]) : mesKey;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _verde));
    }

    return RefreshIndicator(
      color: _verde,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text('Estadísticas',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textoOscuro)),
          const SizedBox(height: 4),
          Text('Rendimiento de tus publicaciones',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),
          _buildKPIs(),
          const SizedBox(height: 24),
          _buildSeccion(
            titulo: 'Solicitudes por mes',
            subtitulo: 'Últimos 6 meses',
            icono: Icons.bar_chart_rounded,
            child: _buildBarChart(),
          ),
          const SizedBox(height: 20),
          if (_popularidad.isNotEmpty)
            _buildSeccion(
              titulo: 'Inmuebles más populares',
              subtitulo: 'Basado en solicitudes recibidas',
              icono: Icons.donut_large_rounded,
              child: _buildDonutChart(),
            ),
        ],
      ),
    );
  }

  Widget _buildKPIs() {
    return Row(children: [
      Expanded(
          child: _kpiCard(
        label: 'Vistas',
        valor: '$_vistas',
        icono: Icons.visibility_outlined,
        color: _verde,
        bgColor: _verdeClaro,
      )),
      const SizedBox(width: 10),
      Expanded(
          child: _kpiCard(
        label: 'Solicitudes',
        valor: '$_solicitudes',
        icono: Icons.contact_mail_outlined,
        color: _verdeOscuro,
        bgColor: const Color(0xFFD1FAE5),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: _kpiCard(
        label: 'Conversión',
        valor:
            _conversion % 1 == 0 ? '${_conversion.toInt()}%' : '$_conversion%',
        icono: Icons.trending_up_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
        tooltip: 'Solicitudes ÷ Vistas × 100',
      )),
    ]);
  }

  Widget _kpiCard({
    required String label,
    required String valor,
    required IconData icono,
    required Color color,
    required Color bgColor,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(valor,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: _verdeClaro, shape: BoxShape.circle),
            child: Icon(icono, size: 16, color: _verdeOscuro),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textoOscuro)),
            Text(subtitulo, style: const TextStyle(fontSize: 11, color: _gris)),
          ]),
        ]),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }

  Widget _buildBarChart() {
    if (_mensuales.isEmpty) return _buildVacio('Sin datos de solicitudes');

    final maxY = _mensuales
        .map((m) => (m['cantidad'] as int).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final limiteY = maxY < 5 ? 5.0 : (maxY * 1.2).ceilToDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: limiteY,
          barGroups: _mensuales.asMap().entries.map((e) {
            final cantidad = (e.value['cantidad'] as int).toDouble();
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: cantidad,
                  width: 22,
                  color: cantidad > 0 ? _verde : _grisClaro,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _mensuales.length)
                    return const SizedBox();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      _labelMes(_mensuales[idx]['mes'] as String),
                      style: const TextStyle(
                          fontSize: 11,
                          color: _gris,
                          fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == limiteY) return const SizedBox();
                  if (value % 1 != 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: _gris),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: _grisClaro, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _textoOscuro,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.toInt()} sol.',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonutChart() {
    if (_popularidad.isEmpty) return _buildVacio('Sin solicitudes todavía');

    int _pieTocado = -1;

    return StatefulBuilder(builder: (context, setLocal) {
      return Column(children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 52,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setLocal(() {
                    if (response?.touchedSection != null &&
                        event is FlTapUpEvent) {
                      _pieTocado =
                          response!.touchedSection!.touchedSectionIndex;
                    } else if (event is FlTapUpEvent) {
                      _pieTocado = -1;
                    }
                  });
                },
              ),
              sections: _popularidad.asMap().entries.map((e) {
                final color = _coloresPie[e.key % _coloresPie.length];
                final tocado = _pieTocado == e.key;
                final porc = (e.value['porcentaje'] as num).toDouble();
                return PieChartSectionData(
                  value: porc,
                  color: color,
                  radius: tocado ? 72 : 60,
                  title: '${porc.toStringAsFixed(0)}%',
                  titleStyle: TextStyle(
                    color: Colors.white,
                    fontSize: tocado ? 14 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ..._popularidad.asMap().entries.map((e) {
          final color = _coloresPie[e.key % _coloresPie.length];
          final titulo = e.value['titulo'] as String;
          final sols = e.value['solicitudes'] as int;
          final porc = (e.value['porcentaje'] as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(titulo,
                      style: const TextStyle(fontSize: 13, color: _textoOscuro),
                      overflow: TextOverflow.ellipsis)),
              Text('$sols sol.',
                  style: const TextStyle(fontSize: 12, color: _gris)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${porc.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ]),
          );
        }),
      ]);
    });
  }

  Widget _buildVacio(String mensaje) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bar_chart_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(mensaje,
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ]),
      ),
    );
  }
}
