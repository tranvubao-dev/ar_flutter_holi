import 'package:ar_flutter_holi/src/platform_interface.dart';

export 'src/platform_interface.dart';
export 'src/method_channel.dart';

/// Flutter plugin for viewing USDZ files and urls.
///
/// This class provides methods to load and interact with USDZ models in Flutter applications.
class FlutterViewerUsdz {
  static final FlutterViewerUsdz _instance = FlutterViewerUsdz._internal();

  /// Factory constructor that returns the singleton instance of [FlutterViewerUsdz].
  factory FlutterViewerUsdz() => _instance;

  FlutterViewerUsdz._internal();

  /// Loads a USDZ file from a local path.
  ///
  /// [path] should be a valid path to a local USDZ file.
  ///
  /// Returns a [Future<bool>] that completes with:
  /// * `true` if the file was loaded successfully
  /// * `false` if there was an error loading the file
  ///
  /// Example:
  /// ```dart
  /// final viewer = FlutterViewerUsdz();
  /// final success = await viewer.loadUSDZFileFromPath('assets/model.usdz');
  /// ```
  Future<bool> loadUSDZFileFromPath(String path) {
    return FlutterViewerUsdzPlatform.instance.loadUSDZFileFromPath(path);
  }

  /// Loads a USDZ file from a URL.
  ///
  /// [url] should be a valid HTTP/HTTPS URL pointing to a USDZ file.
  ///
  /// Returns a [Future<bool>] that completes with:
  /// * `true` if the file was downloaded and loaded successfully
  /// * `false` if there was an error downloading or loading the file
  ///
  /// Example:
  /// ```dart
  /// final viewer = FlutterViewerUsdz();
  /// final success = await viewer.loadUSDZFileFromUrl('https://modelviewer.dev/shared-assets/models/Astronaut.usdz');
  /// ```
  Future<bool> loadUSDZFileFromUrl(String url) {
    return FlutterViewerUsdzPlatform.instance.loadUSDZFileFromUrl(url);
  }

  /// Rotates the currently loaded model by the specified angle.
  ///
  /// [angle] is the rotation angle in degrees.
  ///
  /// Throws a [PlatformException] if no model is loaded or if there's an error
  /// during rotation.
  ///
  /// Example:
  /// ```dart
  /// await viewer.rotateModel(90.0); // Rotate 90 degrees
  /// ```
  Future<void> rotateModel(double angle) {
    return FlutterViewerUsdzPlatform.instance.rotateModel(angle);
  }

  /// Disposes of the current USDZ viewer and releases associated resources.
  ///
  /// Should be called when the viewer is no longer needed to prevent memory leaks.
  ///
  /// Example:
  /// ```dart
  /// await viewer.dispose();
  /// ```
  Future<void> dispose() {
    return FlutterViewerUsdzPlatform.instance.dispose();
  }
}
