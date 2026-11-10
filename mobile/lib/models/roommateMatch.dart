class RoommateMatch {
  final int usuarioId;
  final String nombre;
  final String? fotoPerfil;
  final String? telefono;
  final String? institucion;
  final String descripcionSobreMi;
  final int afinidad;
  final Map<String, String> perfil;
  final String? carrera;
  final String? genero;
  final String? ciudadOrigen;
  final List<String> zonasPreferidas;
  final List<String> zonasEnComun;
  final int? presupuestoMin;
  final int? presupuestoMax;
  final int? matchId;
  final String? estadoMatch; // null | 'PENDIENTE' | 'ACEPTADO'
  final bool? soyElSolicitante;

  const RoommateMatch({
    required this.usuarioId,
    required this.nombre,
    this.fotoPerfil,
    this.telefono,
    this.institucion,
    required this.descripcionSobreMi,
    required this.afinidad,
    required this.perfil,
    this.zonasPreferidas = const [],
    this.zonasEnComun = const [],
    this.presupuestoMin,
    this.presupuestoMax,
    this.matchId,
    this.estadoMatch,
    this.soyElSolicitante,
    this.carrera,
    this.genero,
    this.ciudadOrigen,
  });

  bool get tienePresupuesto => presupuestoMin != null && presupuestoMax != null;

  String get presupuestoTexto =>
      tienePresupuesto ? 'Bs. $presupuestoMin – $presupuestoMax' : '';

  factory RoommateMatch.fromJson(Map<String, dynamic> json) => RoommateMatch(
        usuarioId: json['usuarioId'] as int,
        nombre: json['nombre'] as String,
        fotoPerfil: json['fotoPerfil'] as String?,
        telefono: json['telefono'] as String?,
        institucion: json['institucion'] as String?,
        descripcionSobreMi: json['descripcionSobreMi'] as String,
        afinidad: json['afinidad'] as int,
        perfil: Map<String, String>.from(json['perfil'] as Map),
        zonasPreferidas:
            ((json['zonasPreferidas'] as List?) ?? []).cast<String>(),
        zonasEnComun: ((json['zonasEnComun'] as List?) ?? []).cast<String>(),
        presupuestoMin: json['presupuestoMin'] as int?,
        presupuestoMax: json['presupuestoMax'] as int?,
        matchId: json['matchId'] as int?,
        estadoMatch: json['estadoMatch'] as String?,
        soyElSolicitante: json['soyElSolicitante'] as bool?,
        carrera: json['carrera'] as String?,
        genero: json['genero'] as String?,
        ciudadOrigen: json['ciudadOrigen'] as String?,
      );
}
