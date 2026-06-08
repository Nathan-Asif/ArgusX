import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/tech_panel.dart';
import '../widgets/tech_slider.dart';
import '../widgets/tech_toggle.dart';
import '../screens/camera_simulation_screen.dart';

/// Pre-simulation configuration screen.
/// When the user taps "INITIALIZE NEURAL SIMULATION", it pushes
/// [CameraSimulationScreen] as a fullscreen route — the Dashboard AppBar
/// and BottomNav are fully covered.
class CameraHudView extends StatefulWidget {
  const CameraHudView({super.key});

  @override
  State<CameraHudView> createState() => _CameraHudViewState();
}

class _CameraHudViewState extends State<CameraHudView> with AutomaticKeepAliveClientMixin {
  // Config variables
  String _selectedLocation = 'CYBER-GRID DELTA';
  double _probeDensity = 75.0;
  bool _tacticalSync = true;

  @override
  bool get wantKeepAlive => true;

  void _launchSimulation() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            CameraSimulationScreen(selectedLocation: _selectedLocation),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up transition
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

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
            'PRE-SIMULATION\nPROTOCOL',
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
            'Calibrate neural sync coordinates, target grid zone, and sensor density before initializing simulation node.',
            style: GoogleFonts.inter(
              color: const Color(0xFF998CA0),
              fontSize: 11.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24.0),

          // Configurations Panel
          TechPanel(
            padding: const EdgeInsets.all(16.0),
            bracketColor: glowColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_outlined, color: activeColor, size: 16.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'CALIBRATION CONTROLS',
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
                Container(
                    height: 1.0,
                    color: const Color(0xFF353436).withValues(alpha: 0.5)),
                const SizedBox(height: 16.0),

                // Target Grid Zone selector
                Text(
                  'TARGET_GRID_ZONE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE5E2E3),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF353436)),
                    color: const Color(0xFF131314),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLocation,
                      dropdownColor: const Color(0xFF131314),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFFDDB7FF)),
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                      items: <String>[
                        'CYBER-GRID DELTA',
                        'NEO-TOKYO SECTOR',
                        'OBSIDIAN BASIN',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedLocation = newValue);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Probe Density Slider
                TechSlider(
                  label: 'PROBE_DENSITY_LOD',
                  valueLabel: '${_probeDensity.toInt()}%',
                  value: _probeDensity,
                  min: 0,
                  max: 100,
                  onChanged: (val) => setState(() => _probeDensity = val),
                ),
                const SizedBox(height: 20.0),

                // Tactical Sync Toggle
                TechToggle(
                  label: 'TACTICAL_SYNC_OVERLAY',
                  subLabel: 'Enable camera coordinates HUD',
                  value: _tacticalSync,
                  onChanged: (val) => setState(() => _tacticalSync = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Launch button — design.md §Buttons primary, 0px radius
          ElevatedButton(
            onPressed: _launchSimulation,
            style: ElevatedButton.styleFrom(
              backgroundColor: glowColor,
              minimumSize: const Size(double.infinity, 50.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 6.0,
              shadowColor: glowColor.withValues(alpha: 0.5),
            ),
            child: Text(
              'INITIALIZE NEURAL SIMULATION',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 12.0,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Camera permission hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF4D4354), size: 12),
              const SizedBox(width: 6),
              Text(
                'Browser will request camera access on launch',
                style: GoogleFonts.inter(
                  color: const Color(0xFF4D4354),
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
