import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import '../models/endereco.dart';
import 'string_formatter.dart';

class GeocodificacaoService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const Duration _delayEntreRequisicoes = Duration(milliseconds: 800);
  static const Duration _timeout = Duration(seconds: 8);
  static const int _requisicoesConcorrentes = 3;

  /// Geocodifica uma lista de endereços com processamento em paralelo
  static Future<List<Endereco>> geocodificarMultiplos(List<Endereco> enderecos) async {
    List<Endereco> resultado = [];
    
    // Processa em lotes para evitar muitas requisições simultâneas
    for (int i = 0; i < enderecos.length; i += _requisicoesConcorrentes) {
      int fim = (i + _requisicoesConcorrentes).clamp(0, enderecos.length);
      List<Endereco> lote = enderecos.sublist(i, fim);
      
      try {
        // Processa até 3 endereços em paralelo
        List<Future<void>> futures = [];
        for (var endereco in lote) {
          futures.add(_geocodificarComTimeout(endereco));
        }
        
        await Future.wait(futures);
        resultado.addAll(lote);
        
        // Pequeno delay entre lotes
        if (fim < enderecos.length) {
          await Future.delayed(_delayEntreRequisicoes);
        }
      } catch (e) {
        resultado.addAll(lote);
      }
    }

    return resultado;
  }

  /// Geocodifica um endereço com timeout
  static Future<void> _geocodificarComTimeout(Endereco endereco) async {
    try {
      LatLng? coords = await geocodificarEndereco(endereco).timeout(
        _timeout,
        onTimeout: () {
          return null;
        },
      );
      endereco.coordenadas = coords;
    } catch (e) {
      // Ignorar erros de geocodificação
    }
  }

  /// Geocodifica um endereço individual
  static Future<LatLng?> geocodificarEndereco(Endereco endereco) async {
    try {
      String query = StringFormatter.montarBuscaNominatim(
        endereco.logradouro,
        endereco.numero,
        endereco.bairro,
        endereco.cidade,
        endereco.uf,
      );

      final uri = Uri.parse('$_nominatimUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '1',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout na geocodificação'),
      );

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);

        if (results.isNotEmpty) {
          double lat = double.parse(results[0]['lat'].toString());
          double lon = double.parse(results[0]['lon'].toString());
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      throw Exception('Erro ao geocodificar: $e');
    }

    return null;
  }
}
