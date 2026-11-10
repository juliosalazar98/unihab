import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constantes.dart';
import '../models/inmueble.dart';

class InmuebleService {
  Future<Map<String, dynamic>> obtenerInmuebles({
    String? zona,
    String? tipo,
    String? tipoOferta,
    double? precioMin,
    double? precioMax,
    String? orden,
    Set<String>? servicios,
    int page = 1,
    int limit = 10,
  }) async {
    String url = '${Constantes.baseUrl}/inmuebles?page=$page&limit=$limit';
    if (zona != null && zona.isNotEmpty) url += '&zona=$zona';
    if (tipo != null && tipo.isNotEmpty) url += '&tipo=$tipo';
    if (tipoOferta != null && tipoOferta.isNotEmpty)
      url += '&tipoOferta=$tipoOferta';
    if (precioMin != null) url += '&precioMin=$precioMin';
    if (precioMax != null) url += '&precioMax=$precioMax';
    if (orden != null && orden.isNotEmpty) url += '&orden=$orden';
    if (servicios != null) {
      for (final s in servicios) {
        url += '&$s=true';
      }
    }

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data['ok'] == true) {
      final lista = (data['datos']['inmuebles'] as List)
          .map((i) => Inmueble.fromJson(i))
          .toList();
      return {
        'inmuebles': lista,
        'total': data['datos']['total'],
        'totalPaginas': data['datos']['totalPaginas'],
      };
    }

    return {'inmuebles': [], 'total': 0, 'totalPaginas': 0};
  }

  Future<Inmueble?> obtenerInmueble(int id) async {
    final res = await http.get(
      Uri.parse('${Constantes.baseUrl}/inmuebles/$id'),
    );
    final data = jsonDecode(res.body);
    if (data['ok'] == true) return Inmueble.fromJson(data['datos']);
    return null;
  }
}
