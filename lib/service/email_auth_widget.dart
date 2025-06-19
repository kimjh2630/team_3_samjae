import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:project/widgets/language_dialog.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class EmailAuthWidget extends StatefulWidget {
  final Future<void> Function(String email, String nickname, String password) onLoginSuccess;

  const EmailAuthWidget({
    Key? key,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<EmailAuthWidget> createState() => _EmailAuthWidgetState();
}

class _EmailAuthWidgetState extends State<EmailAuthWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLogin = true; // true: 로그인, false: 회원가입
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // 이메일 유효성 검사
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "enterEmail".tr();
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "invalidEmailFormat".tr();
    }
    return null;
  }

  // 비밀번호 유효성 검사
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "enterPassword".tr();
    }
    if (value.length < 6) {
      return "passwordTooShort".tr();
    }
    return null;
  }

  // 닉네임 유효성 검사
  String? _validateNickname(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return "enterNickname".tr();
    }
    return null;
  }

  // 폼 제출 처리
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      print('이메일 : \\${_emailController.text}');
      print('비밀번호 : \\${_passwordController.text}');
      if (_isLogin) {
        // 로그인 처리 (API 호출)
        final response = await AuthService.login({
          'email': _emailController.text,
          'password': _passwordController.text,
          'platform': 'local',
        });
        print('로그인 응답: \\${response.statusCode} \\${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          await AuthService.saveToken(data['access_token']);
          await AuthService.saveUserInfo(data['email'], data['platform']);
          await AuthService.saveRefreshToken(data['refresh_token']);
          await AuthService.saveNickname(data['nickname']);
          Provider.of<AppState>(context, listen: false).nickname = data['nickname'];
          await widget.onLoginSuccess(
            data['email'],
            data['nickname'],
            _passwordController.text,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text( "loginSuccess".tr(),
                  style: TextStyle(color: Colors.green),
                ),
                backgroundColor: Colors.white,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            final msg = jsonDecode(utf8.decode(response.bodyBytes))['detail'] ?? "loginFailed".tr();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${"loginFailed".tr()} : $msg',
                  style: TextStyle(color: Colors.red),
                ),
                backgroundColor: Colors.white,
              ),
            );
          }
        }
      } else {
        // 회원가입 처리 (API 호출)
        await _register();
      }
    }
  }

  //회원가입 함수
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await AuthService.register({
          'email': _emailController.text,
          'password': _passwordController.text,
          'nickname': _nicknameController.text,
          'platform': 'local',
        });
        print('회원가입 응답: \\${response.statusCode} \\${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("signupComplete".tr()),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            setState(() {
              _isLogin = true;
              _emailController.clear();
              _passwordController.clear();
              _nicknameController.clear();
            });
          }
        } else {
          if (mounted) {
            final msg = jsonDecode(utf8.decode(response.bodyBytes))['detail'] ?? "signupFailed".tr();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${"signupFailed".tr()}: $msg'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${"detail.error".tr()} : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

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
        centerTitle: false,
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40), // 상단 여백 추가
                  Text(
                    _isLogin ? "login".tr() : "signup".tr(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "email".tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return  "enterEmail".tr();
                      }
                      if (!value.contains('@')) {
                        return "invalidEmailFormat".tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "password".tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "enterPassword".tr();
                      }
                      if (value.length < 6) {
                        return "passwordTooShort".tr();
                      }
                      return null;
                    },
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        labelText: "nickname".tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "enterNickname".tr();
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4BB8EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isLogin ? "login".tr() : "signup".tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailController.clear();
                        _passwordController.clear();
                        if (!_isLogin) {
                          _nicknameController.clear();
                        }
                      });
                    },
                    child: Text(
                      _isLogin ? "noAccountSignup".tr() : "alreadyHaveAccount".tr(),
                      style: TextStyle(
                        color: Color(0xFF146DA3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // 하단 여백 추가
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}