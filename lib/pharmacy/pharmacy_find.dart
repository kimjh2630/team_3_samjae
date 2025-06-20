import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../component/medical_facility.dart';
import 'pharmacy_nearbyfind.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:provider/provider.dart';
import '../state/app_state.dart';

// 서버 API 엔드포인트 (예시: 로컬 개발 환경)
const String serverApiUrl = 'https://c270-121-172-220-55.ngrok-free.app/api/pharmacy/all';

// 두 지점 간 거리를 미터 단위로 계산하는 함수 (Haversine 공식)
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295; // Math.PI / 180
  var c = cos; // cos 함수를 사용하기 위해 임포트 필요
  var a = 0.5 - c((lat2 - lat1) * p)/2 +
      c(lat1 * p) * c(lat2 * p) *
          (1 - c((lon2 - lon1) * p))/2;
  return 1000 * 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

class PharmacyFindPage extends StatefulWidget {
  const PharmacyFindPage({Key? key}) : super(key: key);

  @override
  _PharmacyFindPageState createState() => _PharmacyFindPageState();
}

class _PharmacyFindPageState extends State<PharmacyFindPage> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      final data = await _initializeData();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NearbyMedicalMapWidget(
            currentPosition: data['position'],
            facilities: data['pharmacies'],
            title: 'pharmacy.nearby',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NearbyMedicalMapWidget(
      currentPosition: context.read<AppState>().position!,
      facilities: context.read<AppState>().pharmacies ?? [],
      title: 'pharmacy.nearby',
    );
  }

  Future<Map<String, dynamic>> _initializeData() async {
    try {
      // 1. 위치 권한 확인 > 오래걸림
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('location_permission_denied'.tr());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('location_permission_denied_forever'.tr());
      }

      // 2. 현재 위치 가져오기 > 오래걸림.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. 약국 데이터 가져오기 (서버 API 호출)
      final url = Uri.parse(serverApiUrl);
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('pharmacy.api_error'.tr());
      }

      List<MedicalFacility> allPharmacies = [];
      try {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final items = jsonData['items'] as List<dynamic>;
        allPharmacies = items.map((item) {
          // 서버에서 내려주는 필드명에 맞게 매핑
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          return MedicalFacility.fromJson(itemMap);
        }).toList();
      } catch (e) {
        throw Exception('pharmacy.parse_error'.tr());
      }

      // 4. 500m 이내 약국 필터링 > 반복문 내부에 거리계산
      List<MedicalFacility> nearbyPharmacies = allPharmacies.where((facility) {
        if (facility.wgs84Lat != null && facility.wgs84Lon != null) {
          try {
            final double lat = double.parse(facility.wgs84Lat!);
            final double lon = double.parse(facility.wgs84Lon!);
            final double distance = calculateDistance(
              position.latitude,
              position.longitude,
              lat,
              lon,
            );
            facility.distance = distance;
            return distance <= 500;
          } catch (e) {
            return false;
          }
        }
        return false;
      }).toList();

      if (nearbyPharmacies.isEmpty) {
        throw Exception('pharmacy.no_nearby'.tr());
      }

      // 5. 거리순 정렬
      nearbyPharmacies.sort((a, b) =>
          (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

      return {
        'position': position,
        'pharmacies': nearbyPharmacies,
      };
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}