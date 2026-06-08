import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final List<IconData> _navIcons = [
    Icons.grid_view_outlined,
    Icons.videocam_outlined,
    Icons.construction_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFDDB7FF);
    const inactiveColor = Color(0xFF4D4354);
    const glowColor = Color(0xFF8E2DE2);

    return Container(
      height: 72.0,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0F),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF353436).withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Active Indicator bar (glowing horizontal line/bracket)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuint,
            top: 0,
            left: (MediaQuery.of(context).size.width / 4) * widget.selectedIndex +
                (MediaQuery.of(context).size.width / 8) -
                25.0, // center it above the active icon
            child: Column(
              children: [
                // Glowing active bar
                Container(
                  height: 3.0,
                  width: 50.0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.8),
                        blurRadius: 10.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
                // L-shape tech brackets hanging down
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 4.0, width: 1.5, color: activeColor),
                    const SizedBox(width: 47.0),
                    Container(height: 4.0, width: 1.5, color: activeColor),
                  ],
                ),
              ],
            ),
          ),
          // Nav slots
          Positioned.fill(
            child: Row(
              children: List.generate(_navIcons.length, (index) {
                final isSelected = widget.selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _navIcons[index],
                          color: isSelected ? activeColor : inactiveColor,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
