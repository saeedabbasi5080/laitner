import 'package:flutter/material.dart';

Widget localFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  return Icon(Icons.image_outlined, size: height ?? 48);
}
