import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'endereco.dart';

enum TipoOtimizacao {
  maisCurta,      // Menor distância total
  maisRapida,     // Menor tempo (considera tráfego simulado)
  proximidade,    // Vai sempre para o ponto mais próximo (greedy)
}

class RotaOtimizada {
  final List<Endereco> enderecos;
  final TipoOtimizacao tipo;
  final double distanciaTotal;
  final Duration tempoEstimado;
  final String descricao;
  final LatLng? pontoInicial;

  RotaOtimizada({
    required this.enderecos,
    required this.tipo,
    required this.distanciaTotal,
    required this.tempoEstimado,
    required this.descricao,
    this.pontoInicial,
  });

  String get distanciaFormatada => '${distanciaTotal.toStringAsFixed(1)} km';
  
  String get tempoFormatado {
    int horas = tempoEstimado.inHours;
    int minutos = tempoEstimado.inMinutes.remainder(60);
    
    if (horas > 0) {
      return '${horas}h ${minutos}min';
    }
    return '${minutos}min';
  }

  String get tituloRota {
    switch (tipo) {
      case TipoOtimizacao.maisCurta:
        return 'Rota Mais Curta';
      case TipoOtimizacao.maisRapida:
        return 'Rota Mais Rápida';
      case TipoOtimizacao.proximidade:
        return 'Próximo de Você';
    }
  }

  IconData get icone {
    switch (tipo) {
      case TipoOtimizacao.maisCurta:
        return Icons.route;
      case TipoOtimizacao.maisRapida:
        return Icons.speed;
      case TipoOtimizacao.proximidade:
        return Icons.near_me;
    }
  }
}
