import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalizacaoService {
  /// Solicita permissão de localização
  static Future<bool> solicitarPermissao() async {
    PermissionStatus status = await Permission.location.request();
    return status.isGranted;
  }

  /// Verifica se a localização está habilitada
  static Future<bool> verificarLocalizacaoHabilitada() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Obtém a localização atual do dispositivo
  static Future<LatLng?> obterLocalizacaoAtual() async {
    try {
      bool permissao = await solicitarPermissao();
      if (!permissao) {
        throw Exception('Permissão de localização negada');
      }

      bool habilitado = await verificarLocalizacaoHabilitada();
      if (!habilitado) {
        throw Exception('Serviço de localização desabilitado');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Erro ao obter localização: $e');
    }
  }

  /// Stream de atualização de posição em tempo real
  static Stream<LatLng> streamLocalizacao() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (position) => LatLng(position.latitude, position.longitude),
    );
  }

  /// Calcula distância entre dois pontos em metros
  static double calcularDistancia(LatLng origem, LatLng destino) {
    return Geolocator.distanceBetween(
      origem.latitude,
      origem.longitude,
      destino.latitude,
      destino.longitude,
    );
  }

  /// Abre configurações do app
  static Future<void> abrirConfiguracoes() async {
    await openAppSettings();
  }
}
