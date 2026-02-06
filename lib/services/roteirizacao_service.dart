import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../models/endereco.dart';
import '../models/rota_alternativa.dart';

class RoteirizacaoService {
  static const String _osrmUrl = 'https://router.project-osrm.org/route/v1/driving';
  static const int _maxPontosPorRequisicao = 25;

  /// Gera múltiplas rotas alternativas para o usuário escolher
  static Future<List<RotaAlternativa>> gerarRotasAlternativas(
    LatLng pontoPartida,
    List<Endereco> enderecos,
  ) async {
    final enderecosValidos = enderecos.where((e) => e.coordenadas != null).toList();
    if (enderecosValidos.length < 2) {
      return _gerarRotasFallback(pontoPartida, enderecosValidos);
    }

    List<RotaAlternativa> rotas = [];

    try {
      // Rota 1: Ordem original (sem otimização)
      RotaAlternativa rotaOriginal = await _calcularRota(
        pontoPartida,
        enderecosValidos,
        'Ordem Original',
        'original',
      );
      rotas.add(rotaOriginal);

      // Rota 2: Mais próximos primeiro (Nearest Neighbor)
      List<Endereco> enderecosPorProximidade = _ordenarPorProximidade(pontoPartida, enderecosValidos);
      RotaAlternativa rotaProxima = await _calcularRota(
        pontoPartida,
        enderecosPorProximidade,
        'Mais Próximos',
        'nearest',
      );
      rotas.add(rotaProxima);

      // Rota 3: Otimizada por OSRM (Trip optimization)
      RotaAlternativa rotaOtimizada = await _otimizarComOSRM(pontoPartida, enderecosValidos);
      rotas.add(rotaOtimizada);
    } catch (e) {
      // fallback local se OSRM falhar (CORS/timeout)
      rotas = _gerarRotasFallback(pontoPartida, enderecosValidos);
    }

    if (rotas.isEmpty) {
      rotas = _gerarRotasFallback(pontoPartida, enderecosValidos);
    }

    return rotas;
  }

  static List<RotaAlternativa> _gerarRotasFallback(
    LatLng origem,
    List<Endereco> enderecos,
  ) {
    if (enderecos.isEmpty) return [];

    final original = _rotaLinear(origem, enderecos, 'Rota Padrão', 'fallback');
    final proximos = _rotaLinear(origem, _ordenarPorProximidade(origem, enderecos), 'Mais Próximos', 'fallback-near');
    final reversa = _rotaLinear(origem, enderecos.reversed.toList(), 'Rota Alternativa', 'fallback-reverse');

    return [original, proximos, reversa];
  }

  static RotaAlternativa _rotaLinear(
    LatLng origem,
    List<Endereco> enderecos,
    String nome,
    String algoritmo,
  ) {
    final pontos = <LatLng>[origem, ...enderecos.map((e) => e.coordenadas!)];
    final distancia = _calcularDistanciaPontos(pontos);
    final tempo = _calcularTempo(distancia, 28);

    return RotaAlternativa(
      nome: nome,
      enderecos: enderecos,
      pontos: pontos,
      distanciaTotal: distancia,
      tempoEstimado: tempo,
      algoritmo: algoritmo,
      instrucoes: const [],
    );
  }

  static double _calcularDistanciaPontos(List<LatLng> pontos) {
    const Distance calc = Distance();
    double total = 0;
    for (int i = 0; i < pontos.length - 1; i++) {
      total += calc.as(LengthUnit.Kilometer, pontos[i], pontos[i + 1]);
    }
    return total;
  }

  static int _calcularTempo(double distanciaKm, double velocidadeKmH) {
    final horas = distanciaKm / velocidadeKmH;
    return (horas * 60).round();
  }

  /// Ordena endereços do mais próximo ao mais distante
  static List<Endereco> _ordenarPorProximidade(LatLng origem, List<Endereco> enderecos) {
    List<Endereco> copia = List.from(enderecos);
    const Distance calculator = Distance();

    copia.sort((a, b) {
      double distA = calculator.as(LengthUnit.Meter, origem, a.coordenadas!);
      double distB = calculator.as(LengthUnit.Meter, origem, b.coordenadas!);
      return distA.compareTo(distB);
    });

    return copia;
  }

  /// Calcula rota simples sem otimização
  static Future<RotaAlternativa> _calcularRota(
    LatLng origem,
    List<Endereco> enderecos,
    String nome,
    String algoritmo,
  ) async {
    List<LatLng> pontos = [origem];
    pontos.addAll(enderecos.map((e) => e.coordenadas!));

    String coordenadas = pontos.map((p) => '${p.longitude},${p.latitude}').join(';');

    final uri = Uri.parse('$_osrmUrl/$coordenadas').replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['code'] == 'Ok') {
        double distancia = data['routes'][0]['distance'] / 1000; // km
        int tempo = (data['routes'][0]['duration'] / 60).round(); // minutos

        List<dynamic> coords = data['routes'][0]['geometry']['coordinates'];
        List<LatLng> pontosRota = coords.map((c) => LatLng(c[1], c[0])).toList();

        List<Instrucao> instrucoes = _extrairInstrucoes(data['routes'][0]['legs']);

        return RotaAlternativa(
          nome: nome,
          enderecos: enderecos,
          pontos: pontosRota,
          distanciaTotal: distancia,
          tempoEstimado: tempo,
          algoritmo: algoritmo,
          instrucoes: instrucoes,
        );
      }
    }

    throw Exception('Erro ao calcular rota');
  }

  /// Otimiza rota usando OSRM Trip Service (caixeiro viajante)
  static Future<RotaAlternativa> _otimizarComOSRM(
    LatLng origem,
    List<Endereco> enderecos,
  ) async {
    List<LatLng> pontos = [origem];
    pontos.addAll(enderecos.map((e) => e.coordenadas!));

    String coordenadas = pontos.map((p) => '${p.longitude},${p.latitude}').join(';');

    // Usa o serviço /trip para otimização TSP
    final uri = Uri.parse('http://router.project-osrm.org/trip/v1/driving/$coordenadas').replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'true',
        'source': 'first', // Começa do primeiro ponto (origem)
        'roundtrip': 'false', // Não volta ao início
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['code'] == 'Ok') {
        double distancia = data['trips'][0]['distance'] / 1000;
        int tempo = (data['trips'][0]['duration'] / 60).round();

        List<dynamic> coords = data['trips'][0]['geometry']['coordinates'];
        List<LatLng> pontosRota = coords.map((c) => LatLng(c[1], c[0])).toList();

        // Reordena endereços conforme otimização
        List<int> waypoints = (data['waypoints'] as List)
            .map((w) => w['waypoint_index'] as int)
            .toList();

        List<Endereco> enderecosOrdenados = [];
        for (int i = 1; i < waypoints.length; i++) {
          enderecosOrdenados.add(enderecos[waypoints[i] - 1]);
        }

        List<Instrucao> instrucoes = _extrairInstrucoes(data['trips'][0]['legs']);

        return RotaAlternativa(
          nome: 'Rota Otimizada',
          enderecos: enderecosOrdenados,
          pontos: pontosRota,
          distanciaTotal: distancia,
          tempoEstimado: tempo,
          algoritmo: 'osrm-trip',
          instrucoes: instrucoes,
        );
      }
    }

    throw Exception('Erro ao otimizar rota');
  }

  /// Extrai instruções turn-by-turn da resposta OSRM
  static List<Instrucao> _extrairInstrucoes(List<dynamic> legs) {
    List<Instrucao> instrucoes = [];

    for (var leg in legs) {
      for (var step in leg['steps']) {
        String maneuver = step['maneuver']['type'];
        String modifier = step['maneuver']['modifier'] ?? '';
        double distance = step['distance'];
        List<dynamic> location = step['maneuver']['location'];

        String texto = _traduzirManobra(maneuver, modifier, distance);

        instrucoes.add(Instrucao(
          texto: texto,
          coordenada: LatLng(location[1], location[0]),
          tipo: maneuver,
          distancia: distance,
        ));
      }
    }

    return instrucoes;
  }

  /// Traduz manobras OSRM para português
  static String _traduzirManobra(String maneuver, String modifier, double distance) {
    String distStr = distance > 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.round()} m';

    switch (maneuver) {
      case 'turn':
        if (modifier.contains('left')) return 'Vire à esquerda em $distStr';
        if (modifier.contains('right')) return 'Vire à direita em $distStr';
        return 'Vire em $distStr';
      case 'new name':
        return 'Continue em frente por $distStr';
      case 'depart':
        return 'Siga em frente por $distStr';
      case 'arrive':
        return 'Você chegou ao destino';
      case 'merge':
        return 'Entre na via em $distStr';
      case 'roundabout':
        return 'Entre na rotatória em $distStr';
      default:
        return 'Continue por $distStr';
    }
  }

  /// Calcula distância total da rota em km
  static double calcularDistanciaTotal(List<Endereco> enderecos) {
    double distancia = 0;
    const Distance distanceCalculator = Distance();

    for (int i = 0; i < enderecos.length - 1; i++) {
      if (enderecos[i].coordenadas != null && enderecos[i + 1].coordenadas != null) {
        distancia += distanceCalculator.as(
          LengthUnit.Kilometer,
          enderecos[i].coordenadas!,
          enderecos[i + 1].coordenadas!,
        );
      }
    }

    return distancia;
  }
}
