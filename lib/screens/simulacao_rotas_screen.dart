import 'package:flutter/material.dart';
import '../models/endereco.dart';
import '../services/roteirizacao_service.dart';
import 'mapa_rota_screen.dart';

class SimulacaoRotasScreen extends StatefulWidget {
  final List<Endereco> enderecos;

  const SimulacaoRotasScreen({Key? key, required this.enderecos}) : super(key: key);

  @override
  State<SimulacaoRotasScreen> createState() => _SimulacaoRotasScreenState();
}

class _SimulacaoRotasScreenState extends State<SimulacaoRotasScreen> {
  late List<Endereco> _enderecos;
  bool _simulando = false;
  final List<_SimulacaoRota> _rotas = [];
  int _rotaSelecionada = -1;

  @override
  void initState() {
    super.initState();
    _enderecos = widget.enderecos;
    _gerarRotas();
  }

  void _gerarRotas() async {
    setState(() => _simulando = true);
    _rotas.clear();

    try {
      // Rota 1: Otimizada
      final rotaOtimizada = await RoteirizacaoService.otimizarRota(_enderecos);
      final distOtimizada = RoteirizacaoService.calcularDistanciaTotal(rotaOtimizada);
      _rotas.add(_SimulacaoRota(
        nome: 'Rota Otimizada',
        descricao: 'Melhor eficiência de distância',
        distancia: distOtimizada,
        enderecos: rotaOtimizada,
        cor: Colors.green,
      ));

      // Rota 2: Ordem original
      final distOriginal = RoteirizacaoService.calcularDistanciaTotal(_enderecos);
      _rotas.add(_SimulacaoRota(
        nome: 'Ordem Original',
        descricao: 'Conforme a planilha',
        distancia: distOriginal,
        enderecos: List<Endereco>.from(_enderecos),
        cor: Colors.blue,
      ));

      // Rota 3: Invertida
      final enderecosInvertidos = List<Endereco>.from(_enderecos.reversed);
      final distInvertida = RoteirizacaoService.calcularDistanciaTotal(enderecosInvertidos);
      _rotas.add(_SimulacaoRota(
        nome: 'Ordem Invertida',
        descricao: 'Contrário ao planejado',
        distancia: distInvertida,
        enderecos: enderecosInvertidos,
        cor: Colors.orange,
      ));

      // Ordena por distância
      _rotas.sort((a, b) => a.distancia.compareTo(b.distancia));

      // Seleciona a melhor rota (primeira)
      _rotaSelecionada = 0;

      setState(() => _simulando = false);
    } catch (e) {
      setState(() {
        _simulando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar rotas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Simular Rotas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _simulando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gerando rotas...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header com instruções
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3).withValues(alpha: 0.1),
                        const Color(0xFF1976D2).withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Escolha a melhor rota',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_rotas.length} simulações geradas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de rotas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _rotas.length,
                    itemBuilder: (context, index) {
                      final rota = _rotas[index];
                      final selecionada = _rotaSelecionada == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _rotaSelecionada = index);
                          },
                          child: Card(
                            elevation: selecionada ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: selecionada
                                  ? BorderSide(color: rota.cor, width: 2)
                                  : BorderSide.none,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: selecionada
                                    ? rota.cor.withValues(alpha: 0.1)
                                    : Colors.white,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: rota.cor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rota.nome,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              rota.descricao,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index == 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'MELHOR',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Distância Total',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${rota.distancia.toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1565C0),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Pontos',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              '${rota.enderecos.length}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1565C0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Botão de ação
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _rotaSelecionada >= 0
                            ? () {
                                final rotaSelecionada = _rotas[_rotaSelecionada];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapaRotaScreen(
                                      enderecos: rotaSelecionada.enderecos,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.map, size: 24),
                        label: Text(
                          _rotaSelecionada >= 0
                              ? 'Visualizar no Mapa'
                              : 'Selecione uma rota',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SimulacaoRota {
  final String nome;
  final String descricao;
  final double distancia;
  final List<Endereco> enderecos;
  final Color cor;

  _SimulacaoRota({
    required this.nome,
    required this.descricao,
    required this.distancia,
    required this.enderecos,
    required this.cor,
  });
}
