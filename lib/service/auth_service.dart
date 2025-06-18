/// 사용자 인증을 관리하는 서비스 클래스
///
/// 현재는 임시로 메모리 내에서 로그인 상태만 관리합니다.
/// 추후 Firebase Authentication 등과 연동하여 실제 인증 기능을 구현할 수 있습니다.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // API 서버 주소
  static const String jwtKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userEmailKey = 'user_email';
  static const String userPlatformKey = 'user_platform';

  // JWT 토큰 저장
  static Future<void> saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(jwtKey, token);
    } else {
      await prefs.remove(jwtKey);
    }
  }

  // JWT 토큰 삭제
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(jwtKey);
  }

  // JWT 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(jwtKey);
  }

  // Refresh Token 저장
  static Future<void> saveRefreshToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(refreshTokenKey, token);
    } else {
      await prefs.remove(refreshTokenKey);
    }
  }

  // Refresh Token 가져오기
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  // Refresh Token 삭제
  static Future<void> removeRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(refreshTokenKey);
  }

  // 완전한 로그아웃 (모든 토큰 삭제)
  static Future<void> logout() async {
    await removeToken();
    await removeRefreshToken();
  }

  // 회원가입
  static Future<http.Response> register(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl/loginaccount/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  // 로그인(로컬)
  static Future<http.Response> login(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl/loginaccount/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  // 회원정보 조회 (인증 필요)
  static Future<http.Response> getUser(String email, String platform) async {
    return await http.get(
      Uri.parse('$baseUrl/loginaccount/$email?platform=$platform'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // 소셜 로그인 (네이버/카카오/구글)
  static Future<http.Response> socialLogin(String provider, String accessToken) async {
    return await http.post(
      Uri.parse('$baseUrl/loginaccount/social'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'access_token': accessToken,
      }),
    );
  }

  // 회원정보 수정 (닉네임/비밀번호)
  static Future<http.Response> updateUser(String email, String platform, Map<String, dynamic> updateData) async {
    return await http.patch(
      Uri.parse('$baseUrl/loginaccount/$email?platform=$platform'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
  }

  // email, platform 저장
  static Future<void> saveUserInfo(String email, String platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userEmailKey, email);
    await prefs.setString(userPlatformKey, platform);
  }

  // email, platform 불러오기
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(userEmailKey),
      'platform': prefs.getString(userPlatformKey),
    };
  }

  // 닉네임 저장
  static Future<void> saveNickname(String? nickname) async {
    final prefs = await SharedPreferences.getInstance();
    if (nickname != null) {
      await prefs.setString('nickname', nickname);
    } else {
      await prefs.remove('nickname');
    }
  }

  // 닉네임 불러오기
  static Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname');
  }

  // 로그인/닉네임 변경/로그아웃 시 AppState 닉네임 갱신용 함수
  static void updateAppStateNickname(context, String? nickname) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.nickname = (nickname != null && nickname.isNotEmpty) ? nickname : '비회원';
  }

  // 회원 탈퇴 (DELETE)
  static Future<http.Response> deleteAccount(String email, String platform) async {
    return await http.delete(
      Uri.parse('$baseUrl/loginaccount/$email?platform=$platform'),
      headers: {'Content-Type': 'application/json'},
    );
  }
} 