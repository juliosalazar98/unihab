import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '/models/inmueble.dart';

class GaleriaInmuebleScreen extends StatelessWidget {
  final List<Imagen> imagenes;
  final int indiceInicial;

  const GaleriaInmuebleScreen({
    super.key,
    required this.imagenes,
    this.indiceInicial = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Fotos de la propiedad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _GaleriaCollage(
        imagenes: imagenes,
        indiceInicial: indiceInicial,
      ),
    );
  }
}

class _GaleriaCollage extends StatelessWidget {
  final List<Imagen> imagenes;
  final int indiceInicial;

  const _GaleriaCollage({
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  Widget build(BuildContext context) {
    if (imagenes.isEmpty) {
      return const Center(
        child: Text('Sin fotos disponibles',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: _FotoTile(
              imagen: imagenes[0],
              indice: 0,
              imagenes: imagenes,
              height: 260,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (imagenes.length > 1)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final indice = i + 1; // +1 porque la primera ya está arriba
                  return Padding(
                    padding: EdgeInsets.only(
                      right: i.isEven ? 6 : 0,
                      left: i.isOdd ? 6 : 0,
                      top: 12,
                    ),
                    child: _FotoTile(
                      imagen: imagenes[indice],
                      indice: indice,
                      imagenes: imagenes,
                      height: 160,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
                childCount: imagenes.length - 1,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}

class _FotoTile extends StatelessWidget {
  final Imagen imagen;
  final int indice;
  final List<Imagen> imagenes;
  final double height;
  final BorderRadius borderRadius;

  const _FotoTile({
    required this.imagen,
    required this.indice,
    required this.imagenes,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirVisor(context),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: imagen.url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF1C1C1E),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white38, strokeWidth: 1.5),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF1C1C1E),
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirVisor(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _VisorFotos(
          imagenes: imagenes,
          indiceInicial: indice,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _VisorFotos extends StatefulWidget {
  final List<Imagen> imagenes;
  final int indiceInicial;

  const _VisorFotos({
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  State<_VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<_VisorFotos> {
  late PageController _pageCtrl;
  late int _actual;

  @override
  void initState() {
    super.initState();
    _actual = widget.indiceInicial;
    _pageCtrl = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _actual = i),
            itemBuilder: (_, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imagenes[i].url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white38, strokeWidth: 1.5),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 48),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_actual + 1} / ${widget.imagenes.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imagenes.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _actual == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _actual == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
