import 'package:flutter/services.dart';
import 'platform_interface.dart';

class MethodChannelFlutterViewerUsdz extends FlutterViewerUsdzPlatform {
  // final methodChannel = const MethodChannel('flutter_viewer_usdz');
  final MethodChannel methodChannel = const MethodChannel('ar_flutter_holi');

  @override
  Future<bool> loadUSDZFileFromPath(String path) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('loadUSDZFile', {
        'path': path,
        'isUrl': false,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error loading USDZ file from path: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> loadUSDZFileFromUrl(String url) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('loadUSDZFile', {
        'path': url,
        'isUrl': true,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error loading USDZ file from URL: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> rotateModel(double angle) async {
    try {
      await methodChannel.invokeMethod<void>('rotateModel', {
        'angle': angle,
      });
    } on PlatformException catch (e) {
      print('Error rotating model: ${e.message}');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await methodChannel.invokeMethod<void>('dispose');
    } on PlatformException catch (e) {
      print('Error disposing viewer: ${e.message}');
    }
  }
}
