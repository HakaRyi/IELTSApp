import 'package:flutter/material.dart';
import '../core/auth_controller.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController auth;
  const RegisterScreen({super.key, required this.auth});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (email.isEmpty || user.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Nhập đầy đủ email, username và mật khẩu');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.register(
        email: email,
        username: user,
        password: pw,
        displayName: name,
      );
      // Root tự chuyển sang HomeScreen
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ. Kiểm tra Auth.API.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const FadeSlideIn(
                    child: Text('Tạo tài khoản',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 6),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 80),
                    child: Text('Bắt đầu hành trình chinh phục IELTS',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AuthField(
                      controller: _nameCtrl,
                      hint: 'Tên hiển thị (tuỳ chọn)',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: AuthField(
                      controller: _emailCtrl,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: AuthField(
                      controller: _userCtrl,
                      hint: 'Username',
                      icon: Icons.alternate_email_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 210),
                    child: AuthField(
                      controller: _pwCtrl,
                      hint: 'Mật khẩu (ít nhất 6 ký tự)',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      onToggleObscure: () =>
                          setState(() => _obscure = !_obscure),
                      onSubmit: _register,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.negative.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.negative, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.negative,
                                      fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Đăng ký',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đã có tài khoản? ',
                            style: TextStyle(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Đăng nhập',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
