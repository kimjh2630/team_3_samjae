import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseService {
  //싱글톤 패턴 구현을 위한 인스턴스 변수
  static final DatabaseService _instance = DatabaseService._internal();
  //PostgreSQL 연결 객체
  late final PostgreSQLConnection _connection;
  //연결 상태 플래그
  bool _isConnected = false;

  //팩토리 생성자 : 항상 같은 인스턴스 반환
  factory DatabaseService() {
    return _instance;
  }

  //내부 생성자 (싱글톤용)
  DatabaseService._internal();

  //비밀번호 해시 함수
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // 비밀번호를 바이트로 인코딩
    final hash = sha256.convert(bytes); // SHA-256 해시 생성
    return hash.toString();
  }

  //DB 연결 함수
  Future<void> connect() async {
    //이미 연결되어 있지 않은 경우에만 연결 시도
    if (!_isConnected) {
      try {
        _connection = PostgreSQLConnection(
          //DB 호스트 주소
          'database-1.ct8wqsmwwlb2.ap-northeast-2.rds.amazonaws.com',
          5432,                     //포트번호
          'postgres',               //DB 이름
          username: 'postgres',     //DB 접속 아이디
          password: 'admin1234',    //DB 접속 비밀번호
          useSSL: true,             //SSL 사용 여부
        );

        await _connection.open();   //DB 연결 오픈
        _isConnected = true;        //연결 상태 플래그 갱신
        print('데이터베이스 연결 성공');

        //이메일 회원가입용 테이블 생성
        await _connection.execute('''
          CREATE TABLE IF NOT EXISTS email_users (
            id SERIAL PRIMARY KEY,
            nickname VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      } catch (e) {
        print('데이터베이스 연결 실패: $e');
        rethrow;                    //에러를 상위 호출자에게 전달
      }
    }
  }

  // 이메일 회원가입 함수
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      if (!_isConnected) {
        await connect();
      }

      if (nickname.trim().isEmpty) {
        print('닉네임이 비어 있습니다. 유효한 닉네임을 입력하세요.');
        return false;
      }

      // 이메일 중복 체크
      final existingUser = await _connection.query(
        'SELECT * FROM email_users WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (existingUser.isNotEmpty) {
        print('이미 존재하는 이메일입니다.');
        return false;
      }

      // 비밀번호 해시화 및 사용자 정보 저장
      final passwordHash = _hashPassword(password);
      await _connection.execute('''
        INSERT INTO email_users (nickname, email, password_hash)
        VALUES (@nickname, @email, @passwordHash)
      ''', substitutionValues: {
        'nickname': nickname,
        'email': email,
        'passwordHash': passwordHash,
      });

      print('로컬 계정 회원가입 성공');
      return true;
    } catch (e) {
      print('로컬 계정 회원가입 실패 : $e');
      return false;
    }
  }

  // 이메일 로그인 함수
  Future<Map<String, dynamic>?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isConnected) {
        await connect();
      }

      final passwordHash = _hashPassword(password);
      final results = await _connection.query(
        'SELECT * FROM email_users WHERE email = @email AND password_hash = @passwordHash',
        substitutionValues: {
          'email': email,
          'passwordHash': passwordHash,
        },
      );

      if (results.isNotEmpty) {
        final nickname = results[0][1]; // 닉네임 컬럼
        print('닉네임 : $nickname');
        return {
          'nickname': results[0][1],
          'email': results[0][2],
          'password': passwordHash
        };
      }
      print('이메일 또는 비밀번호가 일치하지 않습니다.');
      return null;
    } catch (e) {
      print('로그인 실패 : $e');
      return null;
    }
  }

  //DB 연결 종료 함수
  Future<void> disconnect() async {
    if (_isConnected) {
      await _connection.close();    //DB 연결 종료
      _isConnected = false;         //연결 상태 플래그 갱신
      print('데이터베이스 연결 종료');
    }
  }

  //사용자 정보를 DB에 저장하는 함수(없으면 생성, 있으면 업데이트)
  Future<void> saveUserInfo({
    required String email,
    required String nickname,
    required String loginPlatform,
    required String profileImage,
    String? firebaseUid,
    String? password,
  }) async {
    try {
      if (!_isConnected) {
        await connect();    //연결이 안 되어 있으면 연결부터 시도
      }

      //users 테이블이 없으면 생성
      //email과 platform 조합은 유니크해야함
      await _connection.execute('''
        CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        nickname VARCHAR(255) NOT NULL,
        platform VARCHAR(50) NOT NULL,
        profile_image TEXT,
        firebase_uid VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(email, platform)
        )
      ''');

      //사용자 정보를 삽입하거나, 이미 있으면 닉네임과 프로필 이미지만 업데이트
      await _connection.execute('''
        INSERT INTO users (email, nickname, platform, profile_image, firebase_uid)
        VALUES (@email, @nickname, @platform, @profile_image, @firebaseUid)
        ON CONFLICT (email, platform) 
        DO UPDATE SET 
          nickname = EXCLUDED.nickname,
          profile_image = EXCLUDED.profile_image,
          firebase_uid = EXCLUDED.firebase_uid
      ''', substitutionValues: {
        'email': email,
        'nickname': nickname,
        'platform': loginPlatform,
        'profile_image': profileImage,
        'firebaseUid': firebaseUid,
      });

      print('사용자 정보 저장 성공');
    } catch (e) {
      print('사용자 정보 저장 실패: $e');
      rethrow;      //에러 상위 호출자에게 전달
    }
  }

  //이메일과 플랫폼으로 사용자 정보를 조회하는 함수
  Future<Map<String, dynamic>?> getUserInfo({
    required String email,
    required String loginPlatform,
  }) async {
    try {
      if (!_isConnected) {
        await connect();      //연결이 안 되어 있으면 연결 시도
      }

      //users 테이블에서 해당 이메일과 플랫폼에 맞는 사용자 정보 조회
      final results = await _connection.query(
        'SELECT * FROM users WHERE email = @email AND platform = @platform',
        substitutionValues: {'email': email, 'platform': loginPlatform},
      );

      //결과가 있으면 Map 형태로 반환
      if (results.isNotEmpty) {
        return {
          'nickname': results[0][1],        //닉네임
          'email': results[0][2],           //이메일
          'loginPlatform': results[0][3],   //로그인 플랫폼
          'profileImage': results[0][4],    //프로필 이미지 URL
          'firebaseUid': results[0][5],
        };
      }
      //결과가 없으면 null 반환
      return null;
    } catch (e) {
      print('사용자 정보 조회 실패: $e');
      rethrow;      //에러 상위 호출자에게 전달
    }
  }
}
