import 'package:flutter/material.dart';

class CheckInTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const CheckInTopBar({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      height: topInset + 56,
      color: Colors.white, // paints the notch area too
      child: Column(
        children: [
          SizedBox(height: topInset), // status bar space
          Container(
            height: 56,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x11000000))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 56), // left spacer to balance the close button
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B2B),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onClose,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.close,
                            size: 22, color: Color(0xFF9AA6B2)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
