// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:http/http.dart' as http;
// import 'package:vector_math/vector_math_64.dart' hide Colors;

// import '../managers/ar_session_manager.dart';
// import '../managers/ar_object_manager.dart';
// import '../managers/ar_anchor_manager.dart';
// import '../models/ar_anchor.dart';
// import '../models/ar_node.dart';
// import '../datatypes/node_types.dart';
// import 'package:path_provider/path_provider.dart';

// class ARAutoController {
//   ARSessionManager? session;
//   ARObjectManager? objects;
//   ARAnchorManager? anchors;

//   final ValueNotifier<ARHintState> hintState =
//       ValueNotifier(ARHintState.showingHint);

//   File? _localModel;
//   final List<ARNode> _nodes = [];

//   Offset? _iconScreenPosition;
//   ARAutoController();

//   Widget? buildGestureLayer() {
//     if (objects == null) return null;
//     return objects!.buildGestureLayer();
//   }

//   // =============================
//   // PRELOAD MODEL
//   // =============================
//   Future<void> preloadModelFromUrl(String url) async {
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode != 200) {
//       throw Exception('Failed to download model');
//     }

//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/auto_model.glb');
//     await file.writeAsBytes(response.bodyBytes, flush: true);
//     _localModel = file;
//   }

//   // =============================
//   // ON AR VIEW CREATED
//   // =============================
//   void onARViewCreated(
//     ARSessionManager s,
//     ARObjectManager o,
//     ARAnchorManager a,
//   ) {
//     session = s;
//     objects = o;
//     anchors = a;
//     objects!.session = session;

//     session!.onInitialize(
//       showPlanes: false,
//       showWorldOrigin: false,
//       handleTaps: false,
//       showAnimatedGuide: false,
//     );
//   }

//   // =============================
//   // TAP ICON → PLACE OBJECT
//   // =============================
//   Future<void> placeObjectAtIcon() async {
//     if (session == null ||
//         objects == null ||
//         anchors == null ||
//         _iconScreenPosition == null ||
//         _localModel == null ||
//         _nodes.isNotEmpty) return;

//     hintState.value = ARHintState.loading;

//     final results = await session!.hitTest(
//       _iconScreenPosition!.dx,
//       _iconScreenPosition!.dy,
//     );

//     if (results.isEmpty) {
//       hintState.value = ARHintState.showingHint;
//       return;
//     }

//     final hit = results.first;
//     final anchor = ARPlaneAnchor(transformation: hit.worldTransform);

//     if (await anchors!.addAnchor(anchor) != true) {
//       hintState.value = ARHintState.showingHint;
//       return;
//     }

//     final node = ARNode(
//       type: NodeType.webGLB,
//       uri: _localModel!.path,
//       scale: Vector3.all(1.5),
//       position: Vector3.zero(),
//       rotation: Vector4(0, 1, 0, 0),
//     );

//     final added = await objects!.addNode(node, planeAnchor: anchor);
//     if (added == true) {
//       _nodes.add(node);
//       objects!.setActiveNode(node);
//       hintState.value = ARHintState.placed;
//     } else {
//       hintState.value = ARHintState.showingHint;
//     }
//   }

//   // =============================
//   // HINT + LOADING UI
//   // =============================
//   Widget buildHintOverlay() {
//     return ValueListenableBuilder<ARHintState>(
//       valueListenable: hintState,
//       builder: (_, state, __) {
//         if (state == ARHintState.placed) {
//           return const SizedBox.shrink();
//         }
//         return Center(
//           child: _IconWithPosition(
//             onPosition: (offset) => _iconScreenPosition = offset,
//             child: GestureDetector(
//               onTap: state == ARHintState.loading ? null : placeObjectAtIcon,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   state == ARHintState.loading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Icon(Icons.view_in_ar,
//                           size: 80, color: Colors.white),
//                   const SizedBox(height: 8),
//                   Text(
//                     state == ARHintState.loading
//                         ? 'Loading...'
//                         : 'Tap to place object',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _IconWithPosition extends StatelessWidget {
//   final Widget child;
//   final ValueChanged<Offset> onPosition;

//   const _IconWithPosition({
//     required this.child,
//     required this.onPosition,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (_, __) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           final box = context.findRenderObject() as RenderBox?;
//           if (box != null) {
//             final position = box.localToGlobal(
//               box.size.center(Offset.zero),
//             );
//             onPosition(position);
//           }
//         });
//         return child;
//       },
//     );
//   }
// }

// enum ARHintState {
//   idle,
//   showingHint,
//   loading,
//   placed,
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../managers/ar_session_manager.dart';
import '../managers/ar_object_manager.dart';
import '../managers/ar_anchor_manager.dart';
import '../models/ar_anchor.dart';
import '../models/ar_node.dart';
import '../datatypes/node_types.dart';
import 'package:path_provider/path_provider.dart';

class ARAutoController {
  ARSessionManager? session;
  ARObjectManager? objects;
  ARAnchorManager? anchors;

  final ValueNotifier<ARHintState> hintState =
      ValueNotifier(ARHintState.preparing);

  File? _localModel;
  final List<ARNode> _nodes = [];

  bool _tapLocked = false;

  Widget? buildGestureLayer() {
    if (objects == null) return null;
    return objects!.buildGestureLayer();
  }

  // =============================
  // PRELOAD MODEL (CALL ON INIT)
  // =============================
  Future<void> preloadModelFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download model');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/auto_model.glb');
    await file.writeAsBytes(response.bodyBytes, flush: true);

    _localModel = file;
    hintState.value = ARHintState.showingHint;
  }

  // =============================
  // ON AR VIEW CREATED
  // =============================
  void onARViewCreated(
    ARSessionManager s,
    ARObjectManager o,
    ARAnchorManager a,
  ) {
    session = s;
    objects = o;
    anchors = a;

    objects!.session = session;

    session!.onInitialize(
      showPlanes: false,
      showWorldOrigin: false,
      handleTaps: false,
      showAnimatedGuide: false,
    );
  }

  // =============================
  // TAP → PLACE OBJECT (CENTER)
  // =============================
  Future<void> placeObject() async {
    if (_tapLocked) return;
    _tapLocked = true;

    try {
      if (session == null ||
          objects == null ||
          anchors == null ||
          _localModel == null ||
          _nodes.isNotEmpty) {
        return;
      }

      hintState.value = ARHintState.loading;

      final size = MediaQuery.of(session!.buildContext).size;

      final results = await session!.hitTest(
        size.width / 2,
        size.height / 2,
      );

      if (results.isEmpty) {
        hintState.value = ARHintState.showingHint;
        return;
      }

      final hit = results.first;
      final anchor = ARPlaneAnchor(transformation: hit.worldTransform);

      if (await anchors!.addAnchor(anchor) != true) {
        hintState.value = ARHintState.showingHint;
        return;
      }

      final node = ARNode(
        type: NodeType.webGLB,
        uri: _localModel!.path,
        scale: Vector3.all(2.0),
      );

      final added = await objects!.addNode(node, planeAnchor: anchor);
      if (added == true) {
        _nodes.add(node);
        objects!.setActiveNode(node);
        hintState.value = ARHintState.placed;
      } else {
        hintState.value = ARHintState.showingHint;
      }
    } finally {
      _tapLocked = false;
    }
  }

  // =============================
  // HINT + LOADING UI
  // =============================
  Widget buildHintOverlay() {
    return ValueListenableBuilder<ARHintState>(
      valueListenable: hintState,
      builder: (_, state, __) {
        if (state == ARHintState.placed) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.black45,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state == ARHintState.preparing ||
                  state == ARHintState.loading)
                const CircularProgressIndicator(color: Colors.white)
              else
                GestureDetector(
                  onTap: placeObject,
                  child: const Icon(
                    Icons.view_in_ar,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                state == ARHintState.preparing
                    ? 'Preparing AR...'
                    : state == ARHintState.loading
                        ? 'Placing object...'
                        : 'Tap to place object',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ARHintState {
  preparing,
  showingHint,
  loading,
  placed,
}
