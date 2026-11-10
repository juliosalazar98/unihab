class Imagen {
  final int id;
  final String url;

  Imagen({required this.id, required this.url});

  factory Imagen.fromJson(Map<String, dynamic> json) {
    return Imagen(id: json['id'] ?? 0, url: json['url'] ?? '');
  }
}

class Inmueble {
  final int id;
  final String titulo;
  final String? descripcion;
  final double precio;
  final String tipo;
  final String zona;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final bool disponible;
  final bool aprobado;
  final String tipoOferta;
  final List<Imagen> imagenes;
  final Map<String, dynamic>? propietario;
  final bool luzIncluida;
  final bool aguaIncluida;
  final bool internetIncluido;
  final bool gasIncluido;
  final double? tamano;
  final int? piso;
  final bool? amoblado;
  final bool? permiteMascotas;
  final String? generoPermitido;
  final int? numDormitorios;
  final int? numBanos;
  final bool? tieneParqueo;
  final int? habitantesMax;
  final int? habitacionesTotales;
  final int? habitacionesDisponibles;
  final bool? banoCompartido;
  final bool? soloEstudiantes;
  final String? generoConvivientes;
  final int? edadMinima;
  final int? edadMaxima;
  final String? observaciones;
  final String? reglasComunes;
  final String? motivoRechazo;
  final bool desactivadoPorAdmin;
  final bool enApelacion;

  Inmueble({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.precio,
    required this.tipo,
    required this.zona,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.disponible,
    required this.aprobado,
    this.tipoOferta = 'ALQUILER',
    required this.imagenes,
    this.propietario,
    this.luzIncluida = false,
    this.aguaIncluida = false,
    this.internetIncluido = false,
    this.gasIncluido = false,
    this.tamano,
    this.piso,
    this.amoblado,
    this.permiteMascotas,
    this.generoPermitido,
    this.numDormitorios,
    this.numBanos,
    this.tieneParqueo,
    this.habitantesMax,
    this.habitacionesTotales,
    this.habitacionesDisponibles,
    this.banoCompartido,
    this.soloEstudiantes,
    this.generoConvivientes,
    this.edadMinima,
    this.edadMaxima,
    this.observaciones,
    this.reglasComunes,
    this.motivoRechazo,
    this.desactivadoPorAdmin = false,
    this.enApelacion = false,
  });

  factory Inmueble.fromJson(Map<String, dynamic> json) {
    return Inmueble(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      tipo: json['tipo'] ?? '',
      zona: json['zona'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud:
          json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      disponible: json['disponible'] ?? true,
      aprobado: json['aprobado'] ?? false,
      tipoOferta: json['tipoOferta'] as String? ?? 'ALQUILER',
      imagenes: json['imagenes'] != null
          ? (json['imagenes'] as List).map((i) => Imagen.fromJson(i)).toList()
          : [],
      propietario: json['propietario'],
      luzIncluida: json['luzIncluida'] ?? false,
      aguaIncluida: json['aguaIncluida'] ?? false,
      internetIncluido: json['internetIncluido'] ?? false,
      gasIncluido: json['gasIncluido'] ?? false,
      tamano:
          json['tamano'] != null ? (json['tamano'] as num).toDouble() : null,
      piso: json['piso'] as int?,
      amoblado: json['amoblado'] as bool?,
      permiteMascotas: json['permiteMascotas'] as bool?,
      generoPermitido: json['generoPermitido'] as String?,
      numDormitorios: json['numDormitorios'] as int?,
      numBanos: json['numBanos'] as int?,
      tieneParqueo: json['tieneParqueo'] as bool?,
      habitantesMax: json['habitantesMax'] as int?,
      habitacionesTotales: json['habitacionesTotales'] as int?,
      habitacionesDisponibles: json['habitacionesDisponibles'] as int?,
      banoCompartido: json['banoCompartido'] as bool?,
      soloEstudiantes: json['soloEstudiantes'] as bool?,
      generoConvivientes: json['generoConvivientes'] as String?,
      edadMinima: json['edadMinima'] as int?,
      edadMaxima: json['edadMaxima'] as int?,
      observaciones: json['observaciones'] as String?,
      reglasComunes: json['reglasComunes'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      desactivadoPorAdmin: json['desactivadoPorAdmin'] ?? false,
      enApelacion: json['enApelacion'] ?? false,
    );
  }
}
