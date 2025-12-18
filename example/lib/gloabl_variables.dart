import 'dart:io';

class GlobalVariables {
  // static String arObjectUrl1 =
  //     "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Duck/glTF-Binary/Duck.glb";
  static String arObjectUrl1 = Platform.isAndroid
      ? "https://s3.holitech.cloud/evtripar/carar.glb"
      : "https://s3.holitech.cloud/evtripar/carar.usdz";
}
