import 'package:latlong2/latlong.dart';

class Endereco {
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String uf;
  LatLng? coordenadas;
  int? ordem;
  bool entregue;

  Endereco({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.uf,
    this.coordenadas,
    this.ordem,
    this.entregue = false,
  });

  String get enderecoCombinado =>
      '$logradouro, $numero, $bairro, $cidade - $uf';

  String get enderecoBuscaFormatado =>
      '$logradouro $numero $bairro $cidade $uf';

  @override
  String toString() => enderecoCombinado;
}
