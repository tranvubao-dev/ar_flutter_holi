import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ar_flutter_holi/managers/ar_session_manager.dart';
import 'package:ar_flutter_holi/managers/ar_location_manager.dart';
import 'package:ar_flutter_holi/managers/ar_object_manager.dart';
import 'package:ar_flutter_holi/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_holi/models/ar_anchor.dart';
import 'package:ar_flutter_holi_example/gloabl_variables.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_holi/ar_flutter_holi_plus.dart';
import 'package:ar_flutter_holi/datatypes/config_planedetection.dart';
import 'package:ar_flutter_holi/datatypes/node_types.dart';
import 'package:ar_flutter_holi/models/ar_node.dart';
import 'package:ar_flutter_holi/models/ar_hittest_result.dart';
import 'package:http/http.dart' as http;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:path_provider/path_provider.dart';

class ScreenshotWidget extends StatefulWidget {
  const ScreenshotWidget({Key? key}) : super(key: key);
  @override
  _ScreenshotWidgetState createState() => _ScreenshotWidgetState();
}

class _ScreenshotWidgetState extends State<ScreenshotWidget> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  double currentScale = 0.5;
  double initialScale = 1.0;
  late Uint8List glbBytes;
  late String localGlbPath;
  bool isLoadingModel = false;
  File? _localGlbFile;
  ARNode? previewNode;

  @override
  void initState() {
    super.initState();
    _preloadModelToFile();
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  Future<void> _preloadModelToFile() async {
    setState(() => isLoadingModel = true);
    try {
      final uri = Uri.parse(GlobalVariables.arObjectUrl1);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/preloaded_model.glb';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      _localGlbFile = file;
    } catch (e) {
      debugPrint('Preload model failed: $e');
    } finally {
      if (mounted) setState(() => isLoadingModel = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEMO AR')),
      body: SafeArea(
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            if (arObjectManager != null) arObjectManager!.buildGestureLayer(),
          ],
        ),
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: false,
          customPlaneTexturePath: '',
          showWorldOrigin: false,
          handleTaps: true,
        );

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      await arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
  }

  Future<void> onNodeTapped(List<String> nodes) async {
    arSessionManager!.onError("Tapped ${nodes.length} node(s)");
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    if (nodes.isNotEmpty) return;

    // Xóa preview
    if (previewNode != null) {
      await arObjectManager!.removeNode(previewNode!);
      previewNode = null;
    }

    final hit = hitTestResults.first;
    var anchor = ARPlaneAnchor(transformation: hit.worldTransform);

    if (await arAnchorManager!.addAnchor(anchor) != true) return;
    anchors.add(anchor);

    var realNode = ARNode(
      type: NodeType.webGLB,
      uri: _localGlbFile!.path,
      scale: Vector3(currentScale, currentScale, currentScale),
      position: Vector3(0.0, 0.0, 0.0),
      rotation: Vector4(0, 1, 0, 0),
    );

    if (await arObjectManager!.addNode(realNode, planeAnchor: anchor) == true) {
      nodes.add(realNode);
      arObjectManager!.setActiveNode(realNode);
    }
  }
}
