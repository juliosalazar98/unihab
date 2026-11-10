class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? telefono;
  final String? fotoPerfil;
  final int? puntoInteresId;
  final Map<String, dynamic>? puntoInteres;
  final String? carrera;
  final String? genero; // 'MASCULINO' | 'FEMENINO' | 'OTRO'
  final String? ciudadOrigen;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.fotoPerfil,
    this.puntoInteresId,
    this.puntoInteres,
    this.carrera,
    this.genero,
    this.ciudadOrigen,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: json['rol'] as String,
      telefono: json['telefono'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      puntoInteresId: json['puntoInteresId'] as int?,
      puntoInteres: json['puntoInteres'] != null
          ? Map<String, dynamic>.from(json['puntoInteres'])
          : null,
      carrera: json['carrera'] as String?,
      genero: json['genero'] as String?,
      ciudadOrigen: json['ciudadOrigen'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'fotoPerfil': fotoPerfil,
        'carrera': carrera,
        'genero': genero,
        'ciudadOrigen': ciudadOrigen,
      };
}
