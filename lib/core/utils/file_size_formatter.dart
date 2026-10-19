import 'dart:math';

class FileSizeFormatter {
  static const List<String> _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Formats byte count into human readable string, e.g. "14.2 MB"
  static String format(int bytes) {
    if (bytes <= 0) return '0 B';
    final digitGroups = (log(bytes) / log(1024)).floor();
    final clampedGroup = digitGroups.clamp(0, _units.length - 1);
    final value = bytes / pow(1024, clampedGroup);
    return '${value.toStringAsFixed(clampedGroup == 0 ? 0 : 1)} ${_units[clampedGroup]}';
  }
}
