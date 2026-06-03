import 'package:flutter/material.dart';
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
  const HomeScreen({super.key});

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
