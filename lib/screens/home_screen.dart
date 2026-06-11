import 'package:flutter/material.dart';
import '../core/auth_controller.dart';
import '../services/lexical_service.dart';
import '../services/practice_service.dart';
import '../services/review_service.dart';
import '../services/speaking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_background.dart';
import 'history_screen.dart';
import 'lookup_screen.dart';
import 'practice_screen.dart';
import 'review_screen.dart';
import 'speaking_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthController auth;
  const HomeScreen({super.key, required this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _lexicalService  = LexicalService();
  final _practiceService = PracticeService();
  final _speakingService = SpeakingService();
  final _reviewService   = ReviewService();
  final _vaultKey = GlobalKey<VaultScreenState>();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LookupScreen(service: _lexicalService),
      VaultScreen(key: _vaultKey, service: _lexicalService),
      PracticeScreen(
          lexicalService: _lexicalService,
          practiceService: _practiceService),
      SpeakingScreen(
          lexicalService: _lexicalService,
          speakingService: _speakingService),
      HistoryScreen(
          practiceService: _practiceService,
          speakingService: _speakingService),
      ReviewScreen(reviewService: _reviewService),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBackground()),
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: pages[_index],
              ),
            ),
          ),
          // Profile / logout button — góc trên phải
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: _ProfileButton(auth: widget.auth),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingNavBar(
        index: _index,
        onChanged: (i) {
          setState(() => _index = i);
          if (i == 1) _vaultKey.currentState?.refresh();
        },
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _FloatingNavBar({required this.index, required this.onChanged});

  static const _items = [
    _NavDef(Icons.search_rounded, 'Tra từ'),
    _NavDef(Icons.menu_book_rounded, 'Kho từ'),
    _NavDef(Icons.auto_stories_rounded, 'Đọc'),
    _NavDef(Icons.record_voice_over_rounded, 'Nói'),
    _NavDef(Icons.history_rounded, 'Lịch sử'),
    _NavDef(Icons.psychology_rounded, 'Ôn tập'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: _items.asMap().entries.map((e) {
          final i = e.key;
          final def = e.value;
          final sel = index == i;
          return Expanded(
            flex: sel ? 3 : 2,
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                    vertical: 10, horizontal: sel ? 6 : 0),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent])
                      : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(def.icon,
                        color: sel
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 20),
                    if (sel) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          def.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavDef {
  final IconData icon;
  final String label;
  const _NavDef(this.icon, this.label);
}

// ─── Profile / logout button ──────────────────────────────────────────────────

class _ProfileButton extends StatelessWidget {
  final AuthController auth;
  const _ProfileButton({required this.auth});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất',
                  style: TextStyle(color: AppColors.negative))),
        ],
      ),
    );
    if (ok == true) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    final initial = (user?.displayName.isNotEmpty == true
            ? user!.displayName
            : (user?.username ?? '?'))
        .characters
        .first
        .toUpperCase();

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) {
        if (v == 'logout') _confirmLogout(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName.isNotEmpty == true
                  ? user!.displayName
                  : (user?.username ?? ''),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              if (user?.email.isNotEmpty == true)
                Text(user!.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.negative),
              SizedBox(width: 10),
              Text('Đăng xuất',
                  style: TextStyle(color: AppColors.negative)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
    );
  }
}
