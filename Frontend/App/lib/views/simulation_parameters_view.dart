import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_slider.dart';
import '../widgets/tech_toggle.dart';
import '../widgets/audio_equalizer.dart';
import '../widgets/tech_tree_node.dart';

class SimulationParametersView extends StatefulWidget {
  const SimulationParametersView({super.key});

  @override
  State<SimulationParametersView> createState() => _SimulationParametersViewState();
}

class _SimulationParametersViewState extends State<SimulationParametersView> with AutomaticKeepAliveClientMixin {
  // State variables
  double _maxRenderFps = 60.0;
  double _lodDistanceScalar = 2.5;
  bool _envHazardsEnabled = true;
  bool _entityHighlightingEnabled = true;
  double _masterOutputGain = 75.0;
  bool _voiceAssistantEnabled = true;

  // PRD §5.1 Autonomous UI Navigation — prune UI at high speed
  double _currentSpeed = 0.0;
  bool get _isHighSpeed => _currentSpeed >= 80.0;
  bool get _isMidSpeed => _currentSpeed >= 40.0 && _currentSpeed < 80.0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const activeColor = Color(0xFFDDB7FF);
    const glowColor = Color(0xFF8E2DE2);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'SIMULATION\nPARAMETERS',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFE5E2E3),
              fontSize: 28.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Configure global matrix constraints, environmental hazards, and sensory output fidelity. Changes apply real-time to active simulation nodes.',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF998CA0),
              fontSize: 11.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),

          // ── PRD §5.1 Autonomous UI Navigation ───────────────────────
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            borderColor: _isHighSpeed
                ? const Color(0xFFFF5252).withValues(alpha: 0.5)
                : _isMidSpeed
                    ? const Color(0xFFFFB74D).withValues(alpha: 0.4)
                    : const Color(0xFF353436),
            bracketColor: _isHighSpeed
                ? const Color(0xFFFF5252)
                : _isMidSpeed
                    ? const Color(0xFFFFB74D)
                    : activeColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AUTONOMOUS.UI', style: GoogleFonts.spaceGrotesk(
                      color: activeColor, fontSize: 12.0,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: (_isHighSpeed
                            ? const Color(0xFFFF5252)
                            : _isMidSpeed
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFF00E676))
                            .withValues(alpha: 0.15),
                        border: Border.all(
                          color: _isHighSpeed
                              ? const Color(0xFFFF5252)
                              : _isMidSpeed
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF00E676),
                        ),
                      ),
                      child: Text(
                        _isHighSpeed ? 'UI_PRUNED' : _isMidSpeed ? 'PARTIAL' : 'FULL_UI',
                        style: GoogleFonts.spaceMono(
                          color: _isHighSpeed
                              ? const Color(0xFFFF5252)
                              : _isMidSpeed
                                  ? const Color(0xFFFFB74D)
                                  : const Color(0xFF00E676),
                          fontSize: 8.0, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  'PRD §5.1: Context-aware state machine manages UI clutter at speed.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF4D4354), fontSize: 10.0, height: 1.4)),
                const SizedBox(height: 14.0),
                // Speed slider
                Row(
                  children: [
                    const Icon(Icons.speed, color: Color(0xFF998CA0), size: 14),
                    const SizedBox(width: 8.0),
                    Text('SPEED: ${_currentSpeed.toInt()} km/h',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE5E2E3), fontSize: 11.0,
                        fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RectangularSliderThumbShape(),
                    trackHeight: 2.0,
                    activeTrackColor: _isHighSpeed
                        ? const Color(0xFFFF5252)
                        : _isMidSpeed
                            ? const Color(0xFFFFB74D)
                            : activeColor,
                    inactiveTrackColor: const Color(0xFF353436),
                    thumbColor: _isHighSpeed
                        ? const Color(0xFFFF5252)
                        : _isMidSpeed
                            ? const Color(0xFFFFB74D)
                            : activeColor,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _currentSpeed,
                    min: 0.0,
                    max: 160.0,
                    onChanged: (v) => setState(() => _currentSpeed = v),
                  ),
                ),
                // PRD prune indicator
                if (_isHighSpeed) ...[
                  const SizedBox(height: 8.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFFF5252), size: 14),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'HIGH SPEED — NON-ESSENTIAL WIDGETS PRUNED\nBROADENING CRITICAL TELEMETRY OVERLAYS',
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFFFF5252), fontSize: 8.5,
                              fontWeight: FontWeight.bold, letterSpacing: 0.8, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFF131314).withValues(alpha: 0.8),
              border: Border.all(
                color: const Color(0xFF353436),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6.0,
                  width: 6.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E5FF), // Cyan Nominal
                    shape: BoxShape.rectangle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 4.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'SYS.NOMINAL',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00E5FF),
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // 1. VISION MATRIX CONFIG Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_outlined, color: activeColor, size: 16.0),
                        const SizedBox(width: 8.0),
                        Text(
                          'VISION MATRIX\nCONFIG',
                          style: GoogleFonts.spaceGrotesk(
                            color: activeColor,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('NODE_ID:', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF4D4354), fontSize: 8.0)),
                        Text('VM-77A', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF998CA0), fontSize: 10.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Max Render FPS Slider
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechSlider(
                    label: 'MAX_RENDER_FPS',
                    valueLabel: '${_maxRenderFps.toInt()}',
                    value: _maxRenderFps,
                    min: 15,
                    max: 60,
                    divisions: 2,
                    tickLabels: const ['15', '30', '60'],
                    onChanged: (val) => setState(() => _maxRenderFps = val),
                  ),
                ),
                const SizedBox(height: 12.0),

                // LOD Distance Scalar Slider
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechSlider(
                    label: 'LOD_DISTANCE_SCALAR',
                    valueLabel: '${_lodDistanceScalar.toStringAsFixed(1)}x',
                    value: _lodDistanceScalar,
                    min: 1.0,
                    max: 5.0,
                    onChanged: (val) => setState(() => _lodDistanceScalar = val),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Environmental Hazards Toggle
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechToggle(
                    label: 'ENVIRONMENTAL_HAZARDS',
                    subLabel: 'Enable dynamic threats',
                    value: _envHazardsEnabled,
                    onChanged: (val) => setState(() => _envHazardsEnabled = val),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Entity Highlighting Toggle
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechToggle(
                    label: 'ENTITY_HIGHLIGHTING',
                    subLabel: 'Tactical overlay active',
                    value: _entityHighlightingEnabled,
                    onChanged: (val) => setState(() => _entityHighlightingEnabled = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 2. AUDIO SYS Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.graphic_eq, color: activeColor, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'AUDIO SYS',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Equalizer
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: AudioEqualizer(
                    value: _masterOutputGain,
                    onChanged: (val) => setState(() => _masterOutputGain = val),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Voice Assistant Toggle
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechToggle(
                    label: 'VOICE_ASSISTANT_AI',
                    subLabel: 'Synthesized feedback',
                    value: _voiceAssistantEnabled,
                    onChanged: (val) => setState(() => _voiceAssistantEnabled = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 3. HIERARCHICAL SETTING ARRAYS Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined, color: activeColor, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'HIERARCHICAL\nSETTING ARRAYS',
                      style: GoogleFonts.spaceGrotesk(
                        color: activeColor,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Container(height: 1.0, color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Physics Engine Node
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechTreeNode(
                    title: 'PHYSICS_ENGINE',
                    items: [
                      TechTreeItem(label: 'GRAVITY_VECTOR', value: '9.81'),
                      TechTreeItem(label: 'COLLISION_MESH', value: 'HIGH', isSelected: true),
                      TechTreeItem(label: 'FLUID_DYNAMICS', value: 'OFF'),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // AI Behavior Trees Node
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314).withValues(alpha: 0.5),
                  ),
                  child: TechTreeNode(
                    title: 'AI_BEHAVIOR_TREES',
                    items: [
                      TechTreeItem(label: 'AGGRESSION_SCALAR', value: '0.8'),
                      TechTreeItem(label: 'PATHFINDING_LOD', value: 'MED'),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // Commit Changes Button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save, color: Colors.white, size: 16.0),
                  label: Text(
                    'COMMIT_CHANGES',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: glowColor,
                    minimumSize: const Size(double.infinity, 44.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 4.0,
                    shadowColor: glowColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Revert Default Button
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4D4354), width: 1.0),
                    minimumSize: const Size(double.infinity, 44.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'REVERT_TO_DEFAULT',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFFE5E2E3),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}

class RectangularSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double thumbHeight;
  final double thumbWidth;

  const RectangularSliderThumbShape({
    this.enabledThumbRadius = 6.0,
    this.thumbHeight = 12.0,
    this.thumbWidth = 6.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: thumbWidth,
        height: thumbHeight,
      ),
      paint,
    );
  }
}

