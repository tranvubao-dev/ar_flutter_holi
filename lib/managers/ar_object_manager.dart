import 'package:ar_flutter_holi/models/ar_anchor.dart';
import 'package:ar_flutter_holi/models/ar_node.dart';
import 'package:ar_flutter_holi/utils/json_converters.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as VectorMath;

// Type definitions to enforce a consistent use of the API
typedef NodeTapResultHandler = void Function(List<String> nodes);
typedef NodePanStartHandler = void Function(String node);
typedef NodePanChangeHandler = void Function(String node);
typedef NodePanEndHandler = void Function(String node, Matrix4 transform);
typedef NodeRotationStartHandler = void Function(String node);
typedef NodeRotationChangeHandler = void Function(String node);
typedef NodeRotationEndHandler = void Function(String node, Matrix4 transform);

/// Manages the all node-related actions of an [ARView]
class ARObjectManager {
  /// Platform channel used for communication from and to [ARObjectManager]
  late MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  /// Callback function that is invoked when the platform detects a tap on a node
  NodeTapResultHandler? onNodeTap;
  NodePanStartHandler? onPanStart;
  NodePanChangeHandler? onPanChange;
  NodePanEndHandler? onPanEnd;
  NodeRotationStartHandler? onRotationStart;
  NodeRotationChangeHandler? onRotationChange;
  NodeRotationEndHandler? onRotationEnd;

  final ARGestureConfig gestureConfig;

  double _currentScale = 1.0;
  double _initialScale = 1.0;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  Offset? _lastDragPosition;
  ARNode? _activeNode;

  ARObjectManager(
    int id, {
    this.debug = false,
    this.gestureConfig = const ARGestureConfig(),
  }) {
    _channel = MethodChannel('arobjects_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
    if (debug) {
      print("ARObjectManager initialized");
    }
  }

  Widget buildGestureLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
      ),
    );
  }

  void setActiveNode(ARNode node) {
    _activeNode = node;
    _currentScale = node.scale.x;
    _rotationX = 0;
    _rotationY = 0;
  }

  Future<void> _platformCallHandler(MethodCall call) {
    if (debug) {
      print('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    try {
      switch (call.method) {
        case 'onError':
          print(call.arguments);
          break;
        case 'onNodeTap':
          if (onNodeTap != null) {
            final tappedNodes = call.arguments as List<dynamic>;
            onNodeTap!(
              tappedNodes.map((tappedNode) => tappedNode.toString()).toList(),
            );
          }
          break;
        case 'onPanStart':
          if (onPanStart != null) {
            final tappedNode = call.arguments as String;
            // Notify callback
            onPanStart!(tappedNode);
          }
          break;
        case 'onPanChange':
          if (onPanChange != null) {
            final tappedNode = call.arguments as String;
            // Notify callback
            onPanChange!(tappedNode);
          }
          break;
        case 'onPanEnd':
          if (onPanEnd != null) {
            final tappedNodeName = call.arguments["name"] as String;
            final transform = MatrixConverter().fromJson(
              call.arguments['transform'] as List,
            );

            // Notify callback
            onPanEnd!(tappedNodeName, transform);
          }
          break;
        case 'onRotationStart':
          if (onRotationStart != null) {
            final tappedNode = call.arguments as String;
            onRotationStart!(tappedNode);
          }
          break;
        case 'onRotationChange':
          if (onRotationChange != null) {
            final tappedNode = call.arguments as String;
            onRotationChange!(tappedNode);
          }
          break;
        case 'onRotationEnd':
          if (onRotationEnd != null) {
            final tappedNodeName = call.arguments["name"] as String;
            final transform = MatrixConverter().fromJson(
              call.arguments['transform'] as List,
            );

            // Notify callback
            onRotationEnd!(tappedNodeName, transform);
          }
          break;
        default:
          if (debug) {
            print('Unimplemented method ${call.method} ');
          }
      }
    } catch (e) {
      print('Error caught: ' + e.toString());
    }
    return Future.value();
  }

  /// Sets up the AR Object Manager
  onInitialize() {
    _channel.invokeMethod<void>('init', {});
  }

  /// Add given node to the given anchor of the underlying AR scene (or to its top-level if no anchor is given) and listen to any changes made to its transformation
  Future<bool?> addNode(ARNode node, {ARPlaneAnchor? planeAnchor}) async {
    try {
      node.transformNotifier.addListener(() {
        _channel.invokeMethod<void>('transformationChanged', {
          'name': node.name,
          'transformation': MatrixValueNotifierConverter().toJson(
            node.transformNotifier,
          ),
        });
      });
      if (planeAnchor != null) {
        planeAnchor.childNodes.add(node.name);
        return await _channel.invokeMethod<bool>('addNodeToPlaneAnchor', {
          'node': node.toMap(),
          'anchor': planeAnchor.toJson(),
        });
      } else {
        return await _channel.invokeMethod<bool>('addNode', node.toMap());
      }
    } on PlatformException {
      return false;
    }
  }

  /// Remove given node from the AR Scene
  removeNode(ARNode node) {
    _channel.invokeMethod<String>('removeNode', {'name': node.name});
  }

  Future<bool?> updateNode(ARNode node) async {
    try {
      return await _channel.invokeMethod<bool>('updateNode', {
        'node': node.toMap(),
      });
    } on PlatformException {
      return false;
    }
  }

  void onScaleStart(ScaleStartDetails details) {
    if (_activeNode == null) return;

    _initialScale = _currentScale;
    _lastDragPosition = details.focalPoint;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_activeNode == null) return;

    final node = _activeNode!;

    // SCALE
    if (gestureConfig.enableScale) {
      _currentScale = (_initialScale * details.scale).clamp(0.2, 40.0);
    }

    // ROTATE
    if (gestureConfig.enableRotation && _lastDragPosition != null) {
      final dx = details.focalPoint.dx - _lastDragPosition!.dx;
      final dy = details.focalPoint.dy - _lastDragPosition!.dy;
      _lastDragPosition = details.focalPoint;

      const sensitivity = 0.01;
      _rotationY += dx * sensitivity;
      _rotationX += dy * sensitivity;
    }

    final qX = VectorMath.Quaternion.axisAngle(
      VectorMath.Vector3(1, 0, 0),
      _rotationX,
    );
    final qY = VectorMath.Quaternion.axisAngle(
      VectorMath.Vector3(0, 1, 0),
      _rotationY,
    );

    final q = qY * qX;

    node.transform = VectorMath.Matrix4.compose(
      node.position,
      q,
      VectorMath.Vector3(_currentScale, _currentScale, _currentScale),
    );

    updateNode(node);
  }
}

class ARGestureConfig {
  final bool enableScale;
  final bool enableRotation;

  const ARGestureConfig({
    this.enableScale = true,
    this.enableRotation = true,
  });
}
