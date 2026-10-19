import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _fileTimestampFormat = DateFormat('yyyy-MM-dd_HHmmss');
  static final DateFormat _readableFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _shortDate = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeOnly = DateFormat('h:mm a');

  /// Generates a timestamp suitable for filenames, e.g. "2026-10-19_211500"
  static String formatFileTimestamp(DateTime dateTime) {
    return _fileTimestampFormat.format(dateTime);
  }

  /// Formats date for display in UI, e.g. "Oct 19, 2026 • 9:15 PM"
  static String formatReadable(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return _readableFormat.format(dateTime.toLocal());
  }

  /// Formats short date, e.g. "2026-10-19"
  static String formatShortDate(DateTime dateTime) {
    return _shortDate.format(dateTime.toLocal());
  }

  /// Formats time only, e.g. "9:15 PM"
  static String formatTime(DateTime dateTime) {
    return _timeOnly.format(dateTime.toLocal());
  }
}
