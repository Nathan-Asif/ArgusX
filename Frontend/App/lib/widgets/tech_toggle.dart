import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechToggle extends StatefulWidget {
  final String label;
  final String subLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TechToggle({
    super.key,
    required this.label,
    required this.subLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TechToggle> createState() => _TechToggleState();
}

class _TechToggleState extends State<TechToggle> {
  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF8E2DE2); // Purple background track
    const thumbColor = Color(0xFF2962FF); // Blue thumb
    const inactiveBorder = Color(0xFF4D4354);
    const inactiveBg = Color(0xFF161517);
    const inactiveThumb = Color(0xFF353436);

    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFE5E2E3),
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                widget.subLabel,
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF998CA0),
                  fontSize: 9.0,
                ),
              ),
            ],
          ),
          // Custom Toggle
          Container(
            width: 44.0,
            height: 22.0,
            decoration: BoxDecoration(
              color: widget.value ? activeColor : inactiveBg,
              border: Border.all(
                color: widget.value ? activeColor : inactiveBorder,
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: widget.value ? 22.0 : 0.0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 20.0,
                    decoration: BoxDecoration(
                      color: widget.value ? thumbColor : inactiveThumb,
                    ),
                    child: widget.value
                        ? const Icon(Icons.check, color: Colors.white, size: 14.0)
                        : const Icon(Icons.close, color: Color(0xFF998CA0), size: 10.0),
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
