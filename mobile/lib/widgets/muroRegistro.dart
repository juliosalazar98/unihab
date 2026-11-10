import 'package:flutter/material.dart';

const _verde = Color(0xFF10B981);
const _verdeClaro = Color(0xFFECFDF5);
const _verdeOscuro = Color(0xFF059669);
const _textoOscuro = Color(0xFF1F2937);
const _gris = Color(0xFF9CA3AF);

/// Muro de registro para funciones que requieren cuenta.
Future<void> mostrarMuroRegistro(
  BuildContext context, {
  required IconData icono,
  required String titulo,
  required String mensaje,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2)),
        ),
        Container(
          width: 72,
          height: 72,
          decoration:
              const BoxDecoration(color: _verdeClaro, shape: BoxShape.circle),
          child: Icon(icono, size: 34, color: _verde),
        ),
        const SizedBox(height: 20),
        Text(titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
        const SizedBox(height: 10),
        Text(mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _gris, height: 1.5)),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(sheetCtx);
              Navigator.pushNamed(context, '/registro');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _verde,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Crear cuenta gratis',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(sheetCtx);
              Navigator.pushNamed(context, '/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _verdeOscuro,
              side: BorderSide(color: _verde.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Ya tengo cuenta',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(sheetCtx),
          child: const Text('Seguir explorando',
              style: TextStyle(color: _gris, fontSize: 13)),
        ),
      ]),
    ),
  );
}
