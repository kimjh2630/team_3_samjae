// 의료기관 상세 정보 화면
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/widgets/language_dialog.dart';
import '../map/route_map_page.dart';
import '../reservation/hospital_reservation_page.dart';

import 'common_naver_map.dart';
import 'medical_facility.dart';
import '../map/medical_map.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import 'naver_directions_button.dart';

class MedicalFacilityDetailPage extends StatelessWidget {
  final MedicalFacility facility;
  final bool fromMainHospitalSearch; // 메인 병원찾기에서 진입한 경우 true

  const MedicalFacilityDetailPage({
    Key? key,
    required this.facility,
    this.fromMainHospitalSearch = false,
  }) : super(key: key);

  // 시간을 'HHMM'에서 'HH:MM' 형식으로 변환 (Flutter 헬퍼 함수)
  String _formatTime(String? time) {
    if (time == null || time.isEmpty || time == "0000" || time == "정보없음") {
      return 'detail.no_info'.tr();
    }
    if (time.length == 4 && int.tryParse(time) != null) {
      return "${time.substring(0, 2)}:${time.substring(2, 4)}";
    }
    if (RegExp(r'^\d{2}:\d{2}\$').hasMatch(time)) {
      return time;
    }
    return 'detail.no_info'.tr();
  }

  Map<String, String> getDutyTimes() {
    final Map<String, String> formattedTimes = {};
    void _addFormattedTime(String day, String? startTime, String? endTime) {
      String formattedStart = _formatTime(startTime);
      String formattedEnd = _formatTime(endTime);
      // 24시간 운영(24:00~24:00 또는 2400~2400)인 경우
      if ((startTime == '2400' || startTime == '24:00') &&
          (endTime == '2400' || endTime == '24:00')) {
        formattedTimes[day] = '24시간 운영';
      } else if (formattedStart == 'detail.no_info'.tr() &&
          formattedEnd == 'detail.no_info'.tr()) {
        formattedTimes[day] = 'detail.no_hours'.tr();
      } else if (formattedStart != 'detail.no_info'.tr() &&
          formattedEnd == 'detail.no_info'.tr()) {
        formattedTimes[day] = "$formattedStart ~ " + 'detail.no_info'.tr();
      } else if (formattedStart == 'detail.no_info'.tr() &&
          formattedEnd != 'detail.no_info'.tr()) {
        formattedTimes[day] = 'detail.no_info'.tr() + " ~ $formattedEnd";
      } else {
        formattedTimes[day] = "$formattedStart ~ $formattedEnd";
      }
    }

    _addFormattedTime('월요일', facility.dutyTime1s, facility.dutyTime1c);
    _addFormattedTime('화요일', facility.dutyTime2s, facility.dutyTime2c);
    _addFormattedTime('수요일', facility.dutyTime3s, facility.dutyTime3c);
    _addFormattedTime('목요일', facility.dutyTime4s, facility.dutyTime4c);
    _addFormattedTime('금요일', facility.dutyTime5s, facility.dutyTime5c);
    _addFormattedTime('토요일', facility.dutyTime6s, facility.dutyTime6c);
    _addFormattedTime('일요일', facility.dutyTime7s, facility.dutyTime7c);
    _addFormattedTime('공휴일', facility.dutyTime8s, facility.dutyTime8c);
    return formattedTimes;
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text('login_required'.tr()),
        content: Text('login_to_reserve'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              // 로그인 화면으로 이동
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('login'.tr()),
          ),
        ],
      ),
    );
  }

  void _navigateToReservationPage(BuildContext context) {
    // 예약 버튼은 항상 노출, 실제 예약 시 로그인 체크
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalReservationPage(facility: facility),
      ),
    );
  }

  //언어 변경 로직
  void _showLanguageDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  @override
  Widget build(BuildContext context) {
    final dutyTimes = getDutyTimes();
    final String finalStatus = facility.finalOpenStatus;
    final bool isOperating = finalStatus.contains('운영중');
    final String displayStatusText = _getTranslatedStatus(finalStatus);
    final Color statusColor = _getStatusColor(finalStatus);

    return Scaffold(
      // backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text("hospitalDetail".tr()),
        // 언어 변경 아이콘
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
            tooltip: 'language_selection'.tr(),
          ),
        ],
        // title: Text(facility.getCleanDutyName() ?? 'detail.no_name'.tr()),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 최상단에 지도 배치
              if (facility.dutyAddr != null &&
                  facility.wgs84Lat != null &&
                  facility.wgs84Lon != null)
                FutureBuilder<Position?>(
                  future: Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return MedicalMapWidget(
                      facility: facility,
                      currentPosition: snapshot.data,
                    );
                  },
                ),
              SizedBox(height: 24),

              // 2. 병원/약국명과 예약 버튼
              Row(
                children: [
                  Expanded(
                    child: Text(
                      facility.getCleanDutyName() ?? 'detail.no_name'.tr(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (fromMainHospitalSearch &&
                      facility.dutyDiv != '약국') // 메인 병원찾기에서만 예약 버튼 표시
                    ElevatedButton.icon(
                      onPressed: () => _navigateToReservationPage(context),
                      icon: Icon(Icons.calendar_today),
                      label: Text('reservation.make'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4BB8EA),
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),

              // 3. 주소
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      facility.dutyAddr ?? 'detail.no_address'.tr(),
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 4. 운영 상태와 전화번호를 카드로 표시
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 운영 상태
                      Row(
                        children: [
                          Icon(
                            isOperating ? Icons.check_circle : Icons.cancel,
                            color: statusColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            displayStatusText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // 전화번호
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey[600], size: 20),
                          SizedBox(width: 8),
                          Text(
                            facility.dutyTel1 ?? 'detail.no_phone'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 5. 길찾기 버튼
              if (facility.dutyAddr != null &&
                  facility.wgs84Lat != null &&
                  facility.wgs84Lon != null)
                NaverDirectionsButton(
                  destLat: double.tryParse(facility.wgs84Lat ?? '') ?? 0.0,
                  destLon: double.tryParse(facility.wgs84Lon ?? '') ?? 0.0,
                  destName:
                  facility.getCleanDutyName() ?? 'detail.no_name'.tr(),
                  destAddr: facility.dutyAddr,
                  height: 56,
                  buttonText: 'detail.directions'.tr(),
                ),
              SizedBox(height: 24),
              // 진료과목 표시
              if (facility.dgidIdName != null &&
                  facility.dgidIdName!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'emergency.subjects'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      facility.dgidIdName!
                          .split(',')
                          .map(
                            (subject) => Chip(
                          label: Text(
                            _translateSubject(subject.trim()),
                            style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.red[50],
                        ),
                      )
                          .toList(),
                    ),
                    SizedBox(height: 24),
                  ],
                ),

              // 6. 운영시간
              Text(
                'detail.weekly_hours'.tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(2),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.grey[200]!),
                    verticalInside: BorderSide(color: Colors.grey[200]!),
                  ),
                  children:
                  dutyTimes.entries.map((e) {
                    return TableRow(
                      decoration: BoxDecoration(color: Colors.white),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            _getTranslatedDay(e.key),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            (e.value == '24시간 운영')
                                ? 'emergency.open_24h'.tr()
                                : (e.value ?? 'detail.no_hours'.tr()),
                            style: TextStyle(
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'detail.basic_info'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              'detail.name'.tr(),
              facility.getCleanDutyName() ?? 'detail.no_name'.tr(),
            ),
            _buildInfoRow(
              'detail.address'.tr(),
              facility.dutyAddr ?? 'detail.no_address'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getTranslatedStatus(String? status) {
    if (status == null) return 'detail.no_status'.tr();
    if (status.contains('운영중')) return 'operating'.tr();
    if (status.contains('운영종료')) return 'closed'.tr();
    if (status.contains('진료준비')) return 'preparing'.tr();
    if (status.contains('휴진')) return 'day_off'.tr();
    if (status.contains('정보 없음')) return 'detail.no_status'.tr();
    return status;
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('운영중')) return Colors.green;
    if (status.contains('운영종료')) return Colors.red;
    return Colors.grey;
  }

  String _getTranslatedDay(String day) {
    switch (day) {
      case '월요일':
        return 'detail.monday'.tr();
      case '화요일':
        return 'detail.tuesday'.tr();
      case '수요일':
        return 'detail.wednesday'.tr();
      case '목요일':
        return 'detail.thursday'.tr();
      case '금요일':
        return 'detail.friday'.tr();
      case '토요일':
        return 'detail.saturday'.tr();
      case '일요일':
        return 'detail.sunday'.tr();
      case '공휴일':
        return 'detail.holiday'.tr();
      default:
        return day;
    }
  }

  String _translateSubject(String subject) {
    // 진료과목 키와 번역 매핑
    final subjectMap = {
      '내과': 'subject_internal',
      '외과': 'subject_surgery',
      '소아과': 'subject_pediatrics',
      '정형외과': 'subject_orthopedics',
      '이비인후과': 'subject_ent',
      '피부과': 'subject_dermatology',
      '안과': 'subject_ophthalmology',
      '신경과': 'subject_neurology',
      '신경외과': 'subject_neurosurgery',
      '산부인과': 'subject_obgyn',
      '비뇨기과': 'subject_urology',
      '정신건강의학과': 'subject_psychiatry',
      '가정의학과': 'subject_family',
      '치과': 'subject_dentistry',
      '한의원': 'subject_oriental',
      '내 주변': 'subject_nearby',
      '구강안면외과': 'subject_dental_surgery',
      '마취통증의학과': 'subject_anesthesiology',
      '방사선종양학과': 'subject_radiology',
      '병리과': 'subject_pathology',
      '비뇨의학과': 'subject_urology',
      '성형외과': 'subject_plastic',
      '소아청소년과': 'subject_pediatric',
      '심장혈관흉부외과': 'subject_cardiology',
      '영상의학과': 'subject_imaging',
      '응급의학과': 'subject_emergency',
      '작업환경의학과': 'subject_occupational',
      '재활의학과': 'subject_rehabilitation',
      '진단검사의학과': 'subject_diagnostic',
      '치과교정과': 'subject_orthodontics',
      '치과보존과': 'subject_prosthodontics',
      '치과소아과': 'subject_pediatric_dentistry',
      '치주과': 'subject_periodontics',
      '핵의학과': 'subject_nuclear',
    };
    if (subjectMap.containsKey(subject)) {
      return subjectMap[subject]!.tr();
    }
    return subject;
  }
}
