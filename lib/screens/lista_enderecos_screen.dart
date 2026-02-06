import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/endereco.dart';
import '../services/localizacao_service.dart';
import 'selecao_rotas_screen.dart';

class ListaEnderecosScreen extends StatefulWidget {
  final List<Endereco> enderecos;

  const ListaEnderecosScreen({Key? key, required this.enderecos}) : super(key: key);

  @override
  State<ListaEnderecosScreen> createState() => _ListaEnderecosScreenState();
}

class _ListaEnderecosScreenState extends State<ListaEnderecosScreen> {
  late List<Endereco> _enderecos;
  bool _carregandoLocalizacao = false;

  @override
  void initState() {
    super.initState();
    _enderecos = widget.enderecos;
  }

  void _iniciarNavegacao() async {
    setState(() => _carregandoLocalizacao = true);

    try {
      // Solicita permissão e obtém localização
      LatLng? localizacao = await LocalizacaoService.obterLocalizacaoAtual();

      if (localizacao == null) {
        throw Exception('Não foi possível obter sua localização');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelecaoRotasScreen(
              enderecos: _enderecos,
              localizacaoAtual: localizacao,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              onPressed: _iniciarNavegacao,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregandoLocalizacao = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Endereços Carregados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_enderecos.length} endereços carregados',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vamos usar sua localização atual como ponto de partida',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _enderecos.length,
              itemBuilder: (context, index) {
                final endereco = _enderecos[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(endereco.logradouro),
                  subtitle: Text(endereco.enderecoCombinado),
                  trailing: endereco.coordenadas != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _carregandoLocalizacao ? null : _iniciarNavegacao,
                icon: _carregandoLocalizacao
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.navigation),
                label: Text(
                  _carregandoLocalizacao ? 'Obtendo localização...' : 'Iniciar Navegação',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
