import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'emergency_service.dart';
import 'emergency_model.dart';
import '../component/medical_facility_detailpage.dart';
import 'package:easy_localization/easy_localization.dart';

class EmergencyMapPage extends StatefulWidget {
  const EmergencyMapPage({Key? key}) : super(key: key);

  @override
  State<EmergencyMapPage> createState() => _EmergencyMapPageState();
}

class _EmergencyMapPageState extends State<EmergencyMapPage> {
  Position? _currentPosition;
  List<EmergencyFacility> _facilities = [];
  Set<NMarker> _markers = {};
  NaverMapController? _mapController;
  bool _loading = true;
  String? _errorMessage;
  bool _isListVisible = false;
  final double _radius = 5000; // 5km 반경

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  Future<void> _initLocationAndFetch() async {
    try {
      final appState = context.read<AppState>();
      Position? pos = appState.position;

      // 위치 정보가 없는 경우에만 새로 가져오기
      if (pos == null) {
        LocationPermission permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _loading = false;
            _errorMessage = '위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.';
          });
          return;
        }

        pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        appState.position = pos;
      }

      setState(() => _currentPosition = pos);

      // 응급의료기관 데이터 가져오기
      List<EmergencyFacility> facilities = [];
      try {
        facilities = await EmergencyService.fetchNearbyEmergency(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (e) {
        print('응급의료기관 데이터 로드 실패: $e');
      }

      // 마커 생성
      final markers = facilities
          .where((f) => f.wgs84Lat != null && f.wgs84Lon != null)
          .map((f) {
        double lat = double.parse(f.wgs84Lat!);
        double lon = double.parse(f.wgs84Lon!);
        return NMarker(
          id: f.hpid ?? f.dutyName ?? '',
          position: NLatLng(lat, lon),
        )
          ..setCaption(NOverlayCaption(
            text: f.dutyName ?? '',
            textSize: 14,
            color: Colors.red,
          ));
      }).toSet();

      if (mounted) {
        setState(() {
          _facilities = facilities;
          _markers = markers;
          _loading = false;
          _errorMessage = facilities.isEmpty ? 'emergency.no_facility'.tr() : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _getTranslatedStatus(String status) {
    if (status.contains('운영중')) return 'operating'.tr();
    if (status.contains('운영종료')) return 'closed'.tr();
    if (status.contains('운영 시간 정보 없음')) return 'detail.no_hours'.tr();
    return status;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('emergency.nearby'.tr())),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('emergency.nearby'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage!.contains('권한')
                    ? '위치 권한이 필요합니다.\n설정에서 권한을 허용해 주세요.'
                    : _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initLocationAndFetch,
                icon: Icon(Icons.refresh),
                label: Text('재시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('emergency.nearby'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('detail.no_location'.tr()),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initLocationAndFetch,
                child: Text("retry".tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('emergency.nearby'.tr()),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 12,
              ),
              scrollGesturesEnable: true,
              zoomGesturesEnable: true,
              tiltGesturesEnable: true,
              rotationGesturesEnable: true,
              stopGesturesEnable: true,
              locationButtonEnable: true,
            ),
            onMapReady: (controller) {
              _mapController = controller;

              // 현재 위치 마커 추가
              final currentMarker = NMarker(
                id: 'current_location',
                position: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              )..setCaption(NOverlayCaption(
                text: "currentLocation".tr(),
                textSize: 14,
                color: Colors.blue,
              ));
              controller.addOverlay(currentMarker);

              // 반경 원 추가
              final circle = NCircleOverlay(
                id: 'radius_circle',
                center: NLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                radius: _radius,
                color: Colors.red.withOpacity(0.1),
                outlineColor: Colors.red,
                outlineWidth: 2,
              );
              controller.addOverlay(circle);

              // 응급의료기관 마커 추가
              _markers.forEach((marker) {
                marker.setOnTapListener((overlay) {
                  final facility = _facilities.firstWhere(
                        (f) => (f.hpid ?? f.dutyName ?? '') == marker.info.id,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicalFacilityDetailPage(facility: facility.toMedicalFacility(), fromMainHospitalSearch: false),
                    ),
                  );
                });
                controller.addOverlay(marker);
              });
            },
          ),

          //---------------
          // 응급의료기관이 주변에 없을때 메시지 표시
          if (_facilities.isEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'emergency.no_facility'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 하단에 응급의료기관 목록 표시
          if (_isListVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 지도 보기 버튼 (목록 바로 위)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        setState(() {
                          _isListVisible = false;
                        });
                      },
                      label: Text('emergency.view_map'.tr()),
                      icon: Icon(Icons.map),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height / 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 드래그 핸들
                        Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'emergency.list'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '${_facilities.length}${'emergency.count'.tr()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _facilities.isEmpty
                              ? Center(
                            child: Text('emergency.no_facility'.tr()),
                          )
                              : ListView.builder(
                            itemCount: _facilities.length,
                            itemBuilder: (context, idx) {
                              final f = _facilities[idx];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.local_hospital,
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    f.dutyName ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Text(
                                        f.dutyAddr ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            f.calculateTodayOpenStatus().contains('운영중') ? 'operating'.tr() : _getTranslatedStatus(f.calculateTodayOpenStatus()),
                                            style: TextStyle(
                                              color: f.calculateTodayOpenStatus().contains('운영중') ? Colors.green[800] : Colors.red[800],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            EmergencyService.formatDistance(f.distance),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (f.calculateTodayOpenStatus().contains('운영중') ? Colors.green[50] : Colors.red[50]),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      f.calculateTodayOpenStatus().contains('운영중') ? 'emergency.open_24h'.tr() : _getTranslatedStatus(f.calculateTodayOpenStatus()),
                                      style: TextStyle(
                                        color: (f.calculateTodayOpenStatus().contains('운영중') ? Colors.green[800] : Colors.red[800]),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MedicalFacilityDetailPage(facility: f.toMedicalFacility(), fromMainHospitalSearch: false),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 목록 보기 버튼
          if (!_isListVisible)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.extended(
                    onPressed: () {
                      setState(() {
                        _isListVisible = true;
                      });
                    },
                    label: Text('emergency.view_list'.tr()),
                    icon: Icon(Icons.list),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}