import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Point par défaut : Place Jemaa el-Fna, Marrakech
  static const double fallbackLat = 31.6258;
  static const double fallbackLng = -7.9891;

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Service de localisation désactivé sur l'appareil.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Permission GPS refusée par l'utilisateur.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Permissions GPS refusées de manière permanente.");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint("Erreur lors de la récupération GPS: $e");
      return null;
    }
  }
}
