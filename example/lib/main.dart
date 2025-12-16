import 'dart:io';
import 'package:ar_flutter_holi/ar_flutter_holi_plus.dart';
import 'package:ar_flutter_holi/flutter_viewer_usdz.dart';
import 'package:ar_flutter_holi_example/examples/screenshotexample.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'HOLI';
  static const String _title = 'AR Plugin Demo';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ArFlutterHoliPlus.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Column(children: [
          Text('Running on: $_platformVersion\n'),
          Expanded(
            child: SafeArea(
              child: ExampleList(),
            ),
          ),
        ]),
      ),
    );
  }
}

class ExampleList extends StatelessWidget {
  ExampleList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final examples = Platform.isAndroid
        ? [
            Example(
                'android GLB',
                'Place 3D objects on planes',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ScreenshotWidget()))),
          ]
        : [
            Example(
              'iOS USDZ',
              'Place 3D objects on planes',
              () async {
                await openARModel();
              },
            ),
          ];
    return ListView(
      children:
          examples.map((example) => ExampleCard(example: example)).toList(),
    );
  }

  Future<void> openARModel() async {
    const url = "https://s3.holitech.cloud/evtripar/carar.usdz";
    final success = await ArFlutterHoliPlus.loadUSDZFileFromUrl(url);
    if (!success) {
      print("❌ Không thể mở USDZ");
    }
  }
}

class ExampleCard extends StatelessWidget {
  ExampleCard({Key? key, required this.example}) : super(key: key);
  final Example example;

  @override
  build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          example.onTap();
        },
        child: ListTile(
          title: Text(example.name),
          subtitle: Text(example.description),
        ),
      ),
    );
  }
}

class Example {
  const Example(this.name, this.description, this.onTap);
  final String name;
  final String description;
  final Function onTap;
}
