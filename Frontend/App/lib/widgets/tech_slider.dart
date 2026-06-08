import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechSlider extends StatefulWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final List<String>? tickLabels;

  const TechSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.tickLabels,
  });

  @override
  State<TechSlider> createState() => _TechSliderState();
}

class _TechSliderState extends State<TechSlider> {
  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFDDB7FF);
    const glowColor = Color(0xFF8E2DE2);
    final inactiveColor = const Color(0xFF4D4354).withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFE5E2E3),
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              widget.valueLabel,
              style: GoogleFonts.spaceGrotesk(
                color: activeColor,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: activeColor.withValues(alpha: 0.8),
            inactiveTrackColor: inactiveColor,
            thumbColor: activeColor,
            overlayColor: glowColor.withValues(alpha: 0.2),
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.tickLabels != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: widget.tickLabels!.map((label) {
                return Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF4D4354),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
