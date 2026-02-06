import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

class NavegacaoService {
  /// Abre Google Maps com navegação
  static Future<bool> abrirGoogleMaps(LatLng destino, String endereco) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destino.latitude},${destino.longitude}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Abre Waze com navegação
  static Future<bool> abrirWaze(LatLng destino) async {
    final url = Uri.parse(
      'https://waze.com/ul?ll=${destino.latitude},${destino.longitude}&navigate=yes',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Abre navegação padrão do dispositivo
  static Future<bool> abrirNavegacaoPadrao(LatLng destino) async {
    final url = Uri.parse(
      'geo:${destino.latitude},${destino.longitude}?q=${destino.latitude},${destino.longitude}',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
