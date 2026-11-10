import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/inmueble.dart';
import '../../../providers/authProvider.dart';
import '../../../services/inmuebleService.dart';
import '../../../widgets/inmuebleCard.dart';
import 'detalleInmuebleScreen.dart';
import '../propietario/crearInmuebleScreen.dart';

class ListaInmueblesScreen extends StatefulWidget {
  const ListaInmueblesScreen({super.key});

  @override
  State<ListaInmueblesScreen> createState() => _ListaInmueblesScreenState();
}

class _ListaInmueblesScreenState extends State<ListaInmueblesScreen> {
  final InmuebleService _service = InmuebleService();
  final _zonaController = TextEditingController();
  List<Inmueble> _inmuebles = [];
  bool _cargando = true;
  String? _tipoSeleccionado;
  int _pagina = 1;
  int _totalPaginas = 1;

  final List<String> _tipos = ['TODOS', 'CUARTO', 'DEPARTAMENTO', 'COMPARTIDO'];

  @override
  void initState() {
    super.initState();
    _cargarInmuebles();
  }

  Future<void> _cargarInmuebles({bool reset = false}) async {
    if (reset) _pagina = 1;
    setState(() => _cargando = true);

    final resultado = await _service.obtenerInmuebles(
      zona: _zonaController.text.trim(),
      tipo: _tipoSeleccionado == 'TODOS' ? null : _tipoSeleccionado,
      page: _pagina,
    );

    setState(() {
      _inmuebles = resultado['inmuebles'];
      _totalPaginas = resultado['totalPaginas'];
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _zonaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: auth.esPropietario
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearInmuebleScreen()),
              ).then((_) => _cargarInmuebles(reset: true)),
              backgroundColor:
                  Color.fromARGB(255, 54, 97, 58), //255, 54, 97, 58
              icon: const Icon(Icons.add, color: Colors.white),
              label:
                  const Text('Publicar', style: TextStyle(color: Colors.white)),
            )
          : null,
      appBar: AppBar(
        backgroundColor:
            Color.fromARGB(255, 169, 167, 165), // 255, 169, 167, 165p
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'UniHab',
          style: TextStyle(
            color: Color.fromARGB(255, 240, 239, 238),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.usuario?.nombre ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(auth.usuario?.email ?? '',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          auth.usuario?.rol ?? '',
                          style:
                              TextStyle(color: Colors.blue[800], fontSize: 12),
                        ),
                      ),
                      if (auth.esPropietario)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/mis-inmuebles');
                            },
                            icon: const Icon(Icons.home_outlined,
                                color: Colors.white),
                            label: const Text('Mis publicaciones',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 54, 97, 58),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await auth.logout();
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _zonaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por zona (Cala Cala, Quillacollo...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () => _cargarInmuebles(reset: true),
                    ),
                  ),
                  onSubmitted: (_) => _cargarInmuebles(reset: true),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tipos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final tipo = _tipos[i];
                      final seleccionado = _tipoSeleccionado == tipo ||
                          (tipo == 'TODOS' && _tipoSeleccionado == null);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _tipoSeleccionado =
                              tipo == 'TODOS' ? null : tipo);
                          _cargarInmuebles(reset: true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? Colors.blue[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tipo == 'TODOS'
                                ? 'Todos'
                                : tipo[0] + tipo.substring(1).toLowerCase(),
                            style: TextStyle(
                              color:
                                  seleccionado ? Colors.white : Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _inmuebles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No se encontraron inmuebles',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _cargarInmuebles(reset: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _inmuebles.length,
                          itemBuilder: (_, i) => InmuebleCard(
                            inmueble: _inmuebles[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetalleInmuebleScreen(
                                  inmuebleId: _inmuebles[i].id,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
          if (_totalPaginas > 1)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _pagina > 1
                        ? () {
                            setState(() => _pagina--);
                            _cargarInmuebles();
                          }
                        : null,
                  ),
                  Text('$_pagina de $_totalPaginas'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _pagina < _totalPaginas
                        ? () {
                            setState(() => _pagina++);
                            _cargarInmuebles();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
