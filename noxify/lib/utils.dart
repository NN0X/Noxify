import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

int randomInt(int min, int max) {
  return min +
      (max - min) * (DateTime.now().microsecondsSinceEpoch % 1000) ~/ 1000;
}

// load audio file function
Future<Uint8List> loadAudioFile(String path) async {
  ByteData file;
  try {
    file = await rootBundle.load(path);
    print('Loaded audio file: $path');
    return file.buffer.asUint8List();
  } catch (e) {
    print('Error loading audio file: $path');
    return Uint8List(0);
  }
}
