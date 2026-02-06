import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/rota_alternativa.dart';
import '../services/localizacao_service.dart';

class NavegacaoScreen extends StatefulWidget {
  final RotaAlternativa rota;
  final LatLng minhaLocalizacao;

  const NavegacaoScreen({
    Key? key,
    required this.rota,
    required this.minhaLocalizacao,
  }) : super(key: key);

  @override
  State<NavegacaoScreen> createState() => _NavegacaoScreenState();
}

class _NavegacaoScreenState extends State<NavegacaoScreen> {
  late MapController _mapController;
  LatLng? _posicaoAtual;
  StreamSubscription<LatLng>? _localizacaoSubscription;
  int _paradaAtual = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _posicaoAtual = widget.minhaLocalizacao;
    _iniciarRastreamento();
  }

  void _iniciarRastreamento() {
    _localizacaoSubscription = LocalizacaoService.streamLocalizacao().listen((localizacao) {
      setState(() => _posicaoAtual = localizacao);
      _mapController.move(localizacao, _mapController.camera.zoom);
    });
  }

  @override
  void dispose() {
    _localizacaoSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _posicaoAtual ?? widget.rota.pontos.first,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'melhor_rota',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.rota.pontos,
                    strokeWidth: 5,
                    color: Colors.blue,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Posição atual
                  if (_posicaoAtual != null)
                    Marker(
                      point: _posicaoAtual!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.navigation, color: Colors.blue, size: 40),
                    ),
                  // Destinos
                  ...widget.rota.enderecos.asMap().entries.map((entry) {
                    return Marker(
                      point: entry.value.coordenadas!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: entry.key == _paradaAtual ? Colors.green : Colors.blue,
                            child: Text('${entry.key + 1}'),
                          ),
                          const Icon(Icons.location_on, color: Colors.red),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // Painel superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildPainelSuperior(),
          ),

          // Painel inferior com próxima instrução
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPainelInferior(),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelSuperior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.rota.tempoFormatado,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.rota.distanciaFormatada,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_paradaAtual + 1) / widget.rota.enderecos.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 4),
          Text(
            'Parada ${_paradaAtual + 1} de ${widget.rota.enderecos.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelInferior() {
    if (_paradaAtual >= widget.rota.enderecos.length) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.green,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Center(
          child: Text(
            '🎉 Todas as entregas concluídas!',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    var enderecoAtual = widget.rota.enderecos[_paradaAtual];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Próxima Parada',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            enderecoAtual.enderecoCombinado,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abrirNavegador('google', enderecoAtual.coordenadas!),
                  icon: const Icon(Icons.map),
                  label: const Text('Google Maps'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abrirNavegador('waze', enderecoAtual.coordenadas!),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Waze'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proximaParada,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Concluir Entrega'),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirNavegador(String app, LatLng destino) async {
    Uri uri;

    if (app == 'google') {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destino.latitude},${destino.longitude}',
      );
    } else {
      uri = Uri.parse('https://waze.com/ul?ll=${destino.latitude},${destino.longitude}&navigate=yes');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir $app')),
      );
    }
  }

  void _proximaParada() {
    if (_paradaAtual < widget.rota.enderecos.length - 1) {
      setState(() => _paradaAtual++);
      _mapController.move(
        widget.rota.enderecos[_paradaAtual].coordenadas!,
        _mapController.camera.zoom,
      );
    } else {
      setState(() => _paradaAtual = widget.rota.enderecos.length);
    }
  }
}
