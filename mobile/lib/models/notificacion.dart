class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final bool leido;
  final String tipo;
  final DateTime creadoEn;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.leido,
    required this.tipo,
    required this.creadoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) => Notificacion(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        mensaje: json['mensaje'] as String,
        leido: json['leido'] as bool,
        tipo: json['tipo'] as String,
        creadoEn: DateTime.parse(json['creadoEn'] as String).toLocal(),
      );
}
