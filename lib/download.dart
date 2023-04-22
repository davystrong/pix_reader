import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

void download(Uint8List data, String filename) async {
  if (defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows) {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Select a save location:',
      fileName: filename,
    );
    if (outputFile != null) {
      await File(outputFile).writeAsBytes(data);
    }
  } else {
    final params = SaveFileDialogParams(
      data: data,
      fileName: filename,
    );
    await FlutterFileDialog.saveFile(params: params);
  }
}
