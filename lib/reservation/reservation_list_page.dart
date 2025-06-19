import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/service/reservation_service.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:project/widgets/nav_main_page.dart';
import '../component/medical_facility_detailpage.dart';
import '../models/reservation.dart';
import '../service/social_login.dart';
import 'reservation_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../component/medical_facility.dart';
import 'dart:convert';

/// 병원 예약 페이지 위젯
///
/// 이 페이지는 사용자가 특정 병원에 대한 예약을 생성할 수 있는 UI를 제공합니다.
/// 예약 가능한 날짜와 시간을 선택하고, 로그인 상태를 확인한 후 예약을 완료할 수 있습니다.
class HospitalReservationPage extends StatefulWidget {
  final MedicalFacility facility;
  final DateTime? initialDate;
  final String? initialTime;
  final int? reservationId;

  const HospitalReservationPage({
    Key? key,
    required this.facility,
    this.initialDate,
    this.initialTime,
    this.reservationId,
  }) : super(key: key);

  @override
  _HospitalReservationPageState createState() =>
      _HospitalReservationPageState();
}

class _HospitalReservationPageState extends State<HospitalReservationPage> {
  /// 선택된 예약 날짜
  late DateTime selectedDate;

  /// 선택된 예약 시간
  String? selectedTime;

  /// 예약 가능한 시간 목록
  List<String> availableTimes = [];

  /// 플랫폼 정보
  String? _platform;

  // 언어 번역 기능
  void _showLanguageDialog() {
    showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  @override
  void initState() {
    super.initState();
    // 예약변경이면 초기값 세팅
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate!;
    } else {
      final now = DateTime.now();
      final todayStatus = widget.facility.calculateTodayOpenStatus();
      if (todayStatus.contains('운영종료')) {
        selectedDate = DateTime(now.year, now.month, now.day).add(Duration(days: 1));
      } else {
        selectedDate = DateTime.now();
      }
    }
    selectedTime = widget.initialTime;
    _generateAvailableTimes();
    _loadPlatform();
  }

  Future<void> _loadPlatform() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _platform = prefs.getString('user_platform');
    });
  }

  /// 병원의 영업 시간을 기반으로 예약 가능한 시간 목록을 생성
  ///
  /// 영업 시작 시간부터 종료 시간 1시간 전까지 30분 간격으로 예약 가능한 시간을 생성합니다.
  void _generateAvailableTimes() {
    final openTime = TimeOfDay.fromDateTime(
      DateTime.parse('2024-01-01 ${widget.facility.dutyTime1s ?? '09:00'}'),
    );
    final closeTime = TimeOfDay.fromDateTime(
      DateTime.parse('2024-01-01 ${widget.facility.dutyTime1c ?? '18:00'}'),
    );
    final endTime = TimeOfDay(
      hour: closeTime.hour - 1,
      minute: closeTime.minute,
    );

    availableTimes.clear();
    TimeOfDay currentTime = openTime;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
    while (currentTime.hour < endTime.hour ||
        (currentTime.hour == endTime.hour &&
            currentTime.minute <= endTime.minute)) {
      // 오늘 예약이면 현재시간 이전은 제외
      if (isToday) {
        if (currentTime.hour > now.hour || (currentTime.hour == now.hour && currentTime.minute > now.minute)) {
          availableTimes.add(
            '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
          );
        }
      } else {
        availableTimes.add(
          '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
        );
      }
      currentTime = TimeOfDay(
        hour: currentTime.hour + (currentTime.minute + 30) ~/ 60,
        minute: (currentTime.minute + 30) % 60,
      );
    }
  }

  /// 로그인이 필요한 경우 표시되는 다이얼로그
  ///
  /// 사용자가 로그인하지 않은 상태에서 예약을 시도할 때 호출됩니다.
  void _showLoginRequiredDialog() {
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginWidget()),
                    (route) => false,
              );
            },
            child: Text('login'.tr()),
          ),
        ],
      ),
    );
  }

  /// 예약 확인 및 처리
  ///
  /// 로그인 상태를 확인하고, 선택된 시간이 있는 경우 예약을 생성합니다.
  /// 예약이 완료되면 예약 목록 페이지로 이동합니다.
  Future<void> _showReservationConfirmDialog() async {
    if (!(await AuthService.isLoggedIn())) {
      _showLoginRequiredDialog();
      return;
    }
    if (selectedTime == null) return;
    final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("viewReservationInfo".tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('병원명: ${widget.facility.dutyName ?? ''}'),
            Text('날짜: $dateStr'),
            Text('시간: $selectedTime'),
            const SizedBox(height: 16),
            Text("confirmReservation".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("cancel".tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("reservation.confirm".tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // 1. 회원 userId 조회
      final userInfo = await AuthService.getUserInfo();
      final email = userInfo['email'];
      final platform = userInfo['platform'];
      int? userId;
      if (email != null && platform != null) {
        final response = await AuthService.getUser(email, platform);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          userId = data['id'];
        }
      }
      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      // 2. DB에 예약 정보 저장 (변경/신규 분기)
      if (userId != null) {
        if (widget.reservationId != null) {
          // 예약변경
          await ReservationService.updateReservation(
            reservationId: widget.reservationId!,
            reservationDate: dateStr,
            reservationTime: selectedTime!,
          );
          // 로컬 리스트도 업데이트
          ReservationService.updateReservationLocal(
            widget.reservationId!,
            selectedDate,
            selectedTime!,
          );
        } else {
          // 신규 예약
          final newReservationId = await ReservationService.createReservation(
            userId: userId,
            hospitalId: widget.facility.hpid ?? '',
            hospitalName: widget.facility.dutyName ?? '',
            hospitalAddress: widget.facility.dutyAddr ?? '',
            reservationDate: dateStr,
            reservationTime: selectedTime!,
          );
          if (newReservationId != null) {
            final reservation = Reservation(
              reservationId: newReservationId,
              hospitalName: widget.facility.dutyName ?? '',
              hospitalAddress: widget.facility.dutyAddr ?? '',
              reservationDate: selectedDate,
              reservationTime: selectedTime!,
              userId: userId?.toString() ?? 'temp_user_id',
              hospitalTel: widget.facility.dutyTel1,
              hospitalLat: widget.facility.wgs84Lat,
              hospitalLon: widget.facility.wgs84Lon,
              openTime: widget.facility.dutyTime1s,
              closeTime: widget.facility.dutyTime1c,
              dutyTime1s: widget.facility.dutyTime1s,
              dutyTime2s: widget.facility.dutyTime2s,
              dutyTime3s: widget.facility.dutyTime3s,
              dutyTime4s: widget.facility.dutyTime4s,
              dutyTime5s: widget.facility.dutyTime5s,
              dutyTime6s: widget.facility.dutyTime6s,
              dutyTime7s: widget.facility.dutyTime7s,
              dutyTime8s: widget.facility.dutyTime8s,
              dutyTime1c: widget.facility.dutyTime1c,
              dutyTime2c: widget.facility.dutyTime2c,
              dutyTime3c: widget.facility.dutyTime3c,
              dutyTime4c: widget.facility.dutyTime4c,
              dutyTime5c: widget.facility.dutyTime5c,
              dutyTime6c: widget.facility.dutyTime6c,
              dutyTime7c: widget.facility.dutyTime7c,
              dutyTime8c: widget.facility.dutyTime8c,
              status: '예약완료',
              hospitalId: widget.facility.hpid ?? '',
            );
            ReservationService.addReservation(reservation);
          }
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("reservation.success".tr()),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nav_MainPage(initialIndex: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 비회원 또는 허용되지 않은 플랫폼이면 안내만 노출
    if (_platform != 'local' && _platform != 'google') {
      return Scaffold(
        backgroundColor: Colors.indigo.shade50,
        appBar: AppBar(
          centerTitle: true,
          title: Text('reservation.make'.tr()),
        ),
        body: Center(child: Text('reservation.login_required'.tr())),
      );
    }

    // 오늘 날짜 & 운영종료 상태면 예약 불가 안내 (단, 오늘만 해당)
    final isToday = selectedDate.year == DateTime.now().year && selectedDate.month == DateTime.now().month && selectedDate.day == DateTime.now().day;
    final todayStatus = widget.facility.calculateTodayOpenStatus();
    final isClosedToday = isToday && todayStatus.contains("closed".tr());

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text('reservation.make'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 병원 정보 카드
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.facility.dutyName ?? '',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.facility.dutyAddr ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // 오늘이 운영 종료된 경우 안내 메시지
            if (isClosedToday) ...[
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text("closedForToday".tr(), style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text("selectDifferentDateOrRetry".tr()),
              SizedBox(height: 16),
            ],
            // 날짜 선택 섹션
            Text(
              'reservation.select_date'.tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF4BB8EA), //  선택된 날짜 색상
                  onPrimary: Colors.white, //  선택된 날짜의 텍스트 색상
                ),
              ),
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: (() {
                  final now = DateTime.now();
                  final todayStatus = widget.facility.calculateTodayOpenStatus();
                  // 오늘이 운영 종료면 내일부터 예약 가능
                  if (todayStatus.contains("closed".tr())) {
                    return DateTime(now.year, now.month, now.day).add(Duration(days: 1));
                  }
                  return DateTime.now();
                })(),
                lastDate: DateTime.now().add(Duration(days: 30)),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                    _generateAvailableTimes(); // 날짜 변경 시 시간 목록 재생성
                    selectedTime = null; // 시간 선택 초기화
                  });
                },
                selectableDayPredicate: (date) {
                  final now = DateTime.now();
                  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                  final todayStatus = widget.facility.calculateTodayOpenStatus();
                  // 오늘이면서 운영 종료면 비활성화
                  if (isToday && todayStatus.contains("closed".tr())) {
                    return false;
                  }
                  // 해당 날짜의 요일에 진료시간 정보가 없으면 비활성화
                  int weekday = date.weekday; // 1(월) ~ 7(일)
                  String? startTime;
                  String? endTime;
                  switch (weekday) {
                    case 1:
                      startTime = widget.facility.dutyTime1s;
                      endTime = widget.facility.dutyTime1c;
                      break;
                    case 2:
                      startTime = widget.facility.dutyTime2s;
                      endTime = widget.facility.dutyTime2c;
                      break;
                    case 3:
                      startTime = widget.facility.dutyTime3s;
                      endTime = widget.facility.dutyTime3c;
                      break;
                    case 4:
                      startTime = widget.facility.dutyTime4s;
                      endTime = widget.facility.dutyTime4c;
                      break;
                    case 5:
                      startTime = widget.facility.dutyTime5s;
                      endTime = widget.facility.dutyTime5c;
                      break;
                    case 6:
                      startTime = widget.facility.dutyTime6s;
                      endTime = widget.facility.dutyTime6c;
                      break;
                    case 7:
                      startTime = widget.facility.dutyTime7s;
                      endTime = widget.facility.dutyTime7c;
                      break;
                  }
                  bool isNoInfo = (startTime == null || startTime.isEmpty || startTime == "noInformation".tr()) &&
                      (endTime == null || endTime.isEmpty || endTime == "noInformation".tr());
                  if (isNoInfo) {
                    return false;
                  }
                  return true;
                },
              ),
            ),
            SizedBox(height: 10),
            // 시간 선택 섹션
            Text(
              'reservation.select_time'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children:
              availableTimes.map((time) {
                return ChoiceChip(
                  label: Text(
                    time,
                    style: TextStyle(
                      color:
                      selectedTime == time
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  selected: selectedTime == time,
                  selectedColor: Color(0xFF4BB8EA),
                  checkmarkColor: Colors.white,
                  // backgroundColor: Colors.indigo.shade50,
                  onSelected: (selected) {
                    setState(() {
                      selectedTime = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            // 예약 확인 버튼
            Center(
              child: ElevatedButton(
                onPressed: selectedTime == null ? null : _showReservationConfirmDialog,
                child: Text(
                  'reservation.confirm'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 예약 목록 페이지 위젯
class ReservationListPage extends StatefulWidget {
  @override
  _ReservationListPageState createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  Future<void>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    _fetchFuture = _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    final userInfo = await AuthService.getUserInfo();
    final email = userInfo['email'];
    final platform = userInfo['platform'];
    if (email != null && platform != null) {
      final response = await AuthService.getUser(email, platform);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userId = data['id'];
        await ReservationService.fetchReservationsFromServer(userId);
      }
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ReservationService.reservations;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => nav_MainPage(initialIndex: 0)),
                  (route) => false,
            );
          },
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("reservation_list".tr(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (reservations.isEmpty) {
            return Center(child: Text('reservation.no_reservations'.tr()));
          }
          // 예약 목록 표시
          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return InkWell(
                onTap: () async {
                  final facility = await ReservationService.fetchMedicalFacilityById(reservation.hospitalId);
                  if (facility == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("cannot_load_hospital_details".tr()), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  // 병원정보 fetch 후 주소 동기화
                  if (reservation.hospitalAddress?.isEmpty == true) {
                    setState(() {
                      reservation.hospitalAddress = facility.dutyAddr ?? '';
                    });
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicalFacilityDetailPage(facility: facility),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reservation.hospitalName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          (reservation.hospitalAddress ?? '').isNotEmpty
                              ? reservation.hospitalAddress!
                              : '',
                        ),
                        SizedBox(height: 4),
                        Text('${reservation.reservationDate.toString().split(' ')[0]} ${reservation.reservationTime}'),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                // 예약변경: 병원정보 fetch 후 예약하기 페이지로 이동
                                final facility = await ReservationService.fetchMedicalFacilityById(reservation.hospitalId);
                                if (facility == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("cannot_load_hospital_details".tr()), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HospitalReservationPage(
                                      facility: facility,
                                      initialDate: reservation.reservationDate,
                                      initialTime: reservation.reservationTime,
                                      reservationId: reservation.reservationId,
                                    ),
                                  ),
                                );
                              },
                              child: Text( "change_reservation".tr()),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("cancel_reservation".tr()),
                                    content: Text("reservation.cancellation_confirm".tr()),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("no".tr()),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text("yes".tr()),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final success = await ReservationService.cancelReservation(reservation.reservationId);
                                  if (success && context.mounted) {
                                    ReservationService.removeReservation(reservation);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("reservation_canceled".tr()), backgroundColor: Colors.red),
                                    );
                                    await Future.delayed(const Duration(milliseconds: 500));
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => nav_MainPage(initialIndex: 2)),
                                    );
                                  }
                                }
                              },
                              child: Text( "cancel_reservation".tr(), style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
