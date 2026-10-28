import 'dart:io';

import 'package:flutter/material.dart';

Widget localFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
  );
}
