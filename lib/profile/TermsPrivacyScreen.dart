// import 'package:flutter/material.dart';
//
// class TermsPrivacyPage extends StatelessWidget {
//   const TermsPrivacyPage({Key? key}) : super(key: key);
//
//   // TODO: 실제 약관 전문으로 교체하세요
//   static const String serviceTermsText = '''
// 제1조(목적)
// 이 약관은 ...
//
// 제2조(정의)
// “서비스”란 ...
//
// … (이하 생략)
// ''';
//
//   static const String locationServiceTermsText = '''
// [위치기반 서비스 이용 약관]
//
// 1. 위치 정보의 수집 및 이용 목적
// 회사는 ...
//
// 2. 위치 정보 제공 범위
// … (이하 생략)
// ''';
//
//   static const String privacyText = '''
// 1. 개인정보의 수집 및 이용 목적
// 회사는 ...
//
// 2. 수집하는 개인정보 항목
// … (이하 생략)
// ''';
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,  // 탭 개수
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('약관 및 개인정보 처리 방침'),
//         ),
//         body: Column(
//           children: [
//             // 탭바
//             Material(
//               color: Theme.of(context).primaryColor,
//               child: const TabBar(
//                 labelColor: Colors.white,
//                 unselectedLabelColor: Colors.white70,
//                 indicatorColor: Colors.white,
//                 tabs: [
//                   Tab(text: '서비스 이용약관'),
//                   Tab(text: '위치기반 서비스 이용 약관'),
//                   Tab(text: '개인정보 처리방침'),
//                 ],
//               ),
//             ),
//
//             // 탭뷰
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   // 서비스 이용약관
//                   SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Text(
//                       serviceTermsText,
//                       style: const TextStyle(fontSize: 14, height: 1.6),
//                     ),
//                   ),
//
//                   // 위치기반 서비스 이용 약관
//                   SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Text(
//                       locationServiceTermsText,
//                       style: const TextStyle(fontSize: 14, height: 1.6),
//                     ),
//                   ),
//
//                   // 개인정보 처리방침
//                   SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Text(
//                       privacyText,
//                       style: const TextStyle(fontSize: 14, height: 1.6),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
