import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryService {
  static const MethodChannel _channel = MethodChannel('com.example.chat_application/battery');
  static final Battery _batteryPlus = Battery();

  /// Fetches native device battery level percentage (0 to 100).
  /// Uses custom MethodChannel first, and falls back to battery_plus plugin.
  /// Returns null if unavailable or running on unsupported environments (like Web).
  static Future<int?> getBatteryLevel() async {
    // 1. Try custom Native MethodChannel
    try {
      final int? result = await _channel.invokeMethod<int>('getBatteryLevel');
      if (result != null && result >= 0 && result <= 100) {
        return result;
      }
    } catch (e) {
      debugPrint('BatteryService Custom MethodChannel fallback: $e');
    }

    // 2. Fallback to battery_plus platform implementation
    try {
      final int level = await _batteryPlus.batteryLevel;
      if (level >= 0 && level <= 100) {
        return level;
      }
    } catch (e) {
      debugPrint('BatteryService battery_plus fallback: $e');
    }

    return null;
  }
}
