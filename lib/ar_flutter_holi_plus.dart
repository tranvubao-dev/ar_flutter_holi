export 'package:ar_flutter_holi/widgets/ar_view.dart';

import 'dart:async';

import 'package:flutter/services.dart';

class ArFlutterHoliPlus {
  static const MethodChannel _channel =
      const MethodChannel('ar_flutter_holi_plus');

  /// Private constructor to prevent accidental instantiation of the Plugin using the implicit default constructor
  ArFlutterHoliPlus._();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
