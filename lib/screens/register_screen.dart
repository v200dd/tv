import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/user_data_service.dart';
import '../utils/font_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _inviteCode = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final base = (await UserDataService.getServerUrl() ??
              UserDataService.defaultServerUrl)
          .replaceAll(RegExp(r'/+$'), '');
      final response = await http
          .post(Uri.parse('$base/api/register'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': _username.text.trim(),
                'password': _password.text,
                'confirmPassword': _confirmPassword.text,
                'inviteCode': _inviteCode.text.trim()
              }))
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw Exception(data['error']?.toString() ?? '注册失败');
      final cookie =
          response.headers['set-cookie']?.split(';').first.trim() ?? '';
      await UserDataService.saveUserData(
          serverUrl: base,
          username: _username.text.trim(),
          password: _password.text,
          cookies: cookie);
      await UserDataService.saveIsLocalMode(false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('注册成功')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController controller, String label, String hint,
          {bool obscure = false, bool required = true}) =>
      TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none)),
          validator: (value) {
            if (!required && (value == null || value.isEmpty)) return null;
            if (value == null || value.trim().isEmpty) return '请输入$label';
            if (label == '密码' && value.length < 6) return '密码长度至少6位';
            if (label == '确认密码' && value != _password.text) return '两次输入的密码不一致';
            if (label == '账号' &&
                !RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(value))
              return '账号格式不正确';
            return null;
          });

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text('设置账号和密码',
                        style: FontUtils.poppins(
                            fontSize: 24, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 28),
                    _field(_username, '账号', '3-20位字母、数字或下划线'),
                    const SizedBox(height: 16),
                    _field(_password, '密码', '至少6位', obscure: true),
                    const SizedBox(height: 16),
                    _field(_confirmPassword, '确认密码', '再次输入密码', obscure: true),
                    const SizedBox(height: 16),
                    _field(_inviteCode, '邀请码（如需要）', '没有邀请码可留空',
                        required: false),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(_loading ? '注册中...' : '立即注册'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
