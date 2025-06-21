// 의료기관 검색 화면 메인 페이지

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project/widgets/language_dialog.dart';
import '../pharmacy/pharmacy_find.dart';
import '../reservation/reservation_list_page.dart';
import '../widgets/nav_main_page.dart';
import 'hospital_search_result_page.dart' as hospital;
import 'package:easy_localization/easy_localization.dart';
import '../emergency/emergency_box.dart';
import '../emergency/emergency_map_page.dart';
import 'package:project/service/auth_service.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HospitalMainPage extends StatefulWidget {
  const HospitalMainPage({Key? key}) : super(key: key);

  @override
  _HospitalMainPageState createState() => _HospitalMainPageState();
}

class _HospitalMainPageState extends State<HospitalMainPage> {
  Position? currentPosition;

  void _showLanguageDialog() {
    showDialog(context: context, builder: (context) => const LanguageDialog());
  }

  final PageController _controller = PageController(viewportFraction: 1);
  final List<String> adImages = [
    'assets/images/ad1.png',
    'assets/images/ad2.png',
    'assets/images/ad3.png',
  ];

  // 1:1로 매핑된 광고 클릭 시 이동할 URL
  final List<String> adUrls = [
    'https://health.kdca.go.kr/healthinfo/biz/health/ntcnInfo/healthSourc/thtimtCntnts/thtimtCntntsView.do?thtimt_cntnts_sn=120&utm_source=kdca&utm_medium=kdca',
    'https://www.kdca.go.kr/gallery.es?mid=a20503020000&bid=0003&b_list=9&act=view&list_no=146864',
    'https://www.kdca.go.kr/gallery.es?mid=a20503020000&bid=0003',
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'URL을 열 수 없습니다: $url';
    }
  }

  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentPage < adImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _controller.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 중지
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nickname = Provider.of<AppState>(context).nickname;
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "home_title".tr(),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: _showLanguageDialog,
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  "${'hello'.tr()}, ${(nickname == null || nickname.isEmpty || nickname == '비회원') ? 'guest'.tr() : nickname} ${'ok_'.tr()}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),

                SizedBox(
                  height: 130, // 슬라이더 높이 조절
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: adImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _launchUrl(adUrls[index]),
                        child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            adImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(20),
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [Colors.blue.shade50, Colors.blue.shade100],
                //       begin: Alignment.topLeft,
                //       end: Alignment.bottomRight,
                //     ),
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         '뭘 넣을까요',
                //         style: TextStyle(
                //           fontSize: 18,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       SizedBox(height: 8),
                //       Center(
                //         child: Text(
                //           '여기에 글자 말고 배너?',
                //           style: TextStyle(fontSize: 13, color: Colors.black87),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 20),

                //병원 및 약국 찾기
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      hospital.HospitalSearchResultPage(),
                            ),
                          );
                        },
            child: Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blueAccent.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/aidoc_logo_noname.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "hospital_search".tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "quickFindHospital".tr(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
      ),
                      ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyFindPage(),
                            ),
                          );
                        },
                        // child: PolygonOverlay(
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blueAccent.shade100,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/aidoc_logo_pha.png',
                                width: 100, // 아이콘 크기 대신 너비
                                height: 100, // 높이 지정
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 0),
                                Text(
                                "pharmacy_search".tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 0),
                                Text(
                                "findPharmacyOnMap".tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ),
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => nav_MainPage(initialIndex: 1),
                      ),
                    );
                  },

                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.blueAccent.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/aidoc_logo_chat.png',
                              width: 100, // 아이콘 크기 대신 너비
                              height: 100, // 높이 지정
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "chatbot.chat".tr(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  SizedBox(height: 8),
                                    Text(
                                      "chatbot.subchat".tr(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                      textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergencyMapPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/aidoc_logo_noname_em.png',
                          width: 100, // 아이콘 크기 대신 너비
                          height: 100, // 높이 지정
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 40),
                        Flexible(
                          child: Text(
                            "emergency.nearby".tr(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
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
      ),
    );
  }
}

/// 2) 반투명 폴리곤을 오버레이하는 CustomPainter
class PolygonOverlay extends StatelessWidget {
  final Widget child;

  const PolygonOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(child: CustomPaint(painter: _PolygonPainter())),
      ],
    );
  }
}

class _PolygonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white10.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final path =
        Path()
          ..moveTo(size.width * 0.2, size.height * 0.1)
          ..lineTo(size.width * 0.8, size.height * 0.25)
          ..lineTo(size.width * 0.5, size.height * 0.6)
          ..close();

    canvas.drawPath(path, paint);
    // 더 많은 폴리곤을 그리고 싶으면 여기 추가
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
