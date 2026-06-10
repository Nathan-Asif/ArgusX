import 'package:flutter/material.dart';
import 'package:argusx/config/argus_fonts.dart';

class EventLogPanel extends StatefulWidget {
  const EventLogPanel({super.key});

  @override
  State<EventLogPanel> createState() => _EventLogPanelState();
}

class _EventLogPanelState extends State<EventLogPanel> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _logs = [
    {
      'time': '[14:02:11]',
      'message': 'AUTH_TOKEN_REFRESH',
      'color': const Color(0xFF998CA0),
      'msgColor': const Color(0xFFE5E2E3),
    },
    {
      'time': '[14:02:15]',
      'message': 'QUERY_EXEC_OK',
      'color': const Color(0xFF998CA0),
      'msgColor': const Color(0xFFE5E2E3),
    },
    {
      'time': '[14:02:18]',
      'message': 'WARN_LATENCY_SPIKE',
      'color': const Color(0xFFFFB872),
      'msgColor': const Color(0xFFFFB872),
    },
    {
      'time': '[14:02:22]',
      'message': 'SYNC_DATA_MODULE',
      'color': const Color(0xFF998CA0),
      'msgColor': const Color(0xFFDDB7FF),
    },
    {
      'time': '[14:02:25]',
      'message': 'SYS_CALIBRATION_END',
      'color': const Color(0xFF8E2DE2).withValues(alpha: 0.5),
      'msgColor': const Color(0xFF00E676),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_fadeController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        Row(
          children: [
            Text(
              'EVENT.LOG',
              style: ArgusFonts.display(
                color: const Color(0xFFDDB7FF),
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        // partition line
        Container(
          height: 1.0,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4D4354).withValues(alpha: 0.5),
                const Color(0xFF4D4354).withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        // Log entries
        ..._logs.map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    log['time'],
                    style: ArgusFonts.display(
                      color: log['color'] as Color,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      log['message'],
                      style: ArgusFonts.display(
                        color: log['msgColor'] as Color,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
        // Blinking await listener
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              children: [
                Text(
                  '[AWAIT]',
                  style: ArgusFonts.display(
                    color: const Color(0xFF4D4354),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'LISTENING...',
                  style: ArgusFonts.display(
                    color: const Color(0xFF4D4354),
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
