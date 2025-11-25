import 'dart:async';

import 'package:flutter/services.dart';

class ArFlutterHoli {
  static const MethodChannel _channel = const MethodChannel('ar_flutter_holi');

  /// Private constructor to prevent accidental instantiation of the Plugin using the implicit default constructor
  ArFlutterHoli._();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
