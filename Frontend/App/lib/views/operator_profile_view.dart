import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/tech_panel.dart';

class OperatorProfileView extends StatefulWidget {
  const OperatorProfileView({super.key});

  @override
  State<OperatorProfileView> createState() => _OperatorProfileViewState();
}

class _OperatorProfileViewState extends State<OperatorProfileView> with AutomaticKeepAliveClientMixin {
  // PRD §5.2: User profile configuration fields
  String _riderHandle = 'RIDER_NEO';
  String _selectedHelmet = 'AGV SportModular Carbon';
  bool _audioAlerts = true;
  bool _sentryVisionPassive = true;
  double _hudSensitivity = 75.0;
  String _accentTheme = 'VIOLET';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const activeColor = Color(0xFFDDB7FF);   // primary per design.md
    const glowColor = Color(0xFF8E2DE2);     // primary-container
    const dimColor = Color(0xFF998CA0);      // outline
    const surfaceColor = Color(0xFF0E0E0F);  // surface-container-lowest

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Text(
            'OPERATOR\nPROFILE',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFE5E2E3),
              fontSize: 28.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Configure identity, HUD preferences, and review personal safety telemetry.',
            style: GoogleFonts.inter(
              color: dimColor,
              fontSize: 11.0,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16.0),

          // ── Session status chip — rectangular per design.md §Status Chips ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF131314).withValues(alpha: 0.8),
                  border: Border.all(color: const Color(0xFF353436), width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square status dot per design.md §Status Chips
                    Container(
                      height: 6.0,
                      width: 6.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF), // status_active cyan
                        boxShadow: [BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4.0, spreadRadius: 1.0)],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'SESSION: NEO_SECURE',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00E5FF),
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // ── 1. RIDER SAFETY INDEX ─────────────────────────────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RIDER.SAFETY INDEX',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.shield_outlined, color: Color(0xFF998CA0), size: 16.0),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                Row(
                  children: [
                    // Score ring — Square border, not circular frame
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '96',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFE5E2E3),
                              fontSize: 28.0,
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 10.0)],
                            ),
                          ),
                          Text(
                            'SCORE',
                            style: GoogleFonts.inter(
                              color: dimColor,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIER 1 // MASTER OPERATOR',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFFE5E2E3),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Top 5% of global operators. Avg hazard response: 165ms.',
                            style: GoogleFonts.inter(
                              color: dimColor,
                              fontSize: 11.0,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Telemetry stat row — vertical dividers per design.md §Layout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCell(label: 'MILES LOGGED', value: '1,248'),
                    Container(height: 28.0, width: 1.0, color: const Color(0xFF353436)),
                    _StatCell(label: 'INTERVENTIONS', value: '18'),
                    Container(height: 28.0, width: 1.0, color: const Color(0xFF353436)),
                    _StatCell(label: 'AVG SPEED', value: '64 km/h'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ── 2. OPERATOR IDENTIFICATION ────────────────────────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OPERATOR.ID PROFILE',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.person_outlined, color: Color(0xFF998CA0), size: 16.0),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Rider handle input — design.md §Input Fields: label above, violet active glow
                Text(
                  'RIDER_HANDLE',
                  style: GoogleFonts.inter(
                    color: dimColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436), width: 1.0),
                    color: surfaceColor,
                  ),
                  child: TextField(
                    controller: TextEditingController(text: _riderHandle),
                    onChanged: (v) => setState(() => _riderHandle = v),
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFFE5E2E3),
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: glowColor, width: 1.0),
                        borderRadius: BorderRadius.zero,
                      ),
                      hintText: 'ENTER OPERATOR DESIGNATION...',
                      hintStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF4D4354), fontSize: 12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Helmet selector
                Text(
                  'CALIBRATED_HELMET',
                  style: GoogleFonts.inter(
                    color: dimColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436), width: 1.0),
                    color: surfaceColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedHelmet,
                      dropdownColor: const Color(0xFF131314),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFDDB7FF)),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                      items: <String>[
                        'AGV SportModular Carbon',
                        'Shoei RF-1400 SmartSentry',
                        'Arai Regent-X Edge',
                      ].map<DropdownMenuItem<String>>((String v) {
                        return DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        );
                      }).toList(),
                      onChanged: (v) { if (v != null) setState(() => _selectedHelmet = v); },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ── 3. HUD DEVICE CALIBRATION ─────────────────────────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HUD.DEVICE CALIBRATION',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.tune_outlined, color: Color(0xFF998CA0), size: 16.0),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Sensitivity slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HAZARD_TRIGGER_SENSITIVITY',
                      style: GoogleFonts.inter(
                        color: dimColor,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${_hudSensitivity.toInt()}%',
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
                    activeTrackColor: glowColor,
                    inactiveTrackColor: const Color(0xFF353436),
                    thumbColor: activeColor,
                    overlayColor: glowColor.withValues(alpha: 0.15),
                    thumbShape: const RectangularSliderThumbShape(), // 0px — square per design.md
                    trackHeight: 2.0,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _hudSensitivity,
                    min: 10,
                    max: 100,
                    onChanged: (v) => setState(() => _hudSensitivity = v),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Audio alerts toggle
                _ToggleRow(
                  label: 'AUXILIARY_AUDIO_WARNINGS',
                  subLabel: 'Transmit chirps into helmet intercom on hazard alerts.',
                  value: _audioAlerts,
                  glowColor: glowColor,
                  activeColor: activeColor,
                  onChanged: (v) => setState(() => _audioAlerts = v),
                ),
                const SizedBox(height: 12.0),

                // Sentry Vision toggle
                _ToggleRow(
                  label: 'PASSIVE_SENTRY_HUD_RENDERING',
                  subLabel: 'Keep obsidian overlay active. Disabled = standby at cruise.',
                  value: _sentryVisionPassive,
                  glowColor: glowColor,
                  activeColor: activeColor,
                  onChanged: (v) => setState(() => _sentryVisionPassive = v),
                ),
                const SizedBox(height: 16.0),

                // Accent theme selector — design.md §Buttons ghost style
                Text(
                  'ARGUS_RING_ACCENT_STYLE',
                  style: GoogleFonts.inter(
                    color: dimColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: ['VIOLET', 'CYAN', 'MONO'].map((theme) {
                    final selected = _accentTheme == theme;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _accentTheme = theme),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: selected ? glowColor.withValues(alpha: 0.2) : Colors.transparent,
                            border: Border.all(
                              color: selected ? activeColor : const Color(0xFF353436),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            theme,
                            style: GoogleFonts.spaceGrotesk(
                              color: selected ? activeColor : dimColor,
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // ── Save action — design.md §Buttons primary style ────────
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined, color: Colors.white, size: 16.0),
            label: Text(
              'SAVE & SYNERGIZE HUD',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 12.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: glowColor,
              minimumSize: const Size(double.infinity, 48.0),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 4.0,
              shadowColor: glowColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8.0),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.logout, color: const Color(0xFFFF5252).withValues(alpha: 0.8), size: 16.0),
            label: Text(
              'TERMINATE SESSION',
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFFF5252),
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 12.0,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF5252), width: 1.0),
              minimumSize: const Size(double.infinity, 48.0),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}

// ── Stat cell widget ──────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF4D4354),
            fontSize: 9.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFE5E2E3),
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Toggle row widget ─────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool value;
  final Color glowColor;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.glowColor,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE5E2E3),
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subLabel,
                style: GoogleFonts.inter(
                  color: const Color(0xFF998CA0),
                  fontSize: 10.0,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44.0,
            height: 24.0,
            decoration: BoxDecoration(
              color: value ? glowColor : const Color(0xFF1C1B1C),
              border: Border.all(
                color: value ? activeColor.withValues(alpha: 0.6) : const Color(0xFF353436),
                width: 1.0,
              ),
              // 0px border radius — sharp toggle per design.md §Shapes
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18.0,
                height: 18.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                color: value ? activeColor : const Color(0xFF4D4354),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rectangular slider thumb (0px) per design.md §Shapes ─────────────
class RectangularSliderThumbShape extends SliderComponentShape {
  const RectangularSliderThumbShape({this.thumbWidth = 10.0, this.thumbHeight = 14.0});
  final double thumbWidth;
  final double thumbHeight;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size(thumbWidth, thumbHeight);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    context.canvas.drawRect(
      Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
      Paint()..color = sliderTheme.thumbColor ?? const Color(0xFFDDB7FF),
    );
  }
}
