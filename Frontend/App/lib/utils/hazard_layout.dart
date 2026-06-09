import 'package:flutter/material.dart';

/// Maps perception-agent hazard types to HUD bounding box layout (normalized 0-1).
class HazardLayout {
  static Map<String, dynamic> fromAgentHazard(Map<String, dynamic> hazard) {
    final type = (hazard['type'] as String? ?? 'unknown').toLowerCase();
    final severity = (hazard['severity'] as String? ?? 'WARNING').toUpperCase();
    final description = hazard['description'] as String? ?? type.replaceAll('_', ' ');

    final layout = switch (type) {
      'distracted_pedestrian' => _box(0.28, 0.18, 0.22, 0.55),
      'cross_traffic' => _box(0.55, 0.25, 0.28, 0.42),
      'opening_door' => _box(0.62, 0.30, 0.25, 0.40),
      'debris' => _box(0.35, 0.22, 0.30, 0.38),
      _ => _box(0.40, 0.25, 0.22, 0.40),
    };

    final color = severity == 'CRITICAL'
        ? const Color(0xFFFF5252)
        : const Color(0xFFFFB74D);

    return {
      'label': description.toUpperCase(),
      'threat': severity,
      'color': color,
      'distance': hazard['distance_m']?.toString() ?? '--',
      ...layout,
    };
  }

  static Map<String, double> _box(double top, double left, double w, double h) => {
        'top': top,
        'left': left,
        'width': w,
        'height': h,
      };
}
