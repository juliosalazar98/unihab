import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeccionDepartamento extends StatelessWidget {
  final Map<String, dynamic> datos;
  final Function(String, dynamic) onCambio;

  const SeccionDepartamento({
    super.key,
    required this.datos,
    required this.onCambio,
  });

  static const Color _verde = Color.fromARGB(255, 54, 97, 58);
  static const Color _grisSuave = Color(0xFFF7F3EF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _seccion('Detalles del departamento'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _campoNumerico(
                label: 'Dormitorios',
                hint: 'Ej: 2',
                valor: datos['numDormitorios']?.toString() ?? '',
                onChange: (v) => onCambio('numDormitorios', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoNumerico(
                label: 'Baños',
                hint: 'Ej: 1',
                valor: datos['numBanos']?.toString() ?? '',
                onChange: (v) => onCambio('numBanos', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _campoNumerico(
                label: 'Piso',
                hint: 'Ej: 3',
                valor: datos['piso']?.toString() ?? '',
                onChange: (v) => onCambio('piso', v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campoNumerico(
                label: 'Habitantes máx.',
                hint: 'Ej: 4',
                valor: datos['habitantesMax']?.toString() ?? '',
                onChange: (v) => onCambio('habitantesMax', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Género permitido'),
        const SizedBox(height: 8),
        _selectorOpciones(
          opciones: ['Cualquiera', 'Solo hombres', 'Solo mujeres'],
          valores: ['CUALQUIERA', 'HOMBRES', 'MUJERES'],
          seleccionado: datos['generoPermitido'] ?? 'CUALQUIERA',
          onChange: (v) => onCambio('generoPermitido', v),
        ),
        const SizedBox(height: 16),
        _switchOp(
          label: 'Tiene parqueo',
          valor: datos['tieneParqueo'] ?? false,
          onChange: (v) => onCambio('tieneParqueo', v),
        ),
        _switchOp(
          label: 'Amoblado',
          valor: datos['amoblado'] ?? false,
          onChange: (v) => onCambio('amoblado', v),
        ),
        _switchOp(
          label: 'Permite mascotas',
          valor: datos['permiteMascotas'] ?? false,
          onChange: (v) => onCambio('permiteMascotas', v),
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

  Widget _campoNumerico({
    required String label,
    required String hint,
    required String valor,
    required Function(String) onChange,
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
