class NumberUtils {
  NumberUtils._();

  /// Safely convert a JSON number (which can be int, double, or String from
  /// Rails decimal serialization) into a double.
  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// JSON booleans may arrive as true/false, 0/1 or "true"/"false".
  static bool toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }

  /// Format with thousands separators: 1234567.89 -> "1,234,567.89".
  static String format(double value, {int decimals = 2}) {
    final neg = value < 0;
    final v = value.abs();
    final fixed = v.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '${neg ? '-' : ''}$buf$decPart';
  }

  /// Compact format for money: 25000000 -> "25.00 tr", 2e9 -> "2.00 tỷ".
  static String compact(double value) {
    final neg = value < 0;
    final v = value.abs();
    if (v >= 1_000_000_000) {
      return '${neg ? '-' : ''}${(v / 1_000_000_000).toStringAsFixed(2)} tỷ';
    }
    if (v >= 1_000_000) {
      return '${neg ? '-' : ''}${(v / 1_000_000).toStringAsFixed(2)} tr';
    }
    return format(value);
  }
}
