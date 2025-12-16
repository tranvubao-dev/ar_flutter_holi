import 'package:flutter/material.dart';
import 'platform_interface.dart';

class UsdzViewer extends StatefulWidget {
  final String path;
  final bool isFromUrl;
  final Function(bool)? onLoadComplete;
  final Function(String)? onError;

  const UsdzViewer({
    Key? key,
    required this.path,
    this.isFromUrl = true,
    this.onLoadComplete,
    this.onError,
  }) : super(key: key);

  @override
  State<UsdzViewer> createState() => _UsdzViewerState();
}

class _UsdzViewerState extends State<UsdzViewer> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = widget.isFromUrl
          ? await FlutterViewerUsdzPlatform.instance
              .loadUSDZFileFromUrl(widget.path)
          : await FlutterViewerUsdzPlatform.instance
              .loadUSDZFileFromPath(widget.path);

      if (mounted) {
        if (success) {
          widget.onLoadComplete?.call(true);
        } else {
          _error = 'Failed to load model';
          widget.onLoadComplete?.call(false);
        }
      }
    } catch (e) {
      if (mounted) {
        _error = e.toString();
        widget.onError?.call(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadModel,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.expand();
  }

  @override
  void dispose() {
    FlutterViewerUsdzPlatform.instance.dispose();
    super.dispose();
  }
}
