import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../component/medical_facility.dart';
import '../emergency/emergency_model.dart';

class AppState extends ChangeNotifier {
  Position? _position;
  List<MedicalFacility>? _pharmacies;
  List<MedicalFacility>? _hospitals;
  Map<String, List<MedicalFacility>>? _subjectHospitals;
  List<EmergencyFacility>? _emergencyFacilities;

  Position? currentPosition;
  List<MedicalFacility>? nearbyHospitals;

  // 닉네임 글로벌 상태
  String? _nickname;
  String? get nickname => _nickname;
  set nickname(String? value) {
    _nickname = value;
    notifyListeners();
  }

  // ── 여기에 로그인 상태 로직 추가 ──
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  void setLoggedIn(bool val) {
    _isLoggedIn = val;
    notifyListeners();
  }


  Position? get position => _position;
  List<MedicalFacility>? get pharmacies => _pharmacies;
  List<MedicalFacility>? get hospitals => _hospitals;
  Map<String, List<MedicalFacility>>? get subjectHospitals => _subjectHospitals;
  List<EmergencyFacility>? get emergencyFacilities => _emergencyFacilities;

  // getter 타입이 nullable 이므로 setter 파라미터도 nullable 로 맞춰줍니다.
  set position(Position? p) {
    _position = p;
    notifyListeners();
  }

  set pharmacies(List<MedicalFacility>? list) {
    _pharmacies = list;
    notifyListeners();
  }

  set hospitals(List<MedicalFacility>? hosps) {
    _hospitals = hosps;
    notifyListeners();
  }

  set subjectHospitals(Map<String, List<MedicalFacility>>? subjectData) {
    _subjectHospitals = subjectData;
    notifyListeners();
  }

  set emergencyFacilities(List<EmergencyFacility>? facilities) {
    _emergencyFacilities = facilities;
    notifyListeners();
  }

  void setCurrentPosition(Position pos) {
    currentPosition = pos;
    notifyListeners();
  }

  void setNearbyHospitals(List<MedicalFacility> list) {
    nearbyHospitals = list;
    notifyListeners();
  }
}