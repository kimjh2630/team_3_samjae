import '../models/reservation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../component/medical_facility.dart';

/// 예약 관리를 위한 서비스 클래스
///
/// 이 클래스는 예약 정보의 CRUD(Create, Read, Update, Delete) 작업을 담당합니다.
/// 현재는 메모리 내에서 예약을 관리하지만, 추후 Firebase Firestore와 연동하여
/// 영구적인 데이터 저장이 가능하도록 확장할 수 있습니다.
class ReservationService {
  /// 예약 정보를 저장하는 내부 리스트
  ///
  /// 현재는 메모리 내에서만 관리되며, 앱이 종료되면 데이터가 초기화됩니다.
  static final List<Reservation> _reservations = [];

  /// 현재 저장된 모든 예약 목록을 반환
  ///
  /// 외부에서 예약 목록을 수정할 수 없도록 불변 리스트로 반환합니다.
  static List<Reservation> get reservations => List.unmodifiable(_reservations);

  /// 새로운 예약을 추가하는 메서드
  ///
  /// [reservation] 추가할 예약 정보
  static void addReservation(Reservation reservation) {
    _reservations.add(reservation);
  }

  /// 기존 예약을 삭제하는 메서드
  ///
  /// [reservation] 삭제할 예약 정보
  static void removeReservation(Reservation reservation) {
    _reservations.remove(reservation);
  }

  /// 특정 사용자의 예약 목록을 조회하는 메서드
  ///
  /// [userId] 조회할 사용자의 ID
  /// Returns: 해당 사용자의 모든 예약 목록
  static List<Reservation> getReservationsByUserId(String userId) {
    return _reservations.where((r) => r.userId == userId).toList();
  }

  static const String baseUrl = 'https://a562-183-109-28-98.ngrok-free.app'; // 실제 서버 주소로 변경

  static Future<int?> createReservation({
    required int userId,
    required String hospitalId,
    required String hospitalName,
    required String hospitalAddress,
    required String reservationDate,
    required String reservationTime,
  }) async {
    final url = Uri.parse('$baseUrl/reservation/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'hospital_id': hospitalId,
        'hospital_name': hospitalName,
        'hospital_address': hospitalAddress,
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['reservationId'] ?? data['id']; // 서버 응답에 따라 키명 확인 필요
    } else {
      print('예약 실패: \\${utf8.decode(response.bodyBytes)}');
      return null;
    }
  }

  static Future<bool> cancelReservation(int reservationId) async {
    final url = Uri.parse('$baseUrl/reservation/$reservationId/cancel');
    final response = await http.patch(url);
    if (response.statusCode == 200) {
      return true;
    } else {
      print('예약 취소 실패: \\${utf8.decode(response.bodyBytes)}');
      return false;
    }
  }

  static Future<bool> updateReservation({
    required int reservationId,
    required String reservationDate,
    required String reservationTime,
  }) async {
    final url = Uri.parse('$baseUrl/reservation/$reservationId/update');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reservation_date': reservationDate,
        'reservation_time': reservationTime,
      }),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print('예약 변경 실패: \\${utf8.decode(response.bodyBytes)}');
      return false;
    }
  }

  static void updateReservationLocal(int reservationId, DateTime newDate, String newTime) {
    final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
    if (index != -1) {
      final old = _reservations[index];
      final reservation = Reservation(
        reservationId: old.reservationId,
        hospitalName: old.hospitalName,
        hospitalAddress: old.hospitalAddress,
        reservationDate: newDate,
        reservationTime: newTime,
        userId: old.userId,
        hospitalTel: old.hospitalTel,
        hospitalLat: old.hospitalLat,
        hospitalLon: old.hospitalLon,
        openTime: old.openTime,
        closeTime: old.closeTime,
        dutyTime1s: old.dutyTime1s,
        dutyTime2s: old.dutyTime2s,
        dutyTime3s: old.dutyTime3s,
        dutyTime4s: old.dutyTime4s,
        dutyTime5s: old.dutyTime5s,
        dutyTime6s: old.dutyTime6s,
        dutyTime7s: old.dutyTime7s,
        dutyTime8s: old.dutyTime8s,
        dutyTime1c: old.dutyTime1c,
        dutyTime2c: old.dutyTime2c,
        dutyTime3c: old.dutyTime3c,
        dutyTime4c: old.dutyTime4c,
        dutyTime5c: old.dutyTime5c,
        dutyTime6c: old.dutyTime6c,
        dutyTime7c: old.dutyTime7c,
        dutyTime8c: old.dutyTime8c,
        status: old.status,
        hospitalId: old.hospitalId,
      );
      _reservations[index] = reservation;
    }
  }

  static Future<void> fetchReservationsFromServer(int userId) async {
    final url = Uri.parse('$baseUrl/reservation/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      print('[DEBUG] 서버에서 받아온 예약 데이터:');
      print(data);
      _reservations.clear();
      final reservations = data.map((e) {
        final r = Reservation.fromJson(e);
        print('[DEBUG] Reservation.fromJson status: \'${r.status}\'');
        return r;
      }).where((r) => r.status == '예약완료').toList();
      _reservations.addAll(reservations);
      print('[DEBUG] 최종 _reservations.length: \'${_reservations.length}\'');
    } else {
      print('예약목록 불러오기 실패: \\${utf8.decode(response.bodyBytes)}');
    }
  }

  static Future<MedicalFacility?> fetchMedicalFacilityById(String hospitalId) async {
    try {
      final url = Uri.parse('$baseUrl/api/medical/$hospitalId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseMap = jsonDecode(utf8.decode(response.bodyBytes));
        final facilityJson = responseMap['item'];
        if (facilityJson != null) {
          return MedicalFacility.fromJson(facilityJson);
        } else {
          print('[ERROR] 병원 정보 없음: hospitalId=$hospitalId');
          return null;
        }
      } else {
        print('[ERROR] 병원 단건 조회 실패: \\${utf8.decode(response.bodyBytes)}');
        return null;
      }
    } catch (e) {
      print('[ERROR] 병원 단건 조회 예외: $e');
      return null;
    }
  }
}