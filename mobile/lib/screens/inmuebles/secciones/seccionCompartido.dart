import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeccionCompartido extends StatelessWidget {
  final Map<String, dynamic> datos;
  final Function(String, dynamic) onCambio;

  const SeccionCompartido({
    super.key,
    required this.datos,
    required this.onCambio,
  });

  static const Color _verde = Color.fromARGB(255, 54, 97, 58);
  static const Color _grisSuave = Color(0xFFF7F3EF);

  final List<String> _reglasDisponibles = const [
    'Prohibido fiestas',
    'Visitas limitadas',
    'Uso de cocina compartida',
    'Silencio después de las 22:00',
    'No fumar dentro',
    'No mascotas',
  ];

  @override
  Widget build(BuildContext context) {
    final reglasMarcadas = List<String>.from(datos['reglasMarcadas'] ?? []);
    final rangoEdad =
        datos['rangoEdad'] as RangeValues? ?? const RangeValues(18, 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seccion('Detalles del espacio compartido'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _campoNumerico(
                label: 'Habitaciones totales',
                hint: 'Ej: 4',
                valor: datos['habitacionesTotales']?.toString() ?? '',
                onChange: (v) => onCambio('habitacionesTotales', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoNumerico(
                label: 'Disponibles',
                hint: 'Ej: 2',
                valor: datos['habitacionesDisponibles']?.toString() ?? '',
                onChange: (v) => onCambio('habitacionesDisponibles', v),
                error: _errorDisponibles(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Baño'),
        const SizedBox(height: 8),
        _selectorOpciones(
          opciones: ['Privado', 'Compartido'],
          valores: ['false', 'true'],
          seleccionado: datos['banoCompartido'] ?? 'false',
          onChange: (v) => onCambio('banoCompartido', v),
        ),
        const SizedBox(height: 16),
        _label('Género de convivientes actuales'),
        const SizedBox(height: 8),
        _selectorOpciones(
          opciones: ['Mixto', 'Solo hombres', 'Solo mujeres'],
          valores: ['MIXTO', 'HOMBRES', 'MUJERES'],
          seleccionado: datos['generoConvivientes'] ?? 'MIXTO',
          onChange: (v) => onCambio('generoConvivientes', v),
        ),
        const SizedBox(height: 16),
        _label('Género permitido para el postulante'),
        const SizedBox(height: 8),
        _selectorOpciones(
          opciones: ['Cualquiera', 'Solo hombres', 'Solo mujeres'],
          valores: ['CUALQUIERA', 'HOMBRES', 'MUJERES'],
          seleccionado: datos['generoPermitido'] ?? 'CUALQUIERA',
          onChange: (v) => onCambio('generoPermitido', v),
        ),
        const SizedBox(height: 16),
        _label(
            'Rango de edad del postulante: ${rangoEdad.start.round()} – ${rangoEdad.end.round()} años'),
        RangeSlider(
          values: rangoEdad,
          min: 18,
          max: 60,
          divisions: 42,
          activeColor: _verde,
          inactiveColor: _verde.withOpacity(0.2),
          labels: RangeLabels(
            rangoEdad.start.round().toString(),
            rangoEdad.end.round().toString(),
          ),
          onChanged: (v) => onCambio('rangoEdad', v),
        ),
        const SizedBox(height: 16),
        _seccion('Reglas de la casa'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _grisSuave,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: _reglasDisponibles.map((regla) {
              final marcada = reglasMarcadas.contains(regla);
              return CheckboxListTile(
                title: Text(regla, style: const TextStyle(fontSize: 13)),
                value: marcada,
                activeColor: _verde,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                onChanged: (v) {
                  final nuevas = List<String>.from(reglasMarcadas);
                  v! ? nuevas.add(regla) : nuevas.remove(regla);
                  onCambio('reglasMarcadas', nuevas);
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _switchOp(
          label: 'Solo para estudiantes',
          valor: datos['soloEstudiantes'] ?? false,
          onChange: (v) => onCambio('soloEstudiantes', v),
        ),
        _switchOp(
          label: 'Permite mascotas',
          valor: datos['permiteMascotas'] ?? false,
          onChange: (v) => onCambio('permiteMascotas', v),
        ),
        const SizedBox(height: 16),
        _label('Observaciones adicionales'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: datos['observaciones'] ?? '',
          maxLines: 3,
          onChanged: (v) => onCambio('observaciones', v),
          decoration: InputDecoration(
            hintText: 'Cualquier detalle extra que quieras aclarar...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: _grisSuave,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _seccion(String texto) => Text(
        texto,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5C3D2E),
        ),
      );

  Widget _label(String texto) => Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );

  String? _errorDisponibles() {
    final totales =
        int.tryParse(datos['habitacionesTotales']?.toString() ?? '');
    final disp =
        int.tryParse(datos['habitacionesDisponibles']?.toString() ?? '');
    if (totales == null || disp == null) return null;
    if (disp > totales) return 'No puede superar el total';
    return null;
  }

  Widget _campoNumerico({
    required String label,
    required String hint,
    required String valor,
    required Function(String) onChange,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: valor,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 11),
            filled: true,
            fillColor: _grisSuave,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _verde, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
        ),
      ],
    );
  }

  Widget _selectorOpciones({
    required List<String> opciones,
    required List<String> valores,
    required String seleccionado,
    required Function(String) onChange,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(opciones.length, (i) {
        final sel = seleccionado == valores[i];
        return GestureDetector(
          onTap: () => onChange(valores[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _verde : _grisSuave,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? _verde : _verde.withOpacity(0.2),
              ),
            ),
            child: Text(
              opciones[i],
              style: TextStyle(
                color: sel ? Colors.white : _verde,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _switchOp({
    required String label,
    required bool valor,
    required Function(bool) onChange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _grisSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        value: valor,
        activeColor: _verde,
        onChanged: onChange,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      ),
    );
  }
}
