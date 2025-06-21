import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project/widgets/language_dialog.dart';
import '../component/medical_facility.dart';
import '../component/medical_facility_detailpage.dart';
import 'package:easy_localization/easy_localization.dart'
;

class NearbyMedicalMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<MedicalFacility> facilities;
  final String title;

  const NearbyMedicalMapWidget({
    required this.currentPosition,
    required this.facilities,
    this.title = 'pharmacy.nearby',
    Key? key,
  }) : super(key: key);

  @override
  _NearbyMedicalMapWidgetState createState() => _NearbyMedicalMapWidgetState();
}

class _NearbyMedicalMapWidgetState extends State<NearbyMedicalMapWidget> {
  NaverMapController? _mapController;
  final double _radius = 500; // 500m 반경
  bool _isListVisible = false; // 약국 목록 표시 상태

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => const LanguageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {

    //위치 기본 좌표 추가.
    final defaultLat = 37.542908;
    final defaultLon = 126.677074;

    // 2) 실제로 사용할 중심 좌표 결정
    final centerLat = widget.currentPosition?.latitude ?? defaultLat;
    final centerLon = widget.currentPosition?.longitude ?? defaultLon;

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
              widget.title.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.language),
              onPressed: _showLanguageDialog,
              tooltip: 'language_selection'.tr(),
            ),
          ],
          backgroundColor: Color(0xFF67BD7D),
      ),
      body: SafeArea(
    bottom: true,
    child: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                // null이면 defaultLatLng 사용
                target: NLatLng(
                  centerLat,
                  centerLon,
                  // widget.currentPosition.latitude,
                  // widget.currentPosition.longitude,
                ),
                zoom: 14, // 500m 반경이 잘 보이도록 줌 레벨 설정 (필요에 따라 조정, 15가 적절할 수 있습니다)
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
                position: NLatLng(
                  centerLat,
                  centerLon,
                  // widget.currentPosition.latitude,
                  // widget.currentPosition.longitude,
                ),
              );
              currentMarker.setCaption(
                NOverlayCaption(
                  text: 'pharmacy.current_location'.tr(),
                  textSize: 14,
                  color: Colors.black87,
                ),
              );
              controller.addOverlay(currentMarker);

              // 반경 원 추가
              final circle = NCircleOverlay(
                id: 'radius_circle',
                center: NLatLng(
                  centerLat,
                  centerLon,
                  // widget.currentPosition.latitude,
                  // widget.currentPosition.longitude,
                ),
                radius: _radius,
                color: Colors.green.withOpacity(0.1),
                outlineColor: Colors.green,
                outlineWidth: 2,
              );
              controller.addOverlay(circle);

              // 약국 마커 추가
              for (var facility in widget.facilities) {
                if (facility.wgs84Lat != null && facility.wgs84Lon != null) {
                  final marker = NMarker(
                    id: facility.hpid ?? '',
                    position: NLatLng(
                      double.parse(facility.wgs84Lat!),
                      double.parse(facility.wgs84Lon!),
                    ),
                  );

                  // 마커 캡션 색상 조건부 표시 -> 항상 검은색으로 변경
                  // calculateTodayOpenStatus 결과를 가져와서 마커 이미지 결정에 사용
                  final String calculatedStatus =
                  facility.calculateTodayOpenStatus();
                  final bool isOperating = calculatedStatus.contains('운영중');

                  marker.setCaption(
                    NOverlayCaption(
                      text: facility.getCleanDutyName() ?? 'pharmacy.no_name'.tr(),
                      textSize: 14,
                      // 약국 이름은 항상 검은색으로 표시
                      color: Colors.black,
                    ),
                  );
                  marker.setOnTapListener((overlay) {
                    // <-- 이 부분이 추가되었습니다.
                    // 마커 탭 시 상세 정보 페이지로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                            MedicalFacilityDetailPage(facility: facility, fromMainHospitalSearch: false),
                      ),
                    );
                  });
                  controller.addOverlay(marker);
                }
              }
            },
          ),

          // 하단에 약국 목록 표시
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
                      label: Text('pharmacy.view_map'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),),
                      icon: Icon(Icons.map),
                      backgroundColor: Color(0xFF67BD7D),
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
                                'pharmacy.list'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF67BD7D),
                                ),
                              ),
                              Text(
                                '${widget.facilities.length}${'pharmacy.count'.tr()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.facilities.length,
                            itemBuilder: (context, index) {
                              final facility = widget.facilities[index];
                              final String calculatedStatus = facility.calculateTodayOpenStatus();
                              final bool isOperating = calculatedStatus.contains('운영중');
                              final Color statusColor = isOperating
                                  ? Colors.green
                                  : calculatedStatus.contains('운영종료')
                                  ? Colors.red
                                  : Colors.grey;

                              // 영업 상태 텍스트 번역
                              String translatedStatus = '';
                              if (calculatedStatus.contains('운영중')) {
                                translatedStatus = 'operating'.tr();
                              } else if (calculatedStatus.contains('운영종료')) {
                                translatedStatus = 'closed'.tr();
                              } else {
                                translatedStatus = 'detail.no_hours'.tr();
                              }

                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.local_pharmacy,
                                      color: statusColor,
                                    ),
                                  ),
                                  title: Text(
                                    facility.getCleanDutyName() ?? 'pharmacy.no_name'.tr(),
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
                                        facility.dutyAddr ?? 'pharmacy.no_address'.tr(),
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            translatedStatus,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            // 거리 표시 (PharmacyService.formatDistance 사용)
                                            facility.distance != null ? '${(facility.distance! >= 1000 ? (facility.distance! / 1000).toStringAsFixed(1) + 'km' : facility.distance!.toStringAsFixed(0) + 'm')}' : '-',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MedicalFacilityDetailPage(
                                          facility: facility,
                                          fromMainHospitalSearch: false,
                                        ),
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

          // 목록이 숨겨져 있을 때 하단에 목록 보기 버튼
          if (!_isListVisible)
            Positioned(
              bottom: 16.0,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  onPressed: () {
                    setState(() {
                      _isListVisible = !_isListVisible;
                    });
                  },
                  label: Text('pharmacy.view_list'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),),
                  icon: Icon(Icons.list),
                  backgroundColor: Color(0xFF67BD7D),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}