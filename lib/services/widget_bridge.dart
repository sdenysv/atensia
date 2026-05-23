import 'dart:io';
import 'package:flutter/services.dart';

/// Platform channel bridge to the iOS home-screen mood widget.
/// All calls are no-ops on non-iOS platforms or when the channel is unavailable.
class WidgetBridge {
  static const _channel = MethodChannel('com.texapp.atensia/widget');

  /// Writes today's mood to the App Group so the widget reflects app state.
  static Future<void> updateTodayMood({double? valence, double? arousal}) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('updateMood', {
        if (valence != null) 'valence': valence,
        if (arousal != null) 'arousal': arousal,
      });
    } catch (_) {}
  }

  /// Returns mood set via the widget since the last app write, or null if
  /// today's data was last written by the app (or no data exists).
  static Future<({double? valence, double? arousal})?> readWidgetMood() async {
    if (!Platform.isIOS) return null;
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('readMood');
      if (raw == null) return null;
      return (
        valence: (raw['valence'] as num?)?.toDouble(),
        arousal: (raw['arousal'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
