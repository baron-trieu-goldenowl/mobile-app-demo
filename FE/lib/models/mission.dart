import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Display metadata for alarm missions (challenge types).
class Mission {
  final String type;
  final IconData icon;
  final Color color;

  const Mission(this.type, this.icon, this.color);

  static const all = [
    Mission('none', Icons.alarm_off_rounded, Color(0xFF8A90A8)),
    Mission('math', Icons.calculate_rounded, AppColors.accent),
    Mission('memory', Icons.grid_view_rounded, AppColors.violet),
    Mission('typing', Icons.keyboard_rounded, AppColors.event),
    Mission('shake', Icons.vibration_rounded, AppColors.warning),
    Mission('walk', Icons.directions_walk_rounded, AppColors.task),
    Mission('puzzle', Icons.extension_rounded, AppColors.accentPink),
    Mission('qr', Icons.qr_code_scanner_rounded, Color(0xFF3FC6E0)),
  ];

  static Mission of(String type) =>
      all.firstWhere((m) => m.type == type, orElse: () => all.first);
}
