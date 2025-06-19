/// 예약 정보를 담는 모델 클래스
/// 
/// 이 클래스는 병원 예약 시스템에서 사용되는 예약 정보를 관리합니다.
/// 각 예약은 병원 이름, 주소, 예약 날짜, 예약 시간, 사용자 ID를 포함합니다.
class Reservation {
  /// 병원의 이름
  final String hospitalName;

  /// 병원의 주소
  String? hospitalAddress;

  /// 예약 날짜 (DateTime 형식)
  final DateTime reservationDate;

  /// 예약 시간 (문자열 형식, 예: "14:30")
  final String reservationTime;

  /// 예약한 사용자의 고유 ID
  final String userId;

  /// 병원의 전화번호
  final String? hospitalTel;

  /// 병원의 위도
  final String? hospitalLat;

  /// 병원의 경도
  final String? hospitalLon;

  /// 병원의 운영시간 (시작)
  final String? openTime;

  /// 병원의 운영시간 (종료)
  final String? closeTime;

  /// 병원의 요일별 운영시간 (시작)
  final String? dutyTime1s;
  final String? dutyTime2s;
  final String? dutyTime3s;
  final String? dutyTime4s;
  final String? dutyTime5s;
  final String? dutyTime6s;
  final String? dutyTime7s;
  final String? dutyTime8s;

  /// 병원의 요일별 운영시간 (종료)
  final String? dutyTime1c;
  final String? dutyTime2c;
  final String? dutyTime3c;
  final String? dutyTime4c;
  final String? dutyTime5c;
  final String? dutyTime6c;
  final String? dutyTime7c;
  final String? dutyTime8c;

  /// 예약 고유 id
  final int reservationId;

  /// 예약 상태 (예: '예약완료', '취소')
  final String status;

  /// 병원의 ID
  final String hospitalId;

  /// Reservation 클래스의 생성자
  ///
  /// [hospitalName] 병원 이름
  /// [hospitalAddress] 병원 주소
  /// [reservationDate] 예약 날짜
  /// [reservationTime] 예약 시간
  /// [userId] 사용자 ID
  /// [hospitalTel] 병원 전화번호
  /// [hospitalLat] 병원 위도
  /// [hospitalLon] 병원 경도
  /// [openTime] 병원 운영시간 (시작)
  /// [closeTime] 병원 운영시간 (종료)
  /// [dutyTime1s] 병원 요일별 운영시간 (시작)
  /// [dutyTime2s] 병원 요일별 운영시간 (시작)
  /// [dutyTime3s] 병원 요일별 운영시간 (시작)
  /// [dutyTime4s] 병원 요일별 운영시간 (시작)
  /// [dutyTime5s] 병원 요일별 운영시간 (시작)
  /// [dutyTime6s] 병원 요일별 운영시간 (시작)
  /// [dutyTime7s] 병원 요일별 운영시간 (시작)
  /// [dutyTime8s] 병원 요일별 운영시간 (시작)
  /// [dutyTime1c] 병원 요일별 운영시간 (종료)
  /// [dutyTime2c] 병원 요일별 운영시간 (종료)
  /// [dutyTime3c] 병원 요일별 운영시간 (종료)
  /// [dutyTime4c] 병원 요일별 운영시간 (종료)
  /// [dutyTime5c] 병원 요일별 운영시간 (종료)
  /// [dutyTime6c] 병원 요일별 운영시간 (종료)
  /// [dutyTime7c] 병원 요일별 운영시간 (종료)
  /// [dutyTime8c] 병원 요일별 운영시간 (종료)
  /// [reservationId] 예약 고유 id
  /// [status] 예약 상태
  /// [hospitalId] 병원 ID
  Reservation({
    required this.reservationId,
    required this.hospitalName,
    this.hospitalAddress,
    required this.reservationDate,
    required this.reservationTime,
    required this.userId,
    this.hospitalTel,
    this.hospitalLat,
    this.hospitalLon,
    this.openTime,
    this.closeTime,
    this.dutyTime1s,
    this.dutyTime2s,
    this.dutyTime3s,
    this.dutyTime4s,
    this.dutyTime5s,
    this.dutyTime6s,
    this.dutyTime7s,
    this.dutyTime8s,
    this.dutyTime1c,
    this.dutyTime2c,
    this.dutyTime3c,
    this.dutyTime4c,
    this.dutyTime5c,
    this.dutyTime6c,
    this.dutyTime7c,
    this.dutyTime8c,
    required this.status,
    required this.hospitalId,
  });

  /// 예약 정보를 JSON 형식으로 변환하는 메서드
  ///
  /// Firebase Firestore에 데이터를 저장할 때 사용됩니다.
  /// 날짜는 ISO 8601 형식의 문자열로 변환됩니다.
  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'reservationDate': reservationDate.toIso8601String(),
      'reservationTime': reservationTime,
      'userId': userId,
      'hospitalTel': hospitalTel,
      'hospitalLat': hospitalLat,
      'hospitalLon': hospitalLon,
      'openTime': openTime,
      'closeTime': closeTime,
      'dutyTime1s': dutyTime1s,
      'dutyTime2s': dutyTime2s,
      'dutyTime3s': dutyTime3s,
      'dutyTime4s': dutyTime4s,
      'dutyTime5s': dutyTime5s,
      'dutyTime6s': dutyTime6s,
      'dutyTime7s': dutyTime7s,
      'dutyTime8s': dutyTime8s,
      'dutyTime1c': dutyTime1c,
      'dutyTime2c': dutyTime2c,
      'dutyTime3c': dutyTime3c,
      'dutyTime4c': dutyTime4c,
      'dutyTime5c': dutyTime5c,
      'dutyTime6c': dutyTime6c,
      'dutyTime7c': dutyTime7c,
      'dutyTime8c': dutyTime8c,
      'status': status,
      'hospitalId': hospitalId,
    };
  }

  /// JSON 데이터로부터 Reservation 객체를 생성하는 팩토리 메서드
  ///
  /// Firebase Firestore에서 데이터를 읽어올 때 사용됩니다.
  /// ISO 8601 형식의 날짜 문자열을 DateTime 객체로 변환합니다.
  factory Reservation.fromJson(Map<String, dynamic> json) {
    print('[DEBUG] Reservation.fromJson json:');
    print(json);
    print('[DEBUG] Reservation.fromJson status 필드: \'${json['status']}\'');
    return Reservation(
      reservationId: json['reservationId'] ?? json['id'] ?? 0,
      hospitalName: json['hospitalName'] ?? json['hospital_name'] ?? '',
      hospitalAddress: json['hospitalAddress'] ?? json['hospital_address'],
      reservationDate: DateTime.parse(json['reservationDate'] ?? json['reservation_date']),
      reservationTime: json['reservationTime'] ?? json['reservation_time'] ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      hospitalTel: json['hospitalTel'] ?? json['hospital_tel'],
      hospitalLat: json['hospitalLat'] ?? json['hospital_lat'],
      hospitalLon: json['hospitalLon'] ?? json['hospital_lon'],
      openTime: json['openTime'] ?? json['open_time'],
      closeTime: json['closeTime'] ?? json['close_time'],
      dutyTime1s: json['dutyTime1s'] ?? json['duty_time1s'],
      dutyTime2s: json['dutyTime2s'] ?? json['duty_time2s'],
      dutyTime3s: json['dutyTime3s'] ?? json['duty_time3s'],
      dutyTime4s: json['dutyTime4s'] ?? json['duty_time4s'],
      dutyTime5s: json['dutyTime5s'] ?? json['duty_time5s'],
      dutyTime6s: json['dutyTime6s'] ?? json['duty_time6s'],
      dutyTime7s: json['dutyTime7s'] ?? json['duty_time7s'],
      dutyTime8s: json['dutyTime8s'] ?? json['duty_time8s'],
      dutyTime1c: json['dutyTime1c'] ?? json['duty_time1c'],
      dutyTime2c: json['dutyTime2c'] ?? json['duty_time2c'],
      dutyTime3c: json['dutyTime3c'] ?? json['duty_time3c'],
      dutyTime4c: json['dutyTime4c'] ?? json['duty_time4c'],
      dutyTime5c: json['dutyTime5c'] ?? json['duty_time5c'],
      dutyTime6c: json['dutyTime6c'] ?? json['duty_time6c'],
      dutyTime7c: json['dutyTime7c'] ?? json['duty_time7c'],
      dutyTime8c: json['dutyTime8c'] ?? json['duty_time8c'],
      status: json['status'] ?? '예약완료',
      hospitalId: json['hospitalId'] ?? json['hospital_id'] ?? '',
    );
  }
} 