import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel.dart';

abstract class FlutterViewerUsdzPlatform extends PlatformInterface {
  FlutterViewerUsdzPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterViewerUsdzPlatform _instance = MethodChannelFlutterViewerUsdz();

  static FlutterViewerUsdzPlatform get instance => _instance;

  static set instance(FlutterViewerUsdzPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> loadUSDZFileFromPath(String path) {
    throw UnimplementedError(
        'loadUSDZFileFromPath() has not been implemented.');
  }

  Future<bool> loadUSDZFileFromUrl(String url) {
    throw UnimplementedError('loadUSDZFileFromUrl() has not been implemented.');
  }

  Future<void> rotateModel(double angle) {
    throw UnimplementedError('rotateModel() has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
