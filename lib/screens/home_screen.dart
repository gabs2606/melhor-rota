import 'package:flutter/material.dart';
import '../models/endereco.dart';
import '../services/csv_service.dart';
import '../services/geocodificacao_service.dart';
import 'lista_enderecos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _carregando = false;
  String _mensagem = '';

  void _importarPlanilha() async {
    setState(() => _carregando = true);

    try {
      List<Endereco> enderecos = await CsvService.importarPlanilha();

      if (enderecos.isEmpty) {
        setState(() {
          _mensagem = 'Nenhum endereço encontrado na planilha';
          _carregando = false;
        });
        return;
      }

      // Mostra progresso
      setState(() => _mensagem = 'Geocodificando ${enderecos.length} endereços...');

      // Geocodifica endereços
      List<Endereco> enderecosComCoord = await GeocodificacaoService.geocodificarMultiplos(enderecos);

      if (enderecosComCoord.isEmpty) {
        setState(() {
          _mensagem = 'Não foi possível geocodificar nenhum endereço';
          _carregando = false;
        });
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListaEnderecosScreen(enderecos: enderecosComCoord),
          ),
        );
      }
    } catch (e) {
      setState(() => _mensagem = 'Erro: ${e.toString()}');
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _mostrarAjuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formatos Suportados'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✅ Formatos aceitos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• CSV (.csv)'),
              Text('• Excel (.xlsx, .xls)'),
              Text('• OpenDocument (.ods)'),
              SizedBox(height: 16),
              Text(
                '📋 Colunas necessárias:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Logradouro (obrigatório)'),
              Text('• Cidade (obrigatório)'),
              Text('• Número (opcional)'),
              Text('• Bairro (opcional)'),
              Text('• UF/Estado (opcional)'),
              SizedBox(height: 16),
              Text(
                '💡 Dica:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'O cabeçalho pode usar qualquer nome similar (rua, avenida, município, etc.)',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Melhor Rota'),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFEAF3FF), const Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 64 : 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Melhor Rota',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'apenas 9,99!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        _HeroCard(
                          isWide: isWide,
                          carregando: _carregando,
                          onImportar: _importarPlanilha,
                          mensagem: _mensagem,
                        ),
                        _PainelInfo(isWide: isWide),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ApoioInfo(isWide: isWide),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isWide;
  final bool carregando;
  final VoidCallback onImportar;
  final String mensagem;

  const _HeroCard({
    required this.isWide,
    required this.carregando,
    required this.onImportar,
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'image/unnamed-Photoroom (5) (1).png',
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Otimize suas entregas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Importe sua planilha e visualize rotas inteligentes antes de iniciar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: carregando ? null : onImportar,
                icon: carregando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(carregando ? 'Processando...' : 'Importar Planilha Shopee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            if (mensagem.isNotEmpty) ... [
              const SizedBox(height: 12),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mensagem.contains('Erro') ? Colors.red : Colors.blueGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PainelInfo extends StatelessWidget {
  final bool isWide;

  const _PainelInfo({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
      child: Column(
        children: const [
          _InfoTile(icon: Icons.upload_file, title: 'Importe', subtitle: 'CSV, XLSX, XLS, ODS'),
          SizedBox(height: 12),
          _InfoTile(icon: Icons.route, title: 'Otimize', subtitle: 'Rotas inteligentes'),
          SizedBox(height: 12),
          _InfoTile(icon: Icons.map, title: 'Pré-visualize', subtitle: 'Mapa antes de iniciar'),
          SizedBox(height: 12),
          _InfoTile(icon: Icons.navigation, title: 'Navegue', subtitle: 'Waze/Google'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEAF3FF),
            child: Icon(icon, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApoioInfo extends StatelessWidget {
  final bool isWide;

  const _ApoioInfo({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Expanded(
              child: Text(
                'Rotas inteligentes com visual profissional e navegação fluida.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.bolt, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
