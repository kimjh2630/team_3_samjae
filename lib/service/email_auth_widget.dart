import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:project/widgets/language_dialog.dart';
import 'database_service.dart';

class EmailAuthWidget extends StatefulWidget {
  final Function(String email, String nickname, String password) onLoginSuccess;

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
  final DatabaseService _db = DatabaseService();
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
      return '이메일을 입력해주세요';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  // 비밀번호 유효성 검사
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }
    return null;
  }

  // 닉네임 유효성 검사
  String? _validateNickname(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return '닉네임을 입력해주세요';
    }
    return null;
  }

  // 폼 제출 처리
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      print('이메일 : ${_emailController.text}');
      print('비밀번호 : ${_passwordController.text}');
      if (_isLogin) {
        // 로그인 처리
        final result = await _db.loginWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (result != null) {
          final email = result['email']?.toString() ?? 'unknown@example.com';
          final password = result['password']?.toString() ?? '';
          final nicknameRaw = result['nickname'];
          final nickname = (nicknameRaw is String && nicknameRaw.trim().isNotEmpty)
              ? nicknameRaw
              : '익명';
          widget.onLoginSuccess(email, nickname, password);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로그인에 성공했습니다.',
                style: TextStyle(color: Colors.green),
                ),
                backgroundColor: Colors.white,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('로그인 실패 : 이메일 또는 비밀번호가 올바르지 않습니다',
                  style: TextStyle(color: Colors.red),
                ),
                backgroundColor: Colors.white,
              ),
            );
          }
        }
      } else {
        // 회원가입 처리
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
        final success = await _db.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          nickname: _nicknameController.text,
        );

        if (success) {
          if (mounted) {
            // 회원가입 성공 메시지 표시
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('회원가입이 완료되었습니다.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // 로그인 화면으로 전환
            setState(() {
              _isLogin = true;
              _emailController.clear();
              _passwordController.clear();
              _nicknameController.clear();
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('회원가입에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
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
      backgroundColor: Colors.indigo.shade50,
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
                  const SizedBox(height: 40), // 상단 여백 추가
                  Text(
                    _isLogin ? '로그인' : '회원가입',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요';
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
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isLogin ? '로그인' : '회원가입'),
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
                      _isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인',
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