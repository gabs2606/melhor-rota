import 'package:latlong2/latlong.dart';
import 'endereco.dart';

class RotaAlternativa {
  final String nome;
  final List<Endereco> enderecos;
  final List<LatLng> pontos;
  final double distanciaTotal;
  final int tempoEstimado;
  final String algoritmo;
  final List<Instrucao> instrucoes;

  RotaAlternativa({
    required this.nome,
    required this.enderecos,
    required this.pontos,
    required this.distanciaTotal,
    required this.tempoEstimado,
    required this.algoritmo,
    this.instrucoes = const [],
  });

  String get tempoFormatado {
    int horas = tempoEstimado ~/ 60;
    int minutos = tempoEstimado % 60;
    if (horas > 0) {
      return '${horas}h ${minutos}min';
    }
    return '${minutos}min';
  }

  String get distanciaFormatada => '${distanciaTotal.toStringAsFixed(1)} km';
}

class Instrucao {
  final String texto;
  final LatLng coordenada;
  final String tipo;
  final double distancia;

  Instrucao({
    required this.texto,
    required this.coordenada,
    required this.tipo,
    required this.distancia,
  });
}
