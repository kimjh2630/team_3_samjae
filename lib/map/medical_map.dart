import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../component/medical_facility.dart';
import '../component/common_naver_map.dart';

class MedicalMapWidget extends StatelessWidget {
  final MedicalFacility facility;
  final Position? currentPosition;

  const MedicalMapWidget({
    required this.facility,
    this.currentPosition,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 현재 위치가 없는 경우: 공통 위젯만 사용
    if (currentPosition == null) {
      double? lat = facility.getLatitude();
      double? lon = facility.getLongitude();

      if (lat == null || lon == null) {
        print('Invalid facility coordinates: ${facility.wgs84Lat}, ${facility.wgs84Lon}');
        return Center(child: Text("locationNotFound".tr()));
      }

      return CommonNaverMap(
        latitude: lat,
        longitude: lon,
        markerLabel: facility.dutyName ?? '이름 없음',
      );
    }

    // 현재 위치가 있는 경우: 커스텀 구현(두 개의 마커)
    double? facilityLat = facility.getLatitude();
    double? facilityLon = facility.getLongitude();

    if (facilityLat == null || facilityLon == null) {
      print('Invalid facility coordinates: ${facility.wgs84Lat}, ${facility.wgs84Lon}');
      return Center(child: Text("cannotDisplayLocationInformation".tr()));
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height / 4,
      child: NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(facilityLat, facilityLon),
            zoom: 15,
          ),
        ),
        onMapReady: (controller) {
          // 의료기관 마커
          final marker = NMarker(
            id: facility.hpid ?? '',
            position: NLatLng(facilityLat, facilityLon),
          );
          marker.setCaption(
            NOverlayCaption(
              text: facility.dutyName ?? '이름 없음',
              textSize: 14,
              color: facility.calculateTodayOpenStatus().contains('운영중') ? Colors.black : Colors.red,
            ),
          );
          controller.addOverlay(marker);

          // 현재 위치 마커
          final currentMarker = NMarker(
            id: 'current_location',
            position: NLatLng(
              currentPosition!.latitude,
              currentPosition!.longitude,
            ),
          );
          currentMarker.setCaption(
            NOverlayCaption(
              text: "currentLocation".tr(),
              textSize: 14,
              color: Colors.blue,
            ),
          );
          controller.addOverlay(currentMarker);
        },
      ),
    );
  }
}