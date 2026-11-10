import 'package:flutter/material.dart';

class PerfilEstudianteScreen extends StatelessWidget {
  final Map<String, dynamic> estudiante;

  const PerfilEstudianteScreen({super.key, required this.estudiante});

  static const _verde = Color(0xFF10B981);
  static const _verdeOscuro = Color(0xFF059669);
  static const _verdeClaro = Color(0xFFECFDF5);
  static const _grisClaro = Color(0xFFF3F4F6);
  static const _gris = Color(0xFF9CA3AF);
  static const _textoOscuro = Color(0xFF1F2937);

  String _labelGenero(String? g) {
    switch (g) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      case 'OTRO':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = estudiante['nombre'] as String? ?? '';
    final email = estudiante['email'] as String? ?? '';
    final telefono = estudiante['telefono'] as String?;
    final fotoPerfil = estudiante['fotoPerfil'] as String?;
    final carrera = estudiante['carrera'] as String?;
    final genero = estudiante['genero'] as String?;
    final ciudad = estudiante['ciudadOrigen'] as String?;
    final puntoInteres = estudiante['puntoInteres'] as Map<String, dynamic>?;
    final institucion = puntoInteres?['nombre'] as String?;
    final tipoInst = puntoInteres?['tipo'] as String?;

    final tieneAcademico = institucion != null || carrera != null;
    final tieneSobreMi = genero != null || ciudad != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        title: const Text(
          'Perfil del estudiante',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: _textoOscuro),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: _verdeClaro,
                  backgroundImage: (fotoPerfil != null && fotoPerfil.isNotEmpty)
                      ? NetworkImage(fotoPerfil)
                      : null,
                  child: (fotoPerfil == null || fotoPerfil.isEmpty)
                      ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: _verdeOscuro))
                      : null,
                ),
                const SizedBox(height: 14),
                Text(nombre,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textoOscuro)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: _gris)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: _verdeClaro,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('ARRENDATARIO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _verdeOscuro)),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            if (tieneAcademico) ...[
              _seccion('Información académica'),
              const SizedBox(height: 12),
              if (tipoInst != null && institucion != null)
                _infoRow(
                  icon: tipoInst == 'UNIVERSIDAD'
                      ? Icons.school_outlined
                      : Icons.business_outlined,
                  label:
                      tipoInst == 'UNIVERSIDAD' ? 'Universidad' : 'Instituto',
                  valor: institucion,
                ),
              if (carrera != null)
                _infoRow(
                    icon: Icons.book_outlined,
                    label: 'Carrera',
                    valor: carrera),
              const SizedBox(height: 8),
            ],
            if (tieneSobreMi) ...[
              _seccion('Sobre el estudiante'),
              const SizedBox(height: 12),
              if (genero != null)
                _infoRow(
                    icon: Icons.person_outline,
                    label: 'Género',
                    valor: _labelGenero(genero)),
              if (ciudad != null)
                _infoRow(
                    icon: Icons.location_city_outlined,
                    label: 'Ciudad de origen',
                    valor: ciudad),
              const SizedBox(height: 8),
            ],
            _seccion('Contacto'),
            const SizedBox(height: 12),
            _infoRow(icon: Icons.email_outlined, label: 'Correo', valor: email),
            if (telefono != null && telefono.isNotEmpty)
              _infoRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  valor: telefono),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _grisClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 14, color: _gris),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Perfil de solo lectura. Los datos son proporcionados por el estudiante.',
                    style: TextStyle(fontSize: 11, color: _gris, height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(titulo,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      );

  Widget _infoRow(
      {required IconData icon, required String label, required String valor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: _gris),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: _gris, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textoOscuro)),
        ]),
      ]),
    );
  }
}
