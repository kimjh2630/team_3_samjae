import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:project/service/auth_service.dart';

class DatabaseService {
  // 싱글톤 인스턴스
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // PostgreSQL 연결 객체
  PostgreSQLConnection? _connection;

  /// 비밀번호 해시 (로컬 이메일 가입용)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// DB 연결 (한 번만 열고 재사용)
  Future<void> connect() async {
    if (_connection == null || _connection!.isClosed) {
      _connection = PostgreSQLConnection(
        'database-1.ct8wqsmwwlb2.ap-northeast-2.rds.amazonaws.com',
        5432,
        'postgres',
        username: 'postgres',
        password: 'admin1234',
        useSSL: true,
      );
      await _connection!.open();
      print('데이터베이스 연결 오픈 (isClosed=${_connection!.isClosed})');

      // 필요한 테이블 생성
      await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS loginaccount (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        nickname VARCHAR(255) NOT NULL,
        platform VARCHAR(50) NOT NULL,
        profile_image TEXT,
        firebase_uid VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX IF NOT EXISTS idx_loginaccount_email_platform
        ON loginaccount(email, platform);

      CREATE TABLE IF NOT EXISTS email_users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        nickname VARCHAR(255) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      ''');
      print('테이블(loginaccount, email_users) 준비 완료');
    }
  }

  /// DB 연결 종료
  Future<void> disconnect() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      print('데이터베이스 연결 종료');
    }
  }

  // ------------------------------------------------------------
  // 로컬 이메일/비밀번호 인증 관련
  // ------------------------------------------------------------

  /// 로컬 계정 회원가입(email_users)
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await connect();
    if (nickname.trim().isEmpty) return false;

    final exists = await _connection!.query(
      'SELECT 1 FROM email_users WHERE email = @email',
      substitutionValues: {'email': email},
    );
    if (exists.isNotEmpty) {
      print('이미 존재하는 이메일입니다.');
      return false;
    }

    final hash = _hashPassword(password);
    await _connection!.execute(
      '''
      INSERT INTO email_users (email, nickname, password_hash)
      VALUES (@email, @nickname, @hash)
    ''',
      substitutionValues: {'email': email, 'nickname': nickname, 'hash': hash},
    );
    return true;
  }

  /// 로컬 계정 로그인(email_users)
  Future<Map<String, dynamic>?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await connect();
    final hash = _hashPassword(password);
    final results = await _connection!.query(
      'SELECT email, nickname FROM email_users WHERE email = @email AND password_hash = @hash',
      substitutionValues: {'email': email, 'hash': hash},
    );
    if (results.isEmpty) return null;
    return {'email': results[0][0], 'nickname': results[0][1]};
  }

  // ------------------------------------------------------------
  // 소셜 로그인 관련
  // ------------------------------------------------------------

  /// (소셜 로그인) 로그인·신규 가입 시 loginaccount 테이블에 저장 또는 업데이트
  Future<void> saveUserInfo({
    required String email,
    required String nickname,
    required String loginPlatform,
    required String profileImage,
    String? firebaseUid,
  }) async {
    await connect();

    await _connection!.execute(
      '''
      INSERT INTO loginaccount
        (email, nickname, platform, profile_image, firebase_uid)
      VALUES
        (@email, @nickname, @platform, @profileImage, @firebaseUid)
      ON CONFLICT (email, platform)
      DO UPDATE SET
        nickname      = EXCLUDED.nickname,
        profile_image = EXCLUDED.profile_image,
        firebase_uid  = EXCLUDED.firebase_uid,
        updated_at    = CURRENT_TIMESTAMP;
    ''',
      substitutionValues: {
        'email': email,
        'nickname': nickname,
        'platform': loginPlatform,
        'profileImage': profileImage,
        'firebaseUid': firebaseUid ?? '',
      },
    );

    print('loginaccount 저장/업데이트 성공');
  }

  // ------------------------------------------------------------
  // 회원 탈퇴 로직
  // ------------------------------------------------------------

  /// 회원탈퇴 : Python API DELETE 호출만 사용
  Future<bool> deleteUser({
    required String email,
    required String loginPlatform,
  }) async {
    // AuthService.deleteAccount가 DELETE /loginaccount/{email}?platform=… 를 호출
    final res = await AuthService.deleteAccount(email, loginPlatform);
    if (res.statusCode == 200) {
      print('API 회원탈퇴 성공 (statusCode=200)');
      return true;
    } else {
      print('API 회원탈퇴 실패 (statusCode=${res.statusCode}): ${res.body}');
      return false;
    }
  }
}
