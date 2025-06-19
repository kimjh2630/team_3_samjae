import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:project/chat_bot/chatbot_page.dart';
import 'package:project/emergency/emergency_map_page.dart';
import 'package:project/hospital/hospital_search_result_page.dart';
import 'package:project/pharmacy/pharmacy_find.dart';
import 'package:project/service/social_login.dart';      // LoginWidget 정의된 파일
import 'package:project/chat_bot/chatbot_screen.dart';  // 다른 화면들
import 'package:project/hospital/hospital_main.dart';
import 'package:project/profile/profile_screen.dart';
import 'package:project/reservation/reservation_list_page.dart';
import 'package:project/splash/splash_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// 애플리케이션의 진입점
///
/// 이 함수는 앱의 초기화 작업을 수행합니다:
/// 1. Flutter 엔진 초기화
/// 2. 다국어 지원 초기화
/// 3. 네이버 지도 API 초기화
/// 4. 앱 실행
void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 다국어 지원 초기화
  await EasyLocalization.ensureInitialized();

  // 1) .env 로드
  await dotenv.load(fileName: ".env");

  // 2) 환경변수에서 키 가져오기
  final naverClientId = dotenv.env['NAVER_MAP_CLIENT_ID']!;
  final kakaoAppKey   = dotenv.env['KAKAO_SDK_APP_KEY']!;

  // 네이버 지도 API 초기화
  FlutterNaverMap().init(
      clientId: naverClientId,
      onAuthFailed: (ex) => switch (ex) {
        NQuotaExceededException(:final message) =>
            print("사용량 초과 (message: $message)"),
        NUnauthorizedClientException() ||
        NClientUnspecifiedException() ||
        NAnotherAuthFailedException() =>
            print("인증 실패: $ex"),
      });

  //카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: kakaoAppKey);

  // EasyLocalization이 MaterialApp(MyApp)을 반드시 감싸도록 수정
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
      ],
      path: 'assets/langs',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      useOnlyLangCode: true,
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MyApp(),
      ),
    ),
  );
}

/// 앱의 루트 위젯
///
/// 이 클래스는 앱의 기본 설정을 정의합니다:
/// - 앱 제목
/// - 테마 설정
/// - 다국어 지원 설정
/// - 초기 화면 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _initNickname(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('nickname');
    final appState = Provider.of<AppState>(context, listen: false);
    appState.nickname = (nickname != null && nickname.isNotEmpty) ? nickname : '비회원';
  }

  @override
  Widget build(BuildContext context) {
    // 앱 시작 시 닉네임을 AppState에 초기화
    _initNickname(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '소셜 로그인 + 지도 예제',
      // 앱의 기본 테마 설정
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 다국어 지원 설정
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // 앱의 초기 화면을 병원 메인 페이지로 설정
      home: SplashScreen(),
      routes: {
        '/chatbot': (context) => const ChatbotPage(),
        '/hospital_search': (context) => const HospitalSearchResultPage(),
        '/pharmacy_nearby': (context) => const PharmacyFindPage(),
        '/emergency_map': (context) => const EmergencyMapPage(),
        '/reservation': (context) => ReservationListPage(),
      },
    );
  }
}