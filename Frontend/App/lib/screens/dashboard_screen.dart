import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/grid_background.dart';
import '../widgets/bottom_nav.dart';
import '../views/mission_control_view.dart';
import '../views/camera_hud_view.dart';
import '../views/simulation_parameters_view.dart';
import '../views/operator_profile_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0; // Default to Mission Control (Index 0)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentNavIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFDDB7FF);
    final glowColor = const Color(0xFF8E2DE2);

    return Scaffold(
      // Custom Cyberpunk Bottom Navigation
      bottomNavigationBar: BottomNav(
        selectedIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
      body: GridBackground(
        child: Column(
          children: [
            // 1. High-Tech Custom AppBar
            Container(
              height: 64.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E0F),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8E2DE2).withValues(alpha: 0.05),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Scanner Icon
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: activeColor,
                      size: 22.0,
                    ),
                    // Title
                    Text(
                      'ARGUSX-SYSTEMS',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFE5E2E3),
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: glowColor.withValues(alpha: 0.5),
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                    ),
                    // Right Slider Icon
                    Icon(
                      Icons.tune_outlined,
                      color: const Color(0xFF998CA0),
                      size: 22.0,
                    ),
                  ],
                ),
              ),
            ),

            // 2. The Main View Content - PageView to allow edge/swipe gestures
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentNavIndex = index;
                  });
                },
                physics: const BouncingScrollPhysics(),
                children: const [
                  // Index 0: Mission Control (Grid View Icon)
                  MissionControlView(),
                  // Index 1: Camera HUD Overlay (Video Icon)
                  CameraHudView(),
                  // Index 2: Simulation Parameters (Construction Icon)
                  SimulationParametersView(),
                  // Index 3: Operator Profile (Person Icon) — PRD §5.2
                  OperatorProfileView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
