import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
//소셜 로그인 관련 패키지
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/service/database_service.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:project/widgets/nav_main_page.dart';
import '../hospital/hospital_main.dart';
import 'email_auth_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../service/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'database_service.dart';

//로그인 플랫폼 구분용 enum
enum LoginPlatform {google, local,}
//로그인 위젯(상태 관리가 필요하므로 StatefulWidget사용)
class LoginWidget extends StatefulWidget{
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  bool isLoggedIn = false; //현재 로그인 여부
  bool _showLocalLogin = false;
  String? nickname; //로그인한 사용자의 닉네임 (구글용)
  String? email; //로그인한 사용자의 이메일 (구글용)
  String? loginPlatform; //현재 로그인된 플랫폼
  String? profileImage; //프로필 이미지 URL (구글 전용)
  User? _user; // Firebase User 객체

  //DB 저장을 위한 서비스 인스턴스
  final DatabaseService _db = DatabaseService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email'],
      serverClientId: '399398963854-dh1b6tgh5sol88q87jcg80edo4n7nomk.apps.googleusercontent.com',);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _initializeFirebase();
    } catch (e) {
      print('서비스 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서비스 초기화에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  @override
  void dispose() {
    // _db.disconnect();
    super.dispose();
  }

  Future <void> _updateLoginState({
    required bool loggedIn,
    String? platform,
    String? nick,
    String? mail,
    String? image
  }) async {
    setState(() {
      isLoggedIn = loggedIn;
      loginPlatform = platform;
      nickname = nick;
      email = mail;
      profileImage = image;
      _showLocalLogin = false;
    });
  }

  //로컬 로그인 성공 처리
  Future<void> loginWithLocal(String email, String nickname, String password) async {

    Provider.of<AppState>(context, listen: false).setLoggedIn(true);
    Provider.of<AppState>(context, listen: false).nickname = nickname;

    await _updateLoginState(
      loggedIn: true,
      platform: 'local',
      nick: nickname,
      mail: email,
      image: null,
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => nav_MainPage(initialIndex: 0),
        ),
      );
    }
  }

  //Google 로그인 함수
  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // 로그인 취소

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;


      if (googleAuth.idToken == null) {
        throw Exception("Google ID Token이 없습니다. Firebase 인증 실패");
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        try {
          // DB에 사용자 정보 저장
          await _db.saveUserInfo(
            email:           user.email      ?? '',
            nickname:        user.displayName?? '익명',
            loginPlatform:   'google',
            firebaseUid:     user.uid,
            profileImage: user.photoURL    ?? '',
          );

          await _updateLoginState(
            loggedIn: true,
            platform: 'google',
            nick: user.displayName,
            mail: user.email,
            image: user.photoURL,
          );

          print('Google 계정 로그인 성공 (Firebase)');
          print('이름 : ${user.displayName}');
          print('이메일 : ${user.email}');

          Provider.of<AppState>(context, listen: false).setLoggedIn(true);
          Provider.of<AppState>(context, listen: false).nickname = user.displayName;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => nav_MainPage(initialIndex: 0),),
                (Route<dynamic> route) => false,
          );
        } catch (dbError) {
          print('DB 저장 실패: $dbError');
          // DB 저장 실패해도 로그인은 유지
          await _updateLoginState(
            loggedIn: true,
            platform: 'google',
            nick: user.displayName,
            mail: user.email,
            image: user.photoURL,
          );
        }
      }
    } catch (e) {
      print('Google 로그인 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 로그인에 실패했습니다: $e')),
        );
      }
    }
  }

  //로그아웃 함수(플랫폼별 분기)
  Future <void> logout() async {
    try {
      if (loginPlatform == 'google') {
        await _googleSignIn.signOut(); //구글 로그아웃
        print('Google 계정 로그아웃 성공');
      } else if (loginPlatform == 'local') {
        print('로컬 계정 로그아웃 성공');
      }
    } catch (e) {
      print('로그아웃 실패 : $e');
    }

    Provider.of<AppState>(context, listen: false).setLoggedIn(false);
    Provider.of<AppState>(context, listen: false).nickname = null;

    //상태 초기화
    setState(() {
      isLoggedIn = false;
      nickname = null;
      email = null;
      loginPlatform = null;
      _user = null;
      profileImage = null;
    });
  }

  //로컬 로그인 버튼 클릭 시 호출되는 함수
  void _showEmailAuthDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Scaffold(
                body: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '이메일 로그인',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            child: EmailAuthWidget(
                              onLoginSuccess: (email, nick, pw) =>
                                  loginWithLocal(email, nick, pw),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();




  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => const LanguageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: null,
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // 1) 상단 로고
              Image.asset(
                'assets/images/aidoc_logo.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EmailAuthWidget(
                              onLoginSuccess: (email, nick, pw) =>
                                  loginWithLocal(email, nick, pw)
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4BB8EA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "socialLoginSignup".tr(),
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 24),

              // 4) OR 구분선
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text("or".tr(), style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 24),

              // 5) 소셜 로그인 버튼 (Google만 남김)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialBtn('assets/images/google_login_m.png', loginWithGoogle),
                ],
              ),
              SizedBox(height: 16),
              GestureDetector(
                //건너 뛰기
                onTap: () async {
                  // 로그인 정보 완전 초기화
                  await AuthService.logout();
                  await AuthService.saveUserInfo('', '');
                  await AuthService.saveNickname(null);
                  if (mounted) {
                    Provider.of<AppState>(context, listen: false).nickname = "nonMember".tr();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => nav_MainPage()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  width: 150,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 10),
                      Text(
                        "startAsNonMember".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 소셜 버튼 위젯 (Google만 남김)
  Widget _socialBtn(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}