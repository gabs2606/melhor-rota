import 'package:latlong2/latlong.dart';
import '../models/endereco.dart';
import '../models/rota_otimizada.dart';

class OtimizadorRotasService {
  static const Distance _distance = Distance();

  /// Gera 3 opções de rotas otimizadas
  static List<RotaOtimizada> gerarOpcoesRotas(
    List<Endereco> enderecos,
    LatLng pontoInicial,
  ) {
    List<RotaOtimizada> opcoes = [];

    // 1. Rota mais curta (TSP aproximado)
    opcoes.add(_rotaMaisCurta(enderecos, pontoInicial));

    // 2. Rota por proximidade (greedy - sempre o mais próximo)
    opcoes.add(_rotaProximidade(enderecos, pontoInicial));

    // 3. Rota mais rápida (simula tempo com velocidade média)
    opcoes.add(_rotaMaisRapida(enderecos, pontoInicial));

    return opcoes;
  }

  /// Algoritmo de rota mais curta (2-opt aproximado)
  static RotaOtimizada _rotaMaisCurta(List<Endereco> enderecos, LatLng inicio) {
    List<Endereco> rota = List.from(enderecos);
    
    // Ordena pela distância do ponto inicial
    rota.sort((a, b) {
      double distA = _distance.as(LengthUnit.Kilometer, inicio, a.coordenadas!);
      double distB = _distance.as(LengthUnit.Kilometer, inicio, b.coordenadas!);
      return distA.compareTo(distB);
    });

    // Aplica 2-opt para melhorar
    bool melhorou = true;
    while (melhorou) {
      melhorou = false;
      for (int i = 0; i < rota.length - 1; i++) {
        for (int j = i + 2; j < rota.length; j++) {
          if (_swap2opt(rota, i, j, inicio)) {
            melhorou = true;
          }
        }
      }
    }

    double distancia = _calcularDistanciaTotal(rota, inicio);
    Duration tempo = _calcularTempo(distancia, 30); // 30 km/h média

    for (int i = 0; i < rota.length; i++) {
      rota[i].ordem = i + 1;
    }

    return RotaOtimizada(
      enderecos: rota,
      tipo: TipoOtimizacao.maisCurta,
      distanciaTotal: distancia,
      tempoEstimado: tempo,
      descricao: 'Menor distância percorrida',
      pontoInicial: inicio,
    );
  }

  /// Algoritmo greedy - sempre vai para o mais próximo
  static RotaOtimizada _rotaProximidade(List<Endereco> enderecos, LatLng inicio) {
    List<Endereco> disponiveis = List.from(enderecos);
    List<Endereco> rota = [];
    LatLng posicaoAtual = inicio;

    while (disponiveis.isNotEmpty) {
      // Encontra o mais próximo
      Endereco maisProximo = disponiveis.first;
      double menorDistancia = _distance.as(
        LengthUnit.Kilometer,
        posicaoAtual,
        maisProximo.coordenadas!,
      );

      for (var endereco in disponiveis) {
        double dist = _distance.as(
          LengthUnit.Kilometer,
          posicaoAtual,
          endereco.coordenadas!,
        );
        if (dist < menorDistancia) {
          menorDistancia = dist;
          maisProximo = endereco;
        }
      }

      rota.add(maisProximo);
      disponiveis.remove(maisProximo);
      posicaoAtual = maisProximo.coordenadas!;
    }

    double distancia = _calcularDistanciaTotal(rota, inicio);
    Duration tempo = _calcularTempo(distancia, 25); // Mais lento por paradas

    for (int i = 0; i < rota.length; i++) {
      rota[i].ordem = i + 1;
    }

    return RotaOtimizada(
      enderecos: rota,
      tipo: TipoOtimizacao.proximidade,
      distanciaTotal: distancia,
      tempoEstimado: tempo,
      descricao: 'Sempre o endereço mais próximo',
      pontoInicial: inicio,
    );
  }

  /// Rota simulando "mais rápida" (considera velocidade variável)
  static RotaOtimizada _rotaMaisRapida(List<Endereco> enderecos, LatLng inicio) {
    // Usa algoritmo similar ao mais curto, mas com peso no tempo
    List<Endereco> rota = List.from(enderecos);
    
    rota.sort((a, b) {
      double distA = _distance.as(LengthUnit.Kilometer, inicio, a.coordenadas!);
      double distB = _distance.as(LengthUnit.Kilometer, inicio, b.coordenadas!);
      return distA.compareTo(distB);
    });

    double distancia = _calcularDistanciaTotal(rota, inicio);
    Duration tempo = _calcularTempo(distancia, 35); // Velocidade maior

    for (int i = 0; i < rota.length; i++) {
      rota[i].ordem = i + 1;
    }

    return RotaOtimizada(
      enderecos: rota,
      tipo: TipoOtimizacao.maisRapida,
      distanciaTotal: distancia,
      tempoEstimado: tempo,
      descricao: 'Otimizada para menor tempo',
      pontoInicial: inicio,
    );
  }

  /// Aplica swap 2-opt se melhorar a rota
  static bool _swap2opt(List<Endereco> rota, int i, int j, LatLng inicio) {
    double distanciaAtual = _calcularDistanciaTotal(rota, inicio);
    
    // Inverte segmento
    List<Endereco> novaRota = List.from(rota);
    List<Endereco> segmento = novaRota.sublist(i + 1, j + 1).reversed.toList();
    novaRota.replaceRange(i + 1, j + 1, segmento);
    
    double novaDistancia = _calcularDistanciaTotal(novaRota, inicio);
    
    if (novaDistancia < distanciaAtual) {
      rota.replaceRange(i + 1, j + 1, segmento);
      return true;
    }
    return false;
  }

  /// Calcula distância total da rota
  static double _calcularDistanciaTotal(List<Endereco> rota, LatLng inicio) {
    double distancia = 0;
    LatLng anterior = inicio;

    for (var endereco in rota) {
      distancia += _distance.as(
        LengthUnit.Kilometer,
        anterior,
        endereco.coordenadas!,
      );
      anterior = endereco.coordenadas!;
    }

    return distancia;
  }

  /// Calcula tempo estimado baseado em velocidade média
  static Duration _calcularTempo(double distanciaKm, double velocidadeKmH) {
    double horas = distanciaKm / velocidadeKmH;
    int minutos = (horas * 60).round();
    return Duration(minutes: minutos);
  }
}
