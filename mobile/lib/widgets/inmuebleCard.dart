import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/inmueble.dart';

class InmuebleCard extends StatefulWidget {
  final Inmueble inmueble;
  final VoidCallback onTap;
  final bool isFavorito; // ← NUEVO
  final VoidCallback? onFavoritoTap; // ← NUEVO

  const InmuebleCard({
    super.key,
    required this.inmueble,
    required this.onTap,
    this.isFavorito = false,
    this.onFavoritoTap,
  });

  @override
  State<InmuebleCard> createState() => _InmuebleCardState();
}

class _InmuebleCardState extends State<InmuebleCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatearMiles(double precio) {
    return precio.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'DEPARTAMENTO':
        return Colors.green;
      case 'CUARTO':
        return Colors.brown;
      case 'COMPARTIDO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'DEPARTAMENTO':
        return 'Departamento';
      case 'CUARTO':
        return 'Cuarto';
      case 'COMPARTIDO':
        return 'Compartido';
      default:
        return tipo;
    }
  }

  List<Map<String, dynamic>> _serviciosActivos() {
    final all = [
      {
        'icon': Icons.wifi,
        'label': 'Internet',
        'activo': widget.inmueble.internetIncluido
      },
      {
        'icon': Icons.bolt,
        'label': 'Luz',
        'activo': widget.inmueble.luzIncluida
      },
      {
        'icon': Icons.water_drop,
        'label': 'Agua',
        'activo': widget.inmueble.aguaIncluida
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Gas',
        'activo': widget.inmueble.gasIncluido
      },
    ];
    return all.where((s) => s['activo'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.inmueble.imagenes;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  imagenes.isNotEmpty
                      ? SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: imagenes.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => CachedNetworkImage(
                              imageUrl: imagenes[i].url,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              errorWidget: (_, __, ___) => _placeholderImagen(),
                            ),
                          ),
                        )
                      : _placeholderImagen(),
                  if (imagenes.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imagenes.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (imagenes.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPage + 1}/${imagenes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: widget.onFavoritoTap,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFavorito
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.isFavorito
                              ? Colors.red[400]
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _colorTipo(widget.inmueble.tipo)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _labelTipo(widget.inmueble.tipo),
                              style: TextStyle(
                                color: _colorTipo(widget.inmueble.tipo),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.inmueble.tipoOferta == 'ANTICRETICO'
                                  ? const Color(0xFFF5F3FF)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: widget.inmueble.tipoOferta ==
                                          'ANTICRETICO'
                                      ? const Color(0xFF8B5CF6).withOpacity(0.3)
                                      : const Color(0xFF3B82F6)
                                          .withOpacity(0.3)),
                            ),
                            child: Text(
                              widget.inmueble.tipoOferta == 'ANTICRETICO'
                                  ? ' Anticrético'
                                  : ' Alquiler',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.inmueble.tipoOferta ==
                                          'ANTICRETICO'
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.inmueble.tipoOferta == 'ANTICRETICO'
                            ? 'Bs. ${_formatearMiles(widget.inmueble.precio)}'
                            : 'Bs. ${_formatearMiles(widget.inmueble.precio)}/mes',
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.inmueble.titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.inmueble.zona,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ]),
                  if (_serviciosActivos().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _serviciosActivos()
                          .map((s) => _buildChip(
                              s['icon'] as IconData, s['label'] as String))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _placeholderImagen() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('Sin imágenes',
            style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ]),
    );
  }
}
