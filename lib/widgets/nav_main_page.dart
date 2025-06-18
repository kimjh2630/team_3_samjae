import 'package:flutter/material.dart';
import 'package:project/chat_bot/chatbot_screen.dart';
import 'package:project/hospital/hospital_main.dart';
import 'package:project/profile/profile_screen.dart';
import 'package:project/reservation/reservation_list_page.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class nav_MainPage extends StatefulWidget {
  final int initialIndex;
  const nav_MainPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _nav_MainPageState createState() => _nav_MainPageState();
}

class _nav_MainPageState extends State<nav_MainPage> {
  late int _currentIndex;

  @override
  void initState(){
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant nav_MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 닉네임을 직접 구독
    final nickname = Provider.of<AppState>(context).nickname;
    final List<Widget> pages = [
      HospitalMainPage(),
      ChatbotScreen(),
      ReservationListPage(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabChange,
      ),
    );
  }
}
