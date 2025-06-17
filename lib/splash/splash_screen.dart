// lib/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:project/component/medical_facility.dart';
import 'package:project/hospital/hospital_search_result_page.dart';
import 'package:project/pharmacy/pharmacy_find.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../service/social_login.dart'; // ← LoginWidget 정의된 곳
import '../service/location_service.dart';
import '../service/pharmacy_service.dart';
import '../state/app_state.dart';
import '../emergency/emergency_service.dart';
import '../emergency/emergency_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
          cos(_toRadians(lat1)) *
              cos(_toRadians(lat2)) *
              sin(dLon / 2) *
              sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degree) => degree * pi / 180;

Future<T> retry<T>(Future<T> Function() fn, {int retries = 3, Duration delay = const Duration(seconds: 1)}) async {
  int attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      attempt++;
      if (attempt >= retries) rethrow;
      await Future.delayed(delay);
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1) .env 로드
      await dotenv.load(fileName: ".env");

      // 2) SDK 초기화
      final naverId = dotenv.env['NAVER_MAP_CLIENT_ID']!;
      final kakaoKey = dotenv.env['KAKAO_SDK_APP_KEY']!;
      FlutterNaverMap().init(
        clientId: naverId,
        onAuthFailed: (e) => debugPrint('NaverMap Auth Failed: $e'),
      );
      KakaoSdk.init(nativeAppKey: kakaoKey);

      // 3) 위치 권한 요청
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
      }

      // 4) 현재 위치 획득
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('위치 측정 타임아웃'),
      );
      context.read<AppState>().position = pos;

      // 5) 약국, 병원, 응급의료기관 데이터 미리 불러오기 (재시도 로직 적용)
      List<MedicalFacility> pharmacies = [];
      List<MedicalFacility> hospitals = [];
      List<EmergencyFacility> emergencyFacilities = [];
      Map<String, List<MedicalFacility>> subjectData = {};
      http.Response? hospitalResp;

      // 5-1) 약국
      try {
        debugPrint('약국 데이터 요청 시작');
        final result = await retry(() => PharmacyService.fetchNearbyPharmacies(pos));
        pharmacies = List<MedicalFacility>.from(result);
        debugPrint('약국 데이터 성공');
      } catch (e) {
        debugPrint('약국 데이터 에러: $e');
        rethrow;
      }

      // 5-2) 병원
      try {
        debugPrint('병원 데이터 요청 시작');
        hospitalResp = await retry(() => http.get(
          Uri.parse(
            '$apiBase/api/medical/nearby?latitude=${pos.latitude}&longitude=${pos.longitude}&radius=10000&type=hospital',
          ),
        ).timeout(
          Duration(seconds: 10),
          onTimeout: () => http.Response('{"items":[],"total_count":0}', 200),
        ));
        debugPrint('병원 데이터 성공');
      } catch (e) {
        debugPrint('병원 데이터 에러: $e');
        rethrow;
      }

      // 5-3) 응급
      try {
        debugPrint('응급 데이터 요청 시작');
        final result = await retry(() => EmergencyService.fetchNearbyEmergency(
          latitude: pos.latitude,
          longitude: pos.longitude,
        ).timeout(Duration(seconds: 10), onTimeout: () => <EmergencyFacility>[]));
        emergencyFacilities = List<EmergencyFacility>.from(result);
        debugPrint('응급 데이터 성공');
      } catch (e) {
        debugPrint('응급 데이터 에러: $e');
        rethrow;
      }

      // 5-4) 진료과목별
      final List<String> subjectKeys = [
        'subject_internal',
        'subject_surgery',
        'subject_pediatrics',
        'subject_orthopedics',
        'subject_ent',
        'subject_dermatology',
        'subject_ophthalmology',
        'subject_neurology',
        'subject_neurosurgery',
        'subject_obgyn',
        'subject_urology',
        'subject_psychiatry',
        'subject_family',
        'subject_dentistry',
        'subject_oriental',
      ];
      for (final subject in subjectKeys) {
        try {
          debugPrint('진료과목 $subject 데이터 요청 시작');
          final resp = await retry(() => http.get(
            Uri.parse(
              '$apiBase/api/medical/search?QN=$subject&page_no=1&num_of_rows=25&latitude=${pos.latitude}&longitude=${pos.longitude}',
            ),
          ).timeout(
            Duration(seconds: 10),
            onTimeout: () => http.Response('{"items":[],"total_count":0}', 200),
          ));
          debugPrint('진료과목 $subject 데이터 성공');
          if (resp.statusCode == 200) {
            final data = json.decode(utf8.decode(resp.bodyBytes));
            final List items = data['items'] as List? ?? [];
            final subjectHospitals = List<MedicalFacility>.from(items.map((e) => MedicalFacility.fromJson(e)));
            // 거리 계산 및 정렬
            for (var h in subjectHospitals) {
              final lat = double.tryParse(h.wgs84Lat ?? '');
              final lon = double.tryParse(h.wgs84Lon ?? '');
              if (lat != null && lon != null) {
                h.distance = calculateDistance(
                  pos.latitude,
                  pos.longitude,
                  lat,
                  lon,
                );
              } else {
                h.distance = double.infinity;
              }
            }
            final sortedSubjectHospitals = List<MedicalFacility>.from(subjectHospitals);
            sortedSubjectHospitals.sort((a, b) {
              final da = a.distance ?? double.infinity;
              final db = b.distance ?? double.infinity;
              return da.compareTo(db);
            });
            subjectData[subject] = sortedSubjectHospitals;
          }
        } catch (e) {
          debugPrint('진료과목 $subject 데이터 에러: $e');
        }
      }

      // 6) 데이터 처리
      // 6-1) 약국 데이터 처리
      // (이미 pharmacies에 있음)

      // 6-2) 병원 데이터 처리
      final hospitalData = json.decode(utf8.decode(hospitalResp!.bodyBytes));
      final List items = hospitalData['items'] as List? ?? [];
      hospitals = List<MedicalFacility>.from(items.map((e) => MedicalFacility.fromJson(e)));

      // 6-3) 응급의료기관 데이터 처리
      // (이미 emergencyFacilities에 있음)

      // 6-4) 진료과목별 데이터 처리
      // (이미 subjectData에 있음)

      // 6-5) 거리 계산
      for (var h in hospitals) {
        final lat = double.tryParse(h.wgs84Lat ?? '');
        final lon = double.tryParse(h.wgs84Lon ?? '');
        if (lat != null && lon != null) {
          h.distance = calculateDistance(pos.latitude, pos.longitude, lat, lon);
        } else {
          h.distance = double.infinity;
        }
      }

      // 6-6) 오름차순 정렬
      final sortedHospitals = List<MedicalFacility>.from(hospitals);
      sortedHospitals.sort((a, b) {
        final da = a.distance ?? double.infinity;
        final db = b.distance ?? double.infinity;
        return da.compareTo(db);
      });
      hospitals = sortedHospitals;

      if (!mounted) return;

      // 7) 데이터 저장
      final appState = context.read<AppState>();
      appState.pharmacies = pharmacies;
      appState.hospitals = hospitals;
      appState.subjectHospitals = subjectData;
      appState.emergencyFacilities = emergencyFacilities;

      // 8) 잠깐 대기
      await Future.delayed(const Duration(milliseconds: 300));

      // 9) 로그인 화면으로 이동
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginWidget()));
    } catch (e) {
      debugPrint('Splash init error: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
          title: Text('error'.tr()),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginWidget()),
                );
              },
              child: Text('ok'.tr()),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/aidoc_logo.png',
                  width: 250,
                  height: 250,
                ),
                CircularProgressIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
