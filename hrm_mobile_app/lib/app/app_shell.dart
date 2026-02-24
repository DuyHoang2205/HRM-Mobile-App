import 'package:flutter/material.dart';
import 'package:hrm_mobile_app/features/home/view/home_page.dart';
import '../../../core/widgets/placeholder_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _isMenuOpen = false;

  final _pages = const [
    HomePage(),
    PlaceholderPage(title: 'My task'),
    PlaceholderPage(title: 'Payment'),
    PlaceholderPage(title: 'Profile'),
  ];

// 1. Change to async
Future<void> _openPlusMenu() async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final size = overlay.size;

  setState(() => _isMenuOpen = true);

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'PlusMenu',
    barrierColor: Colors.black.withOpacity(0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _PlusMenuOverlay(screenSize: size),
    transitionBuilder: (_, animation, __, child) {
      return Transform.scale(
        scale: Curves.easeOutBack.transform(animation.value),
        child: Opacity(opacity: animation.value, child: child),
      );
    },
  );

  // This line runs ONLY after the menu is closed
  setState(() => _isMenuOpen = false);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: IndexedStack(
        index: _index,
        children: _pages,
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 75, 
        height: 75,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0B2A5B),
          elevation: 8,
          shape: const CircleBorder(),
          onPressed: _openPlusMenu,
          // Change icon and color based on state
          child: Icon(
            _isMenuOpen ? Icons.close : Icons.add, 
            size: 30, 
            color: Colors.white, // Now explicitly white
          ),
        ),
      ),

bottomNavigationBar: Transform.translate(
        offset: const Offset(0, 12.0), 
        child: BottomAppBar(
          color: Colors.white,
          elevation: 10,
          shadowColor: const Color(0x14000000),
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          padding: EdgeInsets.zero,
          height: 80, 
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'My task',
                  icon: Icons.task_alt_outlined,
                  activeIcon: Icons.task_alt,
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
              ),
              const SizedBox(width: 62), 
              Expanded(
                child: _NavItem(
                  label: 'Payment',
                  icon: Icons.attach_money_outlined,
                  activeIcon: Icons.attach_money,
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  label: 'Profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0B2A5B) : const Color(0xFF9AA6B2);

    return InkWell(
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max, 
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlusMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          // We use start alignment so the text starts right after the icon
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. Fixed width container for the icon
            SizedBox(
              width: 24, 
              child: Icon(icon, color: const Color(0xFF0B2A5B), size: 22),
            ),
            const SizedBox(width: 16), 

            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1B2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusMenuOverlay extends StatelessWidget {
  final Size screenSize;

  const _PlusMenuOverlay({required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final fabCenterY = screenSize.height - (48 + bottomInset) - 37;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.transparent),
        ),

        Positioned(
          bottom: screenSize.height - (fabCenterY - 20),
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: IntrinsicWidth( // This makes the box only as wide as your longest text
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _PlusMenuItem(icon: Icons.event_available, label: 'Đăng ký nghỉ phép'),
                      _PlusMenuItem(icon: Icons.timelapse, label: 'Đăng ký làm thêm'),
                      _PlusMenuItem(icon: Icons.flight_takeoff, label: 'Đăng ký công tác'),
                      _PlusMenuItem(icon: Icons.receipt_long, label: 'Giải trình chấm công'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
