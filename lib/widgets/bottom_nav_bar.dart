import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,


      // 아이콘/폰트 사이즈 조절
      iconSize: 32.0,
      selectedFontSize: 14.0,
      unselectedFontSize: 12.0,

      // ─── 여기부터 추가 ───
      // 선택된 아이템의 아이콘·라벨 색
      selectedItemColor: Color(0xFF3BA7DF),
      // 선택 안 된 아이템의 아이콘·라벨 색
      unselectedItemColor: Colors.grey.shade500,

      // 선택된 라벨의 텍스트 스타일
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,  // 굵게
        fontStyle: FontStyle.normal,  // 노말
        // color: Colors.blueAccent,  // TextStyle의 color도 지정할 수 있지만,
        // selectedItemColor로 색상을 주는 것이 일반적입니다.
      ),

      // 선택 안 된 라벨의 텍스트 스타일
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        // color: Colors.grey,
      ),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home),              label: "home".tr()),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "chatbot".tr()),
        BottomNavigationBarItem(icon: Icon(Icons.history),           label: "reservation_list".tr()),
        BottomNavigationBarItem(icon: Icon(Icons.person),            label: "myinfo".tr()),
      ],
    );
  }
}