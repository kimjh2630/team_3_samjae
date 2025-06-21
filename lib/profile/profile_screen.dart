import 'package:flutter/material.dart';
import 'package:project/profile/AppInfoPage.dart';
import 'package:project/profile/EditProfilePage.dart';
import 'package:project/profile/HelpPage.dart';
import 'package:project/profile/NoticePage.dart';
import 'package:project/profile/TermsPrivacyScreen.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/service/social_login.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:project/widgets/nav_main_page.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  final String _url = 'https://www.freeprivacypolicy.com/live/98c95c6c-778b-457c-bbf2-e77eefc8c442';

  void _launchURL() async {
    final uri = Uri.parse(_url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // 실패 시 처리
      throw '해당 URL을 열 수 없습니다: $_url';
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showDeleteForm = false;

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LanguageDialog(),
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final nickname = Provider.of<AppState>(context).nickname;
    final isLoggedIn = Provider.of<AppState>(context).isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => nav_MainPage(initialIndex: 0)),
                  (route) => false,
            );
          },
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "myinfo".tr(),
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageDialog(context),
            tooltip: 'language_selection'.tr(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                "${(nickname == null || nickname.isEmpty || nickname == '비회원')
                    ? "please_log_in".tr() : nickname}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // 개인정보 섹션
              _buildProfileSection(
                title: "personalInformation".tr(),
                items: [
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title:"editProfile".tr(),
                    onTap: () async {
                      if (!isLoggedIn) {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AlertDialog(

                                title: Text("notification".tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),),
                                content: Text( "log_in".tr(),
                                textAlign: TextAlign.center,),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("ok".tr()),
                                  ),
                                ],
                              ),
                        );
                        return;
                      }

                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfilePage(currentNickname: nickname),
                        ),
                      ).then((result) {
                        if (result == true) {}
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 안내 섹션
              _buildProfileSection(
                title: "guide".tr(),
                items: [
                  ProfileMenuItem(
                    icon: Icons.notifications_none,
                    title: "announcements".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                      MaterialPageRoute(
                        builder: (_) => const NoticePage()
                      ),
                      );
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: "agreeToTermsAndPrivacy".tr(),
                    onTap: () async {
                      final url = Uri.parse('https://www.freeprivacypolicy.com/live/98c95c6c-778b-457c-bbf2-e77eefc8c442');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication); // 브라우저에서 열기
                      } else {
                        // 오류 처리
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('링크를 열 수 없습니다.')),
                        );
                      }
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    title:  "help".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpPage()
                        ),
                      );
                    },
                  ),
                  ProfileMenuItem(
                    icon: Icons.info_outline,
                    title: "appInfo".tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppInfoPage()
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 최하단 로그아웃 텍스트버튼
              Center(
                child: TextButton(
                  onPressed: () async {
                    if (isLoggedIn) {
                      // 로그아웃
                      await AuthService.logout();
                      Provider.of<AppState>(context, listen: false).setLoggedIn(false);
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginWidget()),
                              (route) => false,
                        );
                      }
                    } else {
                      // 로그인 안 된 상태 → 로그인 화면으로
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginWidget()),
                      );
                    }
                  },
                  child: Text(
                    isLoggedIn ? "logout".tr() : "login".tr(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 단순 메뉴 아이템 위젯
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black54),
            const SizedBox(width: 12),
            Text(title,
                style:
                const TextStyle(fontSize: 16, color: Colors.black87)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
