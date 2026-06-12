import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../core/auth_controller.dart';
import '../core/server_config_store.dart';
import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/floating_background.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController auth;
  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Nhập đầy đủ thông tin đăng nhập');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.login(id, pw);
      // Root sẽ tự chuyển sang HomeScreen qua AuthController
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ. Kiểm tra Auth.API.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(auth: widget.auth)),
    );
  }

  Future<void> _editServer() async {
    final ctrl = TextEditingController(text: AppConfig.gatewayBase);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Địa chỉ server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dán URL backend (Cloudflare Tunnel / IP máy chủ).\nVD: https://abc.trycloudflare.com',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'http://10.0.2.2:5000',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (saved == true && ctrl.text.trim().isNotEmpty) {
      await ServerConfigStore.save(ctrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đặt server: ${AppConfig.gatewayBase}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FadeSlideIn(child: _AuthLogo()),
                    const SizedBox(height: 28),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 80),
                      child: Text('Chào mừng trở lại 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 6),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 120),
                      child: Text('Đăng nhập để tiếp tục học IELTS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: AuthField(
                        controller: _idCtrl,
                        hint: 'Email hoặc username',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: AuthField(
                        controller: _pwCtrl,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _login,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBox(_error!),
                    ],
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16)),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Đăng nhập',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 280),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chưa có tài khoản? ',
                              style:
                                  TextStyle(color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: _goRegister,
                            child: const Text('Đăng ký',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _editServer,
                          icon: const Icon(Icons.dns_rounded,
                              size: 16, color: AppColors.textSecondary),
                          label: const Text('Cấu hình server',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared auth widgets ──────────────────────────────────────────────────────

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onSubmit;
  final TextInputType? keyboardType;

  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.onSubmit,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction:
            onSubmit != null ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) => onSubmit?.call(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20),
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.negative, fontSize: 13))),
        ],
      ),
    );
  }
}
