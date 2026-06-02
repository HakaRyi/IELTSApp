import 'package:flutter/material.dart';
import '../services/lexical_service.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_background.dart';
import 'lookup_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = LexicalService();
  final _vaultKey = GlobalKey<VaultScreenState>();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      LookupScreen(service: _service),
      VaultScreen(key: _vaultKey, service: _service),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBackground()),
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Tra từ',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            icon: Icons.menu_book_rounded,
            label: 'Kho từ',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent])
                : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 22),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
