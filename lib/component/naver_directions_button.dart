import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NaverDirectionsButton extends StatelessWidget {
  final double destLat;
  final double destLon;
  final String destName;
  final String? destAddr;
  final double width;
  final double height;
  final String buttonText;

  const NaverDirectionsButton({
    Key? key,
    required this.destLat,
    required this.destLon,
    required this.destName,
    this.destAddr,
    this.width = double.infinity,
    this.height = 48,
    this.buttonText = '길찾기',
  }) : super(key: key);

  bool _isValidCoordinate(double lat, double lon) {
    return lat.isFinite && lon.isFinite &&
        lat >= -90 && lat <= 90 &&
        lon >= -180 && lon <= 180;
  }

  Future<bool> _isNaverMapInstalled() async {
    try {
      final Uri naverMapUri = Uri.parse("market://details?id=com.nhn.android.nmap");
      final bool canLaunch = await canLaunchUrl(naverMapUri);
      print('Can launch Naver Map: $canLaunch');
      return canLaunch;
    } catch (e) {
      print('Error checking Naver Map installation: $e');
      return false;
    }
  }

  Future<void> _launchNaverMapApp(BuildContext context, String? startLat, String? startLon, String? startName) async {
    // 좌표값 검증
    if (!_isValidCoordinate(destLat, destLon)) {
      print('Invalid destination coordinates: $destLat, $destLon');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목적지 좌표가 유효하지 않습니다.')),
      );
      return;
    }

    if (startLat != null && startLon != null) {
      if (!_isValidCoordinate(double.parse(startLat), double.parse(startLon))) {
        print('Invalid start coordinates: $startLat, $startLon');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출발지 좌표가 유효하지 않습니다.')),
        );
        return;
      }
    }

    // 도착지 정보 설정
    final destinationName = destAddr ?? destName;
    final destNameEncoded = Uri.encodeComponent(destinationName);
    print('Destination info - Name: $destinationName, Encoded: $destNameEncoded');

    // Intent Scheme URL 생성
    String intentUrl;
    if (startLat != null && startLon != null && startName != null) {
      intentUrl = 'intent://route/car?slat=$startLat&slng=$startLon&sname=$startName&dlat=$destLat&dlng=$destLon&dname=$destNameEncoded&appname=project#Intent;scheme=nmap;package=com.nhn.android.nmap;end;';
    } else {
      intentUrl = 'intent://route/car?dlat=$destLat&dlng=$destLon&dname=$destNameEncoded&appname=project#Intent;scheme=nmap;package=com.nhn.android.nmap;end;';
    }

    print('Launching Naver Map with Intent URL: $intentUrl');

    try {
      await launchUrl(Uri.parse(intentUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('[NaverMap] Intent launch failed: $e');
      // Fallback: 웹 플레이스토어로 이동
      final playStoreWebUrl = 'https://play.google.com/store/apps/details?id=com.nhn.android.nmap';
      try {
        await launchUrl(Uri.parse(playStoreWebUrl), mode: LaunchMode.externalApplication);
      } catch (e2) {
        print('[NaverMap] PlayStore web launch failed: $e2');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네이버 지도 앱/플레이스토어 실행에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _launchNaverMapWeb(BuildContext context, String? startLat, String? startLon, String? startName) async {
    // 좌표값 검증
    if (!_isValidCoordinate(destLat, destLon)) {
      print('Invalid destination coordinates: $destLat, $destLon');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목적지 좌표가 유효하지 않습니다.')),
      );
      return;
    }

    if (startLat != null && startLon != null) {
      if (!_isValidCoordinate(double.parse(startLat), double.parse(startLon))) {
        print('Invalid start coordinates: $startLat, $startLon');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출발지 좌표가 유효하지 않습니다.')),
        );
        return;
      }
    }

    // 도착지 정보 설정
    final destinationName = destAddr ?? destName;
    final destNameEncoded = Uri.encodeComponent(destinationName);
    print('Web - Destination info - Name: $destinationName, Encoded: $destNameEncoded');

    // 네이버 지도 웹 URL 생성
    String webUrl;
    if (startLat != null && startLon != null) {
      webUrl = 'https://map.naver.com/v5/directions/$startLat,$startLon/$destLat,$destLon/car?c=15.0,0,0,0,dh&dname=$destNameEncoded&mode=car';
    } else {
      webUrl = 'https://map.naver.com/v5/directions/$destLat,$destLon/car?c=15.0,0,0,0,dh&dname=$destNameEncoded&mode=car';
    }

    print('Launching web URL: $webUrl');

    try {
      final Uri uri = Uri.parse(webUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching web: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('브라우저 실행에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        icon: Icon(Icons.directions),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            print('Current position: ${position.latitude}, ${position.longitude}');
          } catch (e) {
            print('Error getting position: $e');
            position = null;
          }

          String? startLat;
          String? startLon;
          String? startName;

          if (position != null) {
            // 현재 위치의 정확도를 그대로 유지
            startLat = position.latitude.toString();
            startLon = position.longitude.toString();
            startName = '내 위치';  // 인코딩하지 않음
            print('Start position: $startLat, $startLon');
          }

          // 네이버 지도 앱 실행 시도
          await _launchNaverMapApp(context, startLat, startLon, startName);
        },
      ),
    );
  }
}