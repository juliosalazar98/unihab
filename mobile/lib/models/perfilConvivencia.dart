class PerfilConvivencia {
  final int id;
  final String aceptaMascotas;
  final String fumaTabaco;
  final String cronotipo;
  final String ambienteEstudio;
  final String politicaVisitas;
  final String nivelOrden;
  final String descripcionSobreMi;
  final List<String> zonasPreferidas;
  final int? presupuestoMin;
  final int? presupuestoMax;
  final bool activo;

  const PerfilConvivencia({
    required this.id,
    required this.aceptaMascotas,
    required this.fumaTabaco,
    required this.cronotipo,
    required this.ambienteEstudio,
    required this.politicaVisitas,
    required this.nivelOrden,
    required this.descripcionSobreMi,
    this.zonasPreferidas = const [],
    this.presupuestoMin,
    this.presupuestoMax,
    this.activo = true,
  });

  factory PerfilConvivencia.fromJson(Map<String, dynamic> json) =>
      PerfilConvivencia(
        id: json['id'] as int,
        aceptaMascotas: json['aceptaMascotas'] as String,
        fumaTabaco: json['fumaTabaco'] as String,
        cronotipo: json['cronotipo'] as String,
        ambienteEstudio: json['ambienteEstudio'] as String,
        politicaVisitas: json['politicaVisitas'] as String,
        nivelOrden: json['nivelOrden'] as String,
        descripcionSobreMi: json['descripcionSobreMi'] as String,
        zonasPreferidas:
            ((json['zonasPreferidas'] as List?) ?? []).cast<String>(),
        presupuestoMin: json['presupuestoMin'] as int?,
        presupuestoMax: json['presupuestoMax'] as int?,
        activo: (json['activo'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'aceptaMascotas': aceptaMascotas,
        'fumaTabaco': fumaTabaco,
        'cronotipo': cronotipo,
        'ambienteEstudio': ambienteEstudio,
        'politicaVisitas': politicaVisitas,
        'nivelOrden': nivelOrden,
        'descripcionSobreMi': descripcionSobreMi,
        'zonasPreferidas': zonasPreferidas,
        'presupuestoMin': presupuestoMin,
        'presupuestoMax': presupuestoMax,
      };
}
