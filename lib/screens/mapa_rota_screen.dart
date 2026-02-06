import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/endereco.dart';
import '../services/navegacao_service.dart';

class MapaRotaScreen extends StatefulWidget {
  final List<Endereco> enderecos;
  final LatLng? localizacaoAtual;

  const MapaRotaScreen({
    Key? key,
    required this.enderecos,
    this.localizacaoAtual,
  }) : super(key: key);

  @override
  State<MapaRotaScreen> createState() => _MapaRotaScreenState();
}

class _MapaRotaScreenState extends State<MapaRotaScreen> {
  late MapController _mapController;
  late List<Endereco> _enderecos;
  int _enderecoAtualIndex = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _enderecos = widget.enderecos;
    WidgetsBinding.instance.addPostFrameCallback((_) => _centralizarMapa());
  }

  List<LatLng> _obterCoordenadas() {
    List<LatLng> coords = [];
    
    if (widget.localizacaoAtual != null) {
      coords.add(widget.localizacaoAtual!);
    }
    
    coords.addAll(
      _enderecos
          .where((e) => e.coordenadas != null)
          .map((e) => e.coordenadas!)
          .toList(),
    );
    
    return coords;
  }

  void _centralizarMapa() {
    List<LatLng> coords = _obterCoordenadas();
    if (coords.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(coords),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  double _calcularDistanciaTotal() {
    double distancia = 0;
    const Distance distanceCalculator = Distance();

    for (int i = 0; i < _enderecos.length - 1; i++) {
      if (_enderecos[i].coordenadas != null && _enderecos[i + 1].coordenadas != null) {
        distancia += distanceCalculator.as(
          LengthUnit.Kilometer,
          _enderecos[i].coordenadas!,
          _enderecos[i + 1].coordenadas!,
        );
      }
    }

    return distancia;
  }

  void _navegarParaEndereco(Endereco endereco) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parada ${endereco.ordem ?? (_enderecos.indexOf(endereco) + 1)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(endereco.enderecoCombinado),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      bool sucesso = await NavegacaoService.abrirGoogleMaps(
                        endereco.coordenadas!,
                        endereco.enderecoCombinado,
                      );
                      if (!sucesso && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir Google Maps')),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      bool sucesso = await NavegacaoService.abrirWaze(
                        endereco.coordenadas!,
                      );
                      if (!sucesso && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Não foi possível abrir Waze')),
                        );
                      }
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Waze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _enderecoAtualIndex = _enderecos.indexOf(endereco);
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Marcar como entregue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<LatLng> coordenadas = _obterCoordenadas();
    double distanciaTotal = _calcularDistanciaTotal();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota de Entrega'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                '${distanciaTotal.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: coordenadas.isNotEmpty
                  ? coordenadas.first
                  : const LatLng(-23.5505, -46.6333),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'melhor_rota',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: coordenadas,
                    strokeWidth: 4,
                    color: Colors.blue.withValues(alpha: 0.7),
                  ),
                ],
              ),
              // Marcador da localização atual
              if (widget.localizacaoAtual != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.localizacaoAtual!,
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          Icon(Icons.my_location, color: Colors.green, size: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              // Marcadores dos endereços
              MarkerLayer(
                markers: _enderecos
                    .asMap()
                    .entries
                    .map(
                      (entry) => Marker(
                        point: entry.value.coordenadas!,
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _navegarParaEndereco(entry.value),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: entry.key <= _enderecoAtualIndex
                                    ? Colors.green
                                    : Colors.blue,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                color: entry.key <= _enderecoAtualIndex
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centralizarMapa,
              child: const Icon(Icons.my_location),
            ),
          ),
          // Card com próximo destino
          if (_enderecoAtualIndex < _enderecos.length)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.navigation, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Próxima entrega: ${_enderecoAtualIndex + 1}/${_enderecos.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _enderecos[_enderecoAtualIndex].enderecoCombinado,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _navegarParaEndereco(
                          _enderecos[_enderecoAtualIndex],
                        ),
                        icon: const Icon(Icons.directions),
                        label: const Text('Iniciar Navegação'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
