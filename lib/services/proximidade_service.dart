import 'package:latlong2/latlong.dart';
import '../models/endereco.dart';

class ProximidadeService {
  static const double _raioProximidade = 50.0; // metros

  /// Verifica se o usuário está próximo de um endereço
  static bool estaProximo(LatLng posicaoAtual, LatLng destino) {
    const Distance calculator = Distance();
    double distancia = calculator.as(
      LengthUnit.Meter,
      posicaoAtual,
      destino,
    );
    return distancia <= _raioProximidade;
  }

  /// Encontra o próximo endereço não entregue mais próximo
  static Endereco? encontrarProximoDestino(
    LatLng posicaoAtual,
    List<Endereco> enderecos,
  ) {
    const Distance calculator = Distance();
    
    // Filtra apenas endereços não entregues
    List<Endereco> naoEntregues = enderecos.where((e) => !e.entregue).toList();
    
    if (naoEntregues.isEmpty) return null;

    // Encontra o mais próximo
    Endereco maisProximo = naoEntregues.first;
    double menorDistancia = calculator.as(
      LengthUnit.Meter,
      posicaoAtual,
      maisProximo.coordenadas!,
    );

    for (var endereco in naoEntregues.skip(1)) {
      double distancia = calculator.as(
        LengthUnit.Meter,
        posicaoAtual,
        endereco.coordenadas!,
      );
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        maisProximo = endereco;
      }
    }

    return maisProximo;
  }

  /// Calcula distância até o destino em metros
  static double calcularDistancia(LatLng origem, LatLng destino) {
    const Distance calculator = Distance();
    return calculator.as(LengthUnit.Meter, origem, destino);
  }

  /// Formata distância para exibição
  static String formatarDistancia(double metros) {
    if (metros >= 1000) {
      return '${(metros / 1000).toStringAsFixed(1)} km';
    }
    return '${metros.round()} m';
  }
}
