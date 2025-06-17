import 'package:flutter/material.dart';
import 'package:project/profile/EditProfilePage.dart';
import 'package:project/profile/TermsPrivacyScreen.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/service/social_login.dart';
import 'package:project/widgets/language_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:project/widgets/nav_main_page.dart';


class ProfileScreen extends StatelessWidget {
  final String? nickname;
  const ProfileScreen({Key? key, this.nickname}) : super(key: key);

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
                nickname ?? '테스트',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // 개인정보 섹션
              _buildProfileSection(
                title: '개인정보',
                items: [
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: '내 정보 수정',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>   EditProfilePage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 고객센터 섹션
              _buildProfileSection(
                title: '고객센터',
                items: [
                  ProfileMenuItem(
                    icon: Icons.notifications_none,
                    title: '공지사항',
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    icon: Icons.language,
                    title: '약관 및 개인정보 처리 동의',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TermsPrivacyPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 기타 섹션
              _buildProfileSection(
                title: '기타',
                items: [
                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: '도움말',
                    onTap: () {},
                  ),
                  ProfileMenuItem(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 로그아웃 섹션
              _buildProfileSection(
                title: '로그 아웃',
                items: [
                  Center(
                    child: TextButton(
                      onPressed: () {
                        AuthService.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginWidget()),
                              (route) => false,
                        );
                      },
                      child: const Text('로그 아웃 하기'),
                    ),
                  ),
                ],
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
