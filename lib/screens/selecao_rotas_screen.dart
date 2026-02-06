import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/endereco.dart';
import '../models/rota_otimizada.dart';
import '../services/otimizador_rotas_service.dart';
import 'mapa_rota_screen.dart';

class SelecaoRotasScreen extends StatefulWidget {
  final List<Endereco> enderecos;
  final LatLng localizacaoAtual;

  const SelecaoRotasScreen({
    Key? key,
    required this.enderecos,
    required this.localizacaoAtual,
  }) : super(key: key);

  @override
  State<SelecaoRotasScreen> createState() => _SelecaoRotasScreenState();
}

class _SelecaoRotasScreenState extends State<SelecaoRotasScreen> {
  List<RotaAlternativa>? _opcoesRotas;
  bool _carregando = true;
  int _rotaSelecionada = 0;

  void initState() {
    super.initState();e();
    _gerarRotas(); _gerarRotas();
  }  }

  void _gerarRotas() async {
    setState(() => _carregando = true);    setState(() => _carregando = true);

    try {
      List<RotaOtimizada> opcoes = OtimizadorRotasService.gerarOpcoesRotas( opcoes = OtimizadorRotasService.gerarOpcoesRotas(
        widget.enderecos,
        widget.localizacaoAtual,widget.localizacaoAtual,
      );      );

      setState(() {
        _opcoesRotas = opcoes;s;
        _carregando = false;carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar rotas: $e')),SnackBar(content: Text('Erro ao gerar rotas: $e')),
      ); );
    } }
  }  }

  @override
  Widget build(BuildContext context) {Context context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha sua Rota'),Text('Escolha sua Rota'),
        elevation: 0,elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())())
          : _opcoesRotas == null || _opcoesRotas!.isEmpty
              ? const Center(child: Text('Nenhuma rota disponível'))enter(child: Text('Nenhuma rota disponível'))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.shade50,terMap(
                      child: Row(pOptions(
                        children: [tos.first,
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              children: [eName: 'melhor_rota',
                                const Text(
                                  'Sua localização atual',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),nes: [
                                ),e(
                                Text(
                                  '${widget.localizacaoAtual.latitude.toStringAsFixed(4)}, ${widget.localizacaoAtual.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),lor: Colors.blue.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),onst EdgeInsets.all(16),
                      child: Text(
                        'Selecione a melhor opção para você:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  final rota = _opcoesRotas![index];
                      ),    return Card(
                    ),levation: 2,
                    Expanded(
                      child: ListView.builder( index),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _opcoesRotas!.length,
                        itemBuilder: (context, index) {
                          return _buildRotaCard(_opcoesRotas![index]);      onChanged: (v) => setState(() => _rotaSelecionada = v ?? 0),
                        },      ),
                      ),        title: Text(rota.nome),
                    ),          subtitle: Text('${rota.tempoFormatado} • ${rota.distanciaFormatada} • ${rota.enderecos.length} paradas'),
                  ],            trailing: const Icon(Icons.chevron_right),
                ),                      ),
    );                       );
  }                        },

  Widget _buildRotaCard(RotaOtimizada rota) {    ),
    return Card(
      margin: const EdgeInsets.only(bottom: 16),   padding: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),   width: double.infinity,
      child: InkWell(on.icon(
        onTap: () => _selecionarRota(rota),cionarRota(_opcoesRotas![_rotaSelecionada]),
        borderRadius: BorderRadius.circular(12),   icon: const Icon(Icons.navigation),
        child: Padding('Iniciar rota'),
          padding: const EdgeInsets.all(16),),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(rota.icone, color: Colors.blue, size: 28),ntext) => MapaRotaScreen(
                  ),
                  const SizedBox(width: 16), widget.localizacaoAtual,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rota.tituloRota,                          style: const TextStyle(                            fontSize: 18,                            fontWeight: FontWeight.bold,                          ),                        ),                        const SizedBox(height: 4),                        Text(                          rota.descricao,                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),                        ),                      ],                    ),                  ),                ],              ),              const Divider(height: 24),              Row(                mainAxisAlignment: MainAxisAlignment.spaceAround,                children: [                  _buildInfoChip(                    Icons.straighten,                    rota.distanciaFormatada,                    'Distância',                  ),                  _buildInfoChip(                    Icons.access_time,                    rota.tempoFormatado,                    'Tempo estimado',                  ),                  _buildInfoChip(                    Icons.flag,                    '${rota.enderecos.length}',                    'Paradas',                  ),                ],              ),            ],          ),        ),      ),    );  }  Widget _buildInfoChip(IconData icon, String valor, String label) {    return Column(      children: [        Icon(icon, color: Colors.blue, size: 20),        const SizedBox(height: 4),        Text(          valor,          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),        ),        Text(          label,          style: TextStyle(fontSize: 11, color: Colors.grey[600]),        ),      ],    );  }  void _selecionarRota(RotaOtimizada rota) {    Navigator.push(      context,      MaterialPageRoute(        builder: (context) => MapaRotaScreen(          enderecos: rota.enderecos,          localizacaoAtual: widget.localizacaoAtual,        ),      ),    );  }}
