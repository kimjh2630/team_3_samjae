import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/service/reservation_service.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:project/widgets/nav_main_page.dart';


import '../service/social_login.dart';
import '../component/medical_facility_detailpage.dart';
import '../component/medical_facility.dart';


/// 예약 목록을 표시하는 페이지 위젯
///
/// 이 페이지는 사용자의 모든 예약 정보를 목록 형태로 보여줍니다.
/// 로그인하지 않은 사용자에게는 로그인 요청 화면을 표시하고,
/// 예약이 없는 경우 적절한 메시지를 표시합니다.



class ReservationListPage extends StatelessWidget {

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
        title: Text("reservation.status".tr(),
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
      body: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!) {
            // 로그인 안 된 경우
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('reservation.login_required'.tr()),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginWidget()),
                      );
                    },
                    child: Text('login'.tr()),
                  ),
                ],
              ),
            );
          }
          // 예약이 없는 경우
          if (reservations.isEmpty) {
            return Center(child: Text('reservation.no_reservations'.tr()));
          }
          // 예약 목록 표시
          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(reservation.hospitalName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reservation.hospitalAddress),
                      Text(
                        '${reservation.reservationDate.toString().split(' ')[0]} ${reservation.reservationTime}',
                      ),
                    ],
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text( "reservation.cancel".tr()),
                          content: Text( "reservation.cancellation_confirm".tr()),
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
                        ReservationService.removeReservation(reservation);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("reservation.cancelled".tr()),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          await Future.delayed(const Duration(milliseconds: 500));
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => nav_MainPage(initialIndex: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'reservation.cancel'.tr(),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    // 병원 상세 정보 페이지로 이동
                    final facility = MedicalFacility(
                      dutyName: reservation.hospitalName,
                      dutyAddr: reservation.hospitalAddress,
                      dutyTel1: reservation.hospitalTel,
                      wgs84Lat: reservation.hospitalLat,
                      wgs84Lon: reservation.hospitalLon,
                      dutyTime1s: reservation.dutyTime1s,
                      dutyTime2s: reservation.dutyTime2s,
                      dutyTime3s: reservation.dutyTime3s,
                      dutyTime4s: reservation.dutyTime4s,
                      dutyTime5s: reservation.dutyTime5s,
                      dutyTime6s: reservation.dutyTime6s,
                      dutyTime7s: reservation.dutyTime7s,
                      dutyTime8s: reservation.dutyTime8s,
                      dutyTime1c: reservation.dutyTime1c,
                      dutyTime2c: reservation.dutyTime2c,
                      dutyTime3c: reservation.dutyTime3c,
                      dutyTime4c: reservation.dutyTime4c,
                      dutyTime5c: reservation.dutyTime5c,
                      dutyTime6c: reservation.dutyTime6c,
                      dutyTime7c: reservation.dutyTime7c,
                      dutyTime8c: reservation.dutyTime8c,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalFacilityDetailPage(facility: facility),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}