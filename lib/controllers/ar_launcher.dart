import 'dart:io';

import 'package:ar_flutter_holi/ar_flutter_holi_plus.dart';
import 'package:ar_flutter_holi/datatypes/config_planedetection.dart';
import 'package:flutter/material.dart';

class ARLauncher {
  static Future<void> open({
    required BuildContext context,
    required String modelUrl,
    ARModelType modelType = ARModelType.auto,
  }) async {
    if (Platform.isIOS) {
      await ARIOSLauncher.openUSDZ(modelUrl);
      return;
    }

    if (Platform.isAndroid) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ARAndroidPage(
            modelUrl: modelUrl,
          ),
        ),
      );
    }
  }
}

class ARIOSLauncher {
  static Future<void> openUSDZ(String url) async {
    final success = await ArFlutterHoliPlus.loadUSDZFileFromUrl(url);
    if (!success) {
      throw Exception('Cannot open USDZ file');
    }
  }
}

class ARAndroidPage extends StatefulWidget {
  final String modelUrl;

  const ARAndroidPage({
    super.key,
    required this.modelUrl,
  });

  @override
  State<ARAndroidPage> createState() => _ARAndroidPageState();
}

class _ARAndroidPageState extends State<ARAndroidPage> {
  late final ARAutoController arController;

  @override
  void initState() {
    super.initState();
    arController = ARAutoController();
    arController.preloadModelFromUrl(widget.modelUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: (s, o, a, l) {
              arController.objects = o;
              arController.onARViewCreated(s, o, a);
              setState(() {});
            },
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (arController.buildGestureLayer() != null)
            arController.buildGestureLayer()!,
          arController.buildHintOverlay(),
        ],
      ),
    );
  }
}

enum ARModelType {
  auto, // Android: glb | iOS: usdz
  glb,
  usdz,
}
