import 'package:ar_flutter_holi/managers/ar_location_manager.dart';
import 'package:ar_flutter_holi/managers/ar_session_manager.dart';
import 'package:ar_flutter_holi/managers/ar_object_manager.dart';
import 'package:ar_flutter_holi/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_holi/models/ar_anchor.dart';
import 'package:ar_flutter_holi/widgets/ar_view.dart';
import 'package:ar_flutter_holi/gloabl_variables.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_holi/ar_flutter_holi.dart';
import 'package:ar_flutter_holi/datatypes/config_planedetection.dart';
import 'package:ar_flutter_holi/datatypes/node_types.dart';
import 'package:ar_flutter_holi/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_holi/models/ar_node.dart';
import 'package:ar_flutter_holi/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart';

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

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEMO AR'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),

            // ⭐ BUTTON TĂNG GIẢM SIZE ⭐
            Positioned(
              right: 20,
              bottom: 140,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: "btn_plus",
                    onPressed: increaseSize,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: "btn_minus",
                    onPressed: decreaseSize,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),

            // Nút remove + screenshot
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: onRemoveEverything,
                      child: const Text("Remove Everything")),
                  ElevatedButton(
                      onPressed: onTakeScreenshot,
                      child: const Text("Take Screenshot")),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: false,
          customPlaneTexturePath: '',
          showWorldOrigin: false,
        );
    this.arObjectManager!.onInitialize();

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

  Future<void> onTakeScreenshot() async {
    var image = await arSessionManager!.snapshot();
    await showDialog(
        context: context,
        builder: (_) => Dialog(
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(image: image, fit: BoxFit.cover)),
              ),
            ));
  }

  Future<void> onNodeTapped(List<String> nodes) async {
    arSessionManager!.onError("Tapped ${nodes.length} node(s)");
  }

  // ⭐ KHI TAP VÀO PLANE
  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);

    var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      anchors.add(newAnchor);

      var newNode = ARNode(
        type: NodeType.webGLB,
        uri: GlobalVariables.arObjectUrl1,
        scale: Vector3(currentScale, currentScale, currentScale),
        position: Vector3(0.5, 0.5, 0.5),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? didAddNode =
          await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);

      if (didAddNode == true) {
        nodes.add(newNode);
      }
    }
  }

  // 🔥 TĂNG SIZE
  void increaseSize() {
    if (nodes.isEmpty) return;

    currentScale += 1;
    final node = nodes.last;

    node.scale = Vector3(currentScale, currentScale, currentScale);
    arObjectManager!.updateNode(node);
    setState(() {});
  }

  // 🔥 GIẢM SIZE
  void decreaseSize() {
    if (nodes.isEmpty) return;

    currentScale -= 1;
    if (currentScale < 1) currentScale = 1;

    final node = nodes.last;

    node.scale = Vector3(currentScale, currentScale, currentScale);
    arObjectManager!.updateNode(node);
    setState(() {});
  }
}
