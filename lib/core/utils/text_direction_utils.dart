import 'package:flutter/widgets.dart';

/// Infers paragraph direction from the first strong character (Unicode UAX #9).
/// Latin letters and European digits then keep their natural LTR order instead
/// of being mirrored by the app's RTL locale.
TextDirection textDirectionFor(String text) {
  for (final unit in text.runes) {
    if (_isRtl(unit)) return TextDirection.rtl;
    if (_isLtr(unit)) return TextDirection.ltr;
  }
  return TextDirection.rtl;
}

bool _isRtl(int code) {
  return (code >= 0x0590 && code <= 0x08FF) ||
      (code >= 0xFB1D && code <= 0xFDFF) ||
      (code >= 0xFE70 && code <= 0xFEFF);
}

bool _isLtr(int code) {
  return (code >= 0x0041 && code <= 0x005A) ||
      (code >= 0x0061 && code <= 0x007A) ||
      (code >= 0x00C0 && code <= 0x024F) ||
      (code >= 0x0030 && code <= 0x0039);
}
