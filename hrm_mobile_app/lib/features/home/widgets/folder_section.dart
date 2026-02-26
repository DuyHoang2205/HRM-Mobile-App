import 'package:flutter/material.dart';

class FolderSection extends StatelessWidget {
  final void Function(FolderAction action) onTap;

  const FolderSection({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Demo Clean-up: Only include functional actions to ensure a polished client experience
    final items = <_FolderData>[
      const _FolderData(
        title: 'Chấm công',
        icon: Icons.fingerprint_rounded,
        action: FolderAction.attendance,
      ),
      const _FolderData(
        title: 'Phiếu lương',
        icon: Icons.attach_money_rounded,
        action: FolderAction.salary,
      ),
      const _FolderData(
        title: 'Làm ngoài giờ',
        icon: Icons.access_time_rounded,
        action: FolderAction.overtime,
      ),
      const _FolderData(
        title: 'Nghỉ phép',
        icon: Icons.calendar_month_rounded,
        action: FolderAction.leave,
      ),
      const _FolderData(
        title: 'Công tác',
        icon: Icons.work_outline_rounded,
        action: FolderAction.businessTrip,
      ),
      const _FolderData.empty(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thư mục',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B1B2B),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 12),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.83,
            ),
            itemBuilder: (context, i) {
              final item = items[i];
              if (item.isEmpty) return const SizedBox.shrink();

              return _FolderTile(
                title: item.title!,
                icon: item.icon!,
                onTap: () => onTap(item.action!),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Keep the enum values so existing logic doesn't break, but we only use 'attendance' for the demo
enum FolderAction { attendance, salary, overtime, leave, businessTrip }

class _FolderData {
  final String? title;
  final IconData? icon;
  final FolderAction? action;
  final bool isEmpty;

  const _FolderData({
    required this.title,
    required this.icon,
    required this.action,
  }) : isEmpty = false;

  const _FolderData.empty()
      : title = null,
        icon = null,
        action = null,
        isEmpty = true;
}

class _FolderTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _FolderTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final iconSize = w < 110 ? 26.0 : 30.0;
        final bubble = w < 110 ? 50.0 : 56.0;
        final fontSize = w < 110 ? 13.5 : 15.0;
        final gap = w < 110 ? 10.0 : 12.0;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: bubble,
                    height: bubble,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9F1FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: const Color(0xFF0B2D5B),
                    ),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: fontSize * 2.3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B1B2B),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}