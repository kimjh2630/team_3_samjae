import 'dart:convert';
import 'dart:math';                             // ← cos, sqrt, asin
import 'package:http/http.dart' as http;
import '../component/medical_facility.dart';
import 'package:geolocator/geolocator.dart';

const _serverApiUrl = 'https://c270-121-172-220-55.ngrok-free.app/api/pharmacy/all';

class PharmacyService {
  static Future<List<MedicalFacility>> fetchNearbyPharmacies(Position position) async {
    final uri = Uri.parse(
        'https://c270-121-172-220-55.ngrok-free.app/api/pharmacy/nearby'
            '?latitude=${position.latitude}&longitude=${position.longitude}&radius=500'
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('pharmacy.api_error');
    }

    final jsonData = json.decode(utf8.decode(resp.bodyBytes));
    final items = jsonData['items'] as List<dynamic>;

    final nearby = <MedicalFacility>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        final fac = MedicalFacility.fromJson(item);
        if (fac.wgs84Lat != null && fac.wgs84Lon != null) {
          final distVal = item['distance'];
          if (distVal is num) {
            fac.distance = distVal.toDouble();
          } else {
            fac.distance = null;
          }
          nearby.add(fac);
        }
      }
    }

    if (nearby.isEmpty) {
      throw Exception('pharmacy.no_nearby');
    }

    nearby.sort((a, b) {
      final da = a.distance ?? double.infinity;
      final db = b.distance ?? double.infinity;
      return da.compareTo(db);
    });
    return nearby;
  }
}
