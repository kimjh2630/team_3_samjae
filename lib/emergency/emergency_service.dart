import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'emergency_model.dart';
import 'dart:math';

class EmergencyService {
  // 서버의 nearby 데이터 엔드포인트로 변경
  static const String nearbyUrl = 'https://a562-183-109-28-98.ngrok-free.app/api/emergency/nearby';

  // 거리를 km 단위로 변환하는 함수
  static String formatDistance(double? meters) {
    if (meters == null) return '-';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.toStringAsFixed(0)}m';
  }

  static Future<List<EmergencyFacility>> fetchNearbyEmergency({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      final url = Uri.parse('$nearbyUrl?latitude=$latitude&longitude=$longitude&radius=$radius');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('서버 연결 시간이 초과되었습니다.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List items = data['items'] ?? [];
        // 서버에서 이미 반경 및 dutyEryn 필터링이 되어 있으므로, 추가 필터 없이 변환만 수행
        List<EmergencyFacility> facilities = items
            .map((e) => EmergencyFacility.fromJson(e))
            .toList();
        return facilities;
      } else {
        throw Exception('서버 오류:  ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('서버 연결 시간이 초과되었습니다.');
    } catch (e) {
      throw Exception('응급의료기관 정보를 불러오지 못했습니다: $e');
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - (cos((lat2 - lat1) * p) / 2) +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * 1000 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}