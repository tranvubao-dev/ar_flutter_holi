import 'package:ar_flutter_holi/managers/ar_object_manager.dart';
import 'package:ar_flutter_holi_example/gloabl_variables.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_holi/ar_flutter_holi_plus.dart';
import 'package:ar_flutter_holi/datatypes/config_planedetection.dart';

class ScreenshotWidget extends StatefulWidget {
  const ScreenshotWidget({Key? key}) : super(key: key);
  @override
  _ScreenshotWidgetState createState() => _ScreenshotWidgetState();
}

class _ScreenshotWidgetState extends State<ScreenshotWidget> {
  late final arController = ARAutoController();
  late ARObjectManager arObjectManager;

  @override
  void initState() {
    super.initState();
    arController.preloadModelFromUrl(GlobalVariables.arObjectUrl1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEMO AR')),
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
          arController.buildHintOverlay()
        ],
      ),
    );
  }
}
