import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/settingsProvider.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  static const _verde = Color(0xFF10B981);
  static const _textoOscuro = Color(0xFF1F2937);
  static const _gris = Color(0xFF9CA3AF);
  static const _grisClaro = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textoOscuro,
        title: const Text('Configuración',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textoOscuro)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
              _buildSwitchTile(
                icono: Icons.notifications_none_outlined,
                label: 'Notificaciones Internas',
                valor: settings.notificacionesActivas,
                onChanged: (v) => settings.setNotificacionesActivas(v),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: _grisClaro,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline,
                      color: _textoOscuro, size: 18),
                ),
                title: const Text('Acerca de UniHab',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textoOscuro)),
                trailing: const Icon(Icons.chevron_right, color: _gris),
                onTap: () => _mostrarAcercaDe(context),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icono,
    required String label,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: _grisClaro, borderRadius: BorderRadius.circular(10)),
        child: Icon(icono, color: _textoOscuro, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _textoOscuro)),
      trailing: Switch(
        value: valor,
        onChanged: onChanged,
        activeColor: _verde,
      ),
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'UniHab',
      applicationVersion: '1.0.0',
      applicationIcon:
          const Icon(Icons.home_work_outlined, color: _verde, size: 36),
      children: const [
        SizedBox(height: 12),
        Text('Desarrollado por Joel Salazar.', style: TextStyle(fontSize: 13)),
      ],
    );
  }
}
