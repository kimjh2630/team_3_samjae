// 의료기관 데이터 모델
import 'package:flutter/material.dart'; // Color 사용을 위해 추가

class MedicalFacility {
  final String? hpid;
  final String? dutyName;
  final String? dutyAddr;
  final String? dutyTel1;
  final String? dutyDiv;
  final String? dutyDivNam;
  final String? dutyEmcls;
  final String? dutyEmclsName;
  final String? dutyEryn;
  final String? dutyEtc;
  final String? dutyMapimg;
  final String? postCdn1;
  final String? postCdn2;
  final String? wgs84Lat;
  final String? wgs84Lon;
  final String? dutyInf;
  final String? dutyTime1s;
  final String? dutyTime2s;
  final String? dutyTime3s;
  final String? dutyTime4s;
  final String? dutyTime5s;
  final String? dutyTime6s;
  final String? dutyTime7s;
  final String? dutyTime8s;
  final String? dutyTime1c;
  final String? dutyTime2c;
  final String? dutyTime3c;
  final String? dutyTime4c;
  final String? dutyTime5c;
  final String? dutyTime6c;
  final String? dutyTime7c;
  final String? dutyTime8c;
  double? distance;
  final bool? isOpen;
  final String? todayOpenStatusFromServer;
  final String? dutyDivNm;
  final String? hospUrl;
  final String? dutyTel3;
  final String? MKioskTy25;
  final String? dgidIdName;

  MedicalFacility({
    this.hpid,
    this.dutyName,
    this.dutyAddr,
    this.dutyTel1,
    this.dutyDiv,
    this.dutyDivNam,
    this.dutyEmcls,
    this.dutyEmclsName,
    this.dutyEryn,
    this.dutyEtc,
    this.dutyMapimg,
    this.postCdn1,
    this.postCdn2,
    this.wgs84Lat,
    this.wgs84Lon,
    this.dutyInf,
    this.dutyTime1s, this.dutyTime2s, this.dutyTime3s, this.dutyTime4s,
    this.dutyTime5s, this.dutyTime6s, this.dutyTime7s, this.dutyTime8s,
    this.dutyTime1c, this.dutyTime2c, this.dutyTime3c, this.dutyTime4c,
    this.dutyTime5c, this.dutyTime6c, this.dutyTime7c, this.dutyTime8c,
    this.distance,
    this.isOpen,
    this.todayOpenStatusFromServer,
    this.dutyDivNm,
    this.hospUrl,
    this.dutyTel3,
    this.MKioskTy25,
    this.dgidIdName,
  });

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    // 좌표값 처리 및 검증
    String? lat = json['wgs84Lat'] ?? json['wgs84lat'];
    String? lon = json['wgs84Lon'] ?? json['wgs84lon'];

    if (lat != null && lon != null) {
      try {
        double latValue = double.parse(lat);
        double lonValue = double.parse(lon);

        // 좌표값 유효성 검사
        if (latValue < -90 || latValue > 90 || lonValue < -180 || lonValue > 180) {
          print('Invalid coordinates for ${json['dutyName']}: $lat, $lon');
          lat = null;
          lon = null;
        } else {
          // 원본 좌표값 그대로 사용
          lat = latValue.toString();
          lon = lonValue.toString();
        }
      } catch (e) {
        print('Error parsing coordinates for ${json['dutyName']}: $e');
        lat = null;
        lon = null;
      }
    }

    return MedicalFacility(
      hpid: json['hpid'],
      dutyName: json['dutyName'] ?? json['dutyname'],
      dutyAddr: json['dutyAddr'] ?? json['dutyaddr'],
      dutyTel1: json['dutyTel1'] ?? json['dutytel1'],
      dutyDiv: json['dutyDiv'] ?? json['dutydiv'],
      dutyDivNam: json['dutyDivNam'] ?? json['dutydivnam'],
      dutyEmcls: json['dutyEmcls'] ?? json['dutyemcls'],
      dutyEmclsName: json['dutyEmclsName'] ?? json['dutyemclsname'],
      dutyEryn: json['dutyEryn'] ?? json['dutyeryn'],
      dutyEtc: json['dutyEtc'] ?? json['dutyetc'],
      dutyMapimg: json['dutyMapimg'] ?? json['dutymapimg'],
      postCdn1: json['postCdn1'] ?? json['postcdn1'],
      postCdn2: json['postCdn2'] ?? json['postcdn2'],
      wgs84Lat: lat,
      wgs84Lon: lon,
      dutyInf: json['dutyInf'] ?? json['dutyinf'],
      dutyTime1s: json['dutyTime1s'] ?? json['dutytime1s'],
      dutyTime2s: json['dutyTime2s'] ?? json['dutytime2s'],
      dutyTime3s: json['dutyTime3s'] ?? json['dutytime3s'],
      dutyTime4s: json['dutyTime4s'] ?? json['dutytime4s'],
      dutyTime5s: json['dutyTime5s'] ?? json['dutytime5s'],
      dutyTime6s: json['dutyTime6s'] ?? json['dutytime6s'],
      dutyTime7s: json['dutyTime7s'] ?? json['dutytime7s'],
      dutyTime8s: json['dutyTime8s'] ?? json['dutytime8s'],
      dutyTime1c: json['dutyTime1c'] ?? json['dutytime1c'],
      dutyTime2c: json['dutyTime2c'] ?? json['dutytime2c'],
      dutyTime3c: json['dutyTime3c'] ?? json['dutytime3c'],
      dutyTime4c: json['dutyTime4c'] ?? json['dutytime4c'],
      dutyTime5c: json['dutyTime5c'] ?? json['dutytime5c'],
      dutyTime6c: json['dutyTime6c'] ?? json['dutytime6c'],
      dutyTime7c: json['dutyTime7c'] ?? json['dutytime7c'],
      dutyTime8c: json['dutyTime8c'] ?? json['dutytime8c'],
      distance: (json['distance'] != null) ? double.tryParse(json['distance'].toString()) : null,
      isOpen: json['is_open'] is bool ? json['is_open'] : (json['is_open'] == 'true' ? true : (json['is_open'] == 'false' ? false : null)),
      todayOpenStatusFromServer: json['today_open_status'],
      dutyDivNm: json['dutyDivNm'] ?? json['dutydivnm'],
      hospUrl: json['hospUrl'],
      dutyTel3: json['dutyTel3'],
      MKioskTy25: json['MKioskTy25'],
      dgidIdName: json['dgidIdName'],
    );
  }

  // 좌표값을 double로 변환하는 메서드
  double? getLatitude() {
    if (wgs84Lat == null) return null;
    try {
      return double.parse(wgs84Lat!);
    } catch (e) {
      print('Error parsing latitude: $e');
      return null;
    }
  }

  double? getLongitude() {
    if (wgs84Lon == null) return null;
    try {
      return double.parse(wgs84Lon!);
    } catch (e) {
      print('Error parsing longitude: $e');
      return null;
    }
  }

  // "HHMM" 형태의 시간 문자열을 DateTime 객체로 변환 (오늘 날짜 기준)
  DateTime? _parseTimeToDateTime(String? time) {
    if (time == null || time.length != 4) {
      return null;
    }
    try {
      int hour = int.parse(time.substring(0, 2));
      int minute = int.parse(time.substring(2, 4));

      if (hour < 0 || hour > 24 || minute < 0 || minute >= 60) { // 24:00 포함을 위해 hour <= 24로 수정
        return null;
      }

      final now = DateTime.now();
      // API 시간이 2400인 경우 다음 날 00:00으로 처리
      if (hour == 24 && minute == 0) {
        return DateTime(now.year, now.month, now.day, 0, 0).add(Duration(days: 1));
      } else if (hour == 24) { // 24시 이후 시간은 유효하지 않다고 가정
        return null;
      }

      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      // 파싱 오류 발생 시 (숫자가 아닌 문자 포함 등)
      print("Error parsing time string '$time' to DateTime: $e");
      return null;
    }
  }

  // 최종 운영 상태를 결정하는 getter
  String get finalOpenStatus {
    // 1. 서버에서 제공한 상태가 유효하면 그 값을 최우선으로 사용
    if (todayOpenStatusFromServer != null && todayOpenStatusFromServer!.isNotEmpty) {
      return todayOpenStatusFromServer!;
    }
    // 2. 서버 제공 상태가 없으면, 클라이언트에서 계산한 상태를 사용
    return calculateTodayOpenStatus();
  }

  // 현재 시간에 따라 운영 상태를 계산하는 메서드 (Flutter에서 계산)
  String calculateTodayOpenStatus() {
    final now = DateTime.now();
    int todayWeekdayDartIndex = now.weekday; // 1(월) ~ 7(일)

    String? startTimeStr;
    String? endTimeStr;

    // 오늘의 요일에 해당하는 운영 시간 선택
    switch(todayWeekdayDartIndex) {
      case 1: startTimeStr = dutyTime1s; endTimeStr = dutyTime1c; break; // 월
      case 2: startTimeStr = dutyTime2s; endTimeStr = dutyTime2c; break; // 화
      case 3: startTimeStr = dutyTime3s; endTimeStr = dutyTime3c; break; // 수
      case 4: startTimeStr = dutyTime4s; endTimeStr = dutyTime4c; break; // 목
      case 5: startTimeStr = dutyTime5s; endTimeStr = dutyTime5c; break; // 금
      case 6: startTimeStr = dutyTime6s; endTimeStr = dutyTime6c; break; // 토
      case 7: startTimeStr = dutyTime7s; endTimeStr = dutyTime7c; break; // 일
      default:
      // 이론적으로 발생하지 않아야 하지만, 안전을 위해 처리
        return "운영 시간 정보 판단 불가 (요일 오류)";
    }

    // 24시간 운영 예외처리
    if ((startTimeStr == '2400' || startTimeStr == '24:00') && (endTimeStr == '2400' || endTimeStr == '24:00')) {
      return "운영중";
    }

    // 공휴일 체크 로직은 API에서 공휴일 정보를 제공하지 않는 이상 클라이언트에서 정확히 판단하기 어려우므로 일단 제외.
    // dutyTime8s, dutyTime8c는 공휴일 시간으로 사용될 수 있으나, 현재 날짜가 공휴일인지 판단하는 로직 필요

    final startDateTime = _parseTimeToDateTime(startTimeStr);
    final endDateTime = _parseTimeToDateTime(endTimeStr);

    // 현재 시간을 '오늘' 기준으로 맞춤
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    // 시작 시간과 종료 시간 정보가 모두 없는 경우
    if (startDateTime == null && endDateTime == null) {
      // 서버에서 제공하는 isOpen 정보가 있다면 그것을 사용
      if (isOpen != null) {
        return isOpen! ? "운영중 (API)" : "운영종료 (API)";
      }
      // 둘 다 없다면 정보 없음
      return "운영 시간 정보 없음";
    }

    // 야간 운영 (예: 22:00 ~ 03:00) 처리
    if (startDateTime != null && endDateTime != null && startDateTime.isAfter(endDateTime)) {
      // 종료 시간이 다음 날로 넘어가는 경우
      final realEndDateTime = endDateTime.add(Duration(days: 1));

      // 현재 시간이 시작 시간 이후이거나 (오늘 밤) 또는 다음 날 종료 시간 이전인 경우 (내일 새벽)
      if (currentTime.isAfter(startDateTime) || currentTime.isAtSameMomentAs(startDateTime) || currentTime.isBefore(realEndDateTime)) {
        return "운영중";
      } else {
        return "운영종료";
      }
    }
    // 일반적인 주간 운영 (예: 09:00 ~ 18:00) 처리
    else if (startDateTime != null && endDateTime != null) {
      if ((currentTime.isAfter(startDateTime) || currentTime.isAtSameMomentAs(startDateTime))
          && currentTime.isBefore(endDateTime)) {
        return "운영중";
      } else {
        return "운영종료";
      }
    }
    // 시작 시간만 있고 종료 시간 정보가 없는 경우 (애매하지만 시작 시간 이후 운영중으로 간주)
    else if (startDateTime != null && endDateTime == null) {
      return (currentTime.isAfter(startDateTime) || currentTime.isAtSameMomentAs(startDateTime))
          ? "운영중"
          : "운영종료";
    }
    // 종료 시간만 있고 시작 시간 정보가 없는 경우 (애매하지만 종료 시간 이전 운영중으로 간주)
    else if (startDateTime == null && endDateTime != null) {
      return currentTime.isBefore(endDateTime)
          ? "운영중"
          : "운영종료";
    }

    // 모든 경우에 해당하지 않는 경우
    return "운영 시간 판단 불가";
  }

  // 의료기관 이름에서 불필요한 문자 제거
  String? getCleanDutyName() {
    if (dutyName == null) return null;
    return dutyName!.replaceAll(RegExp(r'[^\w\s가-힣]'), '').trim();
  }
}