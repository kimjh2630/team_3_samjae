import '../component/medical_facility.dart';

class EmergencyFacility {
  final String? hpid;
  final String? dutyName;
  final String? dutyTel1;
  final String? dutyAddr;
  final String? wgs84Lat;
  final String? wgs84Lon;
  final String? dgidIdName;
  final double? distance;
  final String? dutyEryn;

  // 응급의료기관 상세 정보
  final String? hvec;  // 응급실
  final String? hvoc;  // 수술실
  final String? hvcc;  // 중환자실
  final String? hvncc;  // 신생아중환자실
  final String? hvccc;  // 흉부중환자실
  final String? hvicc;  // 내과중환자실
  final String? hvgc;  // 일반병상
  final String? MKioskTy25; // 응급실 여부

  EmergencyFacility({
    this.hpid,
    this.dutyName,
    this.dutyTel1,
    this.dutyAddr,
    this.wgs84Lat,
    this.wgs84Lon,
    this.dgidIdName,
    this.distance,
    this.hvec,
    this.hvoc,
    this.hvcc,
    this.hvncc,
    this.hvccc,
    this.hvicc,
    this.hvgc,
    this.MKioskTy25,
    this.dutyEryn,
  });

  factory EmergencyFacility.fromJson(Map<String, dynamic> json) {
    String? getStringValue(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      return str.isEmpty ? null : str;
    }
    return EmergencyFacility(
      hpid: getStringValue(json['hpid']),
      dutyName: getStringValue(json['dutyName']),
      dutyTel1: getStringValue(json['dutyTel1']),
      dutyAddr: getStringValue(json['dutyAddr']),
      wgs84Lat: getStringValue(json['wgs84Lat']),
      wgs84Lon: getStringValue(json['wgs84Lon']),
      dgidIdName: getStringValue(json['dgidIdName']),
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      dutyEryn: getStringValue(json['dutyEryn']),
      hvec: getStringValue(json['hvec']),
      hvoc: getStringValue(json['hvoc']),
      hvcc: getStringValue(json['hvcc']),
      hvncc: getStringValue(json['hvncc']),
      hvccc: getStringValue(json['hvccc']),
      hvicc: getStringValue(json['hvicc']),
      hvgc: getStringValue(json['hvgc']),
      MKioskTy25: getStringValue(json['MKioskTy25']),
    );
  }

  // MedicalFacility로 변환하는 메서드
  MedicalFacility toMedicalFacility() {
    // 필수 정보가 없는 경우 로그 출력
    if (dutyName == null || dutyTel1 == null || wgs84Lat == null || wgs84Lon == null) {
      print('Warning: Converting EmergencyFacility with missing information:');
      print('HPID: $hpid');
      print('Name: $dutyName');
      print('Tel: $dutyTel1');
      print('Coordinates: $wgs84Lat, $wgs84Lon');
      print('Emergency Info:');
      print('- ER: $hvec');
      print('- OR: $hvoc');
      print('- ICU: $hvcc');
      print('- NICU: $hvncc');
      print('- CCU: $hvccc');
      print('- MICU: $hvicc');
      print('- General Beds: $hvgc');
    }

    // 응급의료기관 상세 정보를 설명에 포함
    String description = '응급의료기관 정보\n';
    if ((hvec?.isNotEmpty ?? false)) description += '응급실: $hvec\n';
    if ((hvoc?.isNotEmpty ?? false)) description += '수술실: $hvoc\n';
    if ((hvcc?.isNotEmpty ?? false)) description += '중환자실: $hvcc\n';
    if ((hvncc?.isNotEmpty ?? false)) description += '신생아중환자실: $hvncc\n';
    if ((hvccc?.isNotEmpty ?? false)) description += '흉부중환자실: $hvccc\n';
    if ((hvicc?.isNotEmpty ?? false)) description += '내과중환자실: $hvicc\n';
    if ((hvgc?.isNotEmpty ?? false)) description += '일반병상: $hvgc\n';

    // 기본값 설정
    final defaultName = (dutyName?.isNotEmpty ?? false) ? dutyName! : '이름 없음';
    final defaultTel = (dutyTel1?.isNotEmpty ?? false) ? dutyTel1! : '전화번호 없음';
    final defaultAddr = (dutyAddr?.isNotEmpty ?? false) ? dutyAddr! : '주소 없음';

    // 24시간 운영 시간 설정
    const String operatingTime = "2400";  // 24시간 운영을 나타내는 값

    // 운영 상태 계산 및 번역
    String status = "운영중";
    // 실제 운영 상태 계산 (MedicalFacility에서 언어별 번역 처리)
    // todayOpenStatusFromServer는 null로 두고, MedicalFacilityCard/DetailPage에서 번역 처리

    return MedicalFacility(
      hpid: hpid,
      dutyName: defaultName,
      dutyAddr: defaultAddr,
      dutyTel1: defaultTel,
      wgs84Lat: wgs84Lat,
      wgs84Lon: wgs84Lon,
      dgidIdName: dgidIdName,
      distance: distance,
      // 응급의료기관은 24시간 운영으로 설정
      dutyTime1s: operatingTime,
      dutyTime1c: operatingTime,
      dutyTime2s: operatingTime,
      dutyTime2c: operatingTime,
      dutyTime3s: operatingTime,
      dutyTime3c: operatingTime,
      dutyTime4s: operatingTime,
      dutyTime4c: operatingTime,
      dutyTime5s: operatingTime,
      dutyTime5c: operatingTime,
      dutyTime6s: operatingTime,
      dutyTime6c: operatingTime,
      dutyTime7s: operatingTime,
      dutyTime7c: operatingTime,
      dutyTime8s: operatingTime,
      dutyTime8c: operatingTime,
      // 응급의료기관 정보 추가
      dutyInf: description,
      dutyDiv: "응급실",
      dutyDivNam: "응급실",
      dutyEmcls: "응급실",
      dutyEmclsName: "응급실",
      dutyEryn: "Y",
      isOpen: true,
      // 추가 정보
      dutyTel3: defaultTel,
      todayOpenStatusFromServer: null, // 번역 및 상태는 UI에서 계산
    );
  }

  // 24시간 운영 상태 반환 (MedicalFacility와 동일한 시그니처)
  String calculateTodayOpenStatus() {
    // 응급의료기관은 항상 24시간 운영
    return "운영중";
  }
} 