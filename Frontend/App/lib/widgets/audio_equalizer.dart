import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioEqualizer extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const AudioEqualizer({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<AudioEqualizer> createState() => _AudioEqualizerState();
}

class _AudioEqualizerState extends State<AudioEqualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<double> _baseHeights = [0.2, 0.4, 0.6, 0.3, 0.5, 0.8, 0.2, 0.1];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFDDB7FF);
    final inactiveColor = const Color(0xFF4D4354).withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MASTER_OUTPUT_GAIN',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFE5E2E3),
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16.0),
        // Animated Equalizer Bars
        SizedBox(
          height: 60.0,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_baseHeights.length, (index) {
                  // Mix base height with animation and overall value
                  final heightFactor = _baseHeights[index] + 
                      (index % 2 == 0 ? _animController.value * 0.2 : -_animController.value * 0.2);
                  final adjustedHeight = (heightFactor.clamp(0.1, 1.0) * 60.0) * (widget.value / 100).clamp(0.2, 1.0);
                  
                  return Container(
                    width: 24.0,
                    height: adjustedHeight,
                    color: activeColor.withValues(alpha: 0.9),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 16.0),
        // Slider and Value
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: activeColor.withValues(alpha: 0.5),
                  inactiveTrackColor: inactiveColor,
                  thumbColor: activeColor,
                  overlayColor: activeColor.withValues(alpha: 0.2),
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                ),
                child: Slider(
                  value: widget.value,
                  min: 0,
                  max: 100,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              '${widget.value.toInt()}dB',
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFE5E2E3),
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
