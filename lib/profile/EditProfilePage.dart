import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:project/service/auth_service.dart';
import 'package:project/service/social_login.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:project/service/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class EditProfilePage extends StatefulWidget {
  final String? currentNickname;
  const EditProfilePage({Key? key, this.currentNickname}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nicknameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _newNickCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _newPwCheckCtrl = TextEditingController();
  String? _email;
  String? _platform;
  bool _showNicknameForm = false;
  bool _showPasswordForm = false;
  bool _showDeleteForm   = false;
  bool _isNickLoading = false;
  bool _isPwLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await AuthService.getUserInfo();
    setState(() {
      _email = info['email'];
      _platform = info['platform'];
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Provider.of<AppState>(context, listen: false).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginWidget()),
    );
  }

  void _onNicknameSave() async {
    if (_nicknameFormKey.currentState?.validate() ?? false) {
      if (_email == null || _platform == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("loginInfoMissing".tr())),
        );
        return;
      }
      setState(() { _isNickLoading = true; });
      final response = await AuthService.updateUser(
        _email!,
        _platform!,
        {"nickname": _newNickCtrl.text.trim()},
      );
      setState(() { _isNickLoading = false; });
      if (response.statusCode == 200) {
        final newNickname = _newNickCtrl.text.trim();
        await AuthService.saveNickname(newNickname);
        final appState = Provider.of<AppState>(context, listen: false);
        appState.nickname = newNickname;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("nicknameChanged".tr())),
        );
        setState(() { _showNicknameForm = false; });
        FocusScope.of(context).unfocus();
        Navigator.pop(context, true);
      } else {
        final msg = jsonDecode(utf8.decode(response.bodyBytes))["detail"] ?? '닉네임 변경 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임 변경 실패: $msg')),
        );
      }
    }
  }

  void _onPasswordSave() async {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      if (_email == null || _platform == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("loginInfoMissing".tr())),
        );
        return;
      }
      setState(() { _isPwLoading = true; });
      final response = await AuthService.updateUser(
        _email!,
        _platform!,
        {"password": _newPwCtrl.text.trim()},
      );
      setState(() { _isPwLoading = false; });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("passwordChanged".tr())),
        );
        setState(() { _showPasswordForm = false; });
        FocusScope.of(context).unfocus();
        Navigator.pop(context, true);
      } else {
        final msg = jsonDecode(utf8.decode(response.bodyBytes))["detail"] ?? '비밀번호 변경 실패';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호 변경 실패: $msg')),
        );
      }
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool expanded = false,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.black54),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.arrow_forward_ios, size: 18, color: Colors.black38),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: child),
          const Divider(height: 1, color: Colors.grey),
        ],
      ],
    );
  }

  Widget _buildDeleteAccountAccordion() {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showDeleteForm = !_showDeleteForm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 22, color: Colors.red),
                const SizedBox(width: 12),
                Text("accountDeletion".tr(),
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(_showDeleteForm ? Icons.expand_less : Icons.arrow_forward_ios,
                    size: 18, color: Colors.black38),
              ],
            ),
          ),
        ),
        if (_showDeleteForm) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "accountDeletionWarning".tr(),
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("confirmAccountDeletion".tr()),
                        content: Text("accountDeletionWarning".tr()),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('취소')),
                          ElevatedButton(
                            style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text("accountDeletion".tr()),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;

                    // — 로컬 탈퇴 API 호출
                    if (_email == null || _platform == null) return;
                    final resp = await AuthService.deleteAccount(
                      _email!, _platform!,
                    );
                    if (resp.statusCode == 200) {
                      await _logout();  // 위에서 만든 로그아웃 메서드로 이동
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("accountDeletionComplete".tr())),
                      );
                    } else {
                      final msg = utf8.decode(resp.bodyBytes);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${"accountDeletionFailed".tr()}: $msg')),
                      );
                    }
                  },
                  child: Text("deleteAccount".tr(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
        ],
      ],
    );
  }

  // 기존 회원 탈퇴 로직
  // Widget _buildDeleteAccountAccordion() {
  //   return Column(
  //     children: [
  //       InkWell(
  //         onTap: () => setState(() { _showDeleteForm = !_showDeleteForm; }),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  //           child: Row(
  //             children: [
  //               const Icon(Icons.delete_outline, size: 22, color: Colors.red),
  //               const SizedBox(width: 12),
  //               Text("accountDeletion".tr(), style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
  //               const Spacer(),
  //               Icon(_showDeleteForm ? Icons.expand_less : Icons.arrow_forward_ios, size: 18, color: Colors.black38),
  //             ],
  //           ),
  //         ),
  //       ),
  //       if (_showDeleteForm) ...[
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: [
  //               Text(
  //                 "accountDeletionWarning".tr(),
  //                 style: TextStyle(color: Colors.red, fontSize: 14),
  //               ),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.red,
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                 ),
  //                 onPressed: () async {
  //                   final confirmed = await showDialog<bool>(
  //                     context: context,
  //                     builder: (context) => AlertDialog(
  //                       title: Text("confirmAccountDeletion".tr()),
  //                       content: Text("accountDeletionWarning".tr()),
  //                       actions: [
  //                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
  //                         ElevatedButton(
  //                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //                           onPressed: () => Navigator.pop(context, true),
  //                           child: Text("accountDeletion".tr()),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                   if (confirmed == true) {
  //                     final info     = await AuthService.getUserInfo();
  //                     final email    = info['email'];
  //                     final platform = info['platform'];
  //                     if (email != null && platform != null) {
  //                       try {
  //                             // 1) DB에서 레코드 삭제
  //                             final removed = await DatabaseService()
  //                                 .deleteUser(email: email, loginPlatform: platform);
  //                             if (!removed) throw 'DB 삭제 실패';
  //
  //                             // 2) Firebase Auth 계정 삭제
  //                             final user = FirebaseAuth.instance.currentUser;
  //                             if (user != null) {
  //                               await user.delete();
  //                               // 3) 구글 세션 종료
  //                               await GoogleSignIn().signOut();
  //                             }
  //
  //                             // 4) 앱 상태 초기화
  //                             Provider.of<AppState>(context, listen: false).setLoggedIn(false);
  //                             Provider.of<AppState>(context, listen: false).nickname = null;
  //
  //                             // 5) 로그인 화면으로 돌아가기
  //                             if (!mounted) return;
  //                             ScaffoldMessenger.of(context).showSnackBar(
  //                               SnackBar(content: Text("accountDeletionComplete".tr())),
  //                             );
  //                             Navigator.pushAndRemoveUntil(
  //                               context,
  //                               MaterialPageRoute(builder: (_) => const LoginWidget()),
  //                               (route) => false,
  //                             );
  //                           } catch (e) {
  //                             if (!mounted) return;
  //                             ScaffoldMessenger.of(context).showSnackBar(
  //                               SnackBar(content: Text('${"accountDeletionFailed".tr()}: $e')),
  //                             );
  //                           }
  //                     }
  //                   }
  //                 },
  //                 child: Text(
  //                   "deleteAccount".tr(),
  //                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const Divider(height: 1, color: Colors.grey),
  //       ],
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF6),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
        title: Text("editProfile".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
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
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: "changeNickname".tr(),
                  expanded: _showNicknameForm,
                  onTap: () {
                    setState(() {
                      _showNicknameForm = !_showNicknameForm;
                      if (_showNicknameForm) _showPasswordForm = false;
                    });
                  },
                  child: Form(
                    key: _nicknameFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text("currentNickname".tr(), style: TextStyle(fontSize: 15, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(widget.currentNickname ?? "noNickname".tr(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _newNickCtrl,
                          decoration: InputDecoration(
                            labelText: "newNickname".tr(),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "enterNickname".tr();
                            if (v.trim().length < 2) return "nicknameTooShort".tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3BA7DF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isNickLoading ? null : _onNicknameSave,
                            child: _isNickLoading
                                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text("saveNickname".tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.grey),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: "changePassword".tr(),
                  expanded: _showPasswordForm,
                  onTap: () {
                    setState(() {
                      _showPasswordForm = !_showPasswordForm;
                      if (_showPasswordForm) _showNicknameForm = false;
                    });
                  },
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _currentPwCtrl,
                          decoration: InputDecoration(
                            labelText: "currentPassword".tr(),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "enterCurrentPassword".tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPwCtrl,
                          decoration: InputDecoration(
                            labelText: "newPassword".tr(),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "enterNewPassword".tr();
                            if (v.length < 6) return "passwordTooShort".tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPwCheckCtrl,
                          decoration: InputDecoration(
                            labelText: "confirmNewPassword".tr(),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return  "reenterNewPassword".tr();
                            if (v != _newPwCtrl.text) return "passwordMismatch".tr();
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3BA7DF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isPwLoading ? null : _onPasswordSave,
                            child: _isPwLoading
                                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text("savePassword".tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // 회원 탈퇴 아코디언
                _buildDeleteAccountAccordion(),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
