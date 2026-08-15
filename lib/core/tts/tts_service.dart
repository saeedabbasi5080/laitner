import 'package:flutter_tts/flutter_tts.dart';

/// پوشش نازک روی [FlutterTts] که از موتور تبدیل متن به گفتار خود دستگاه استفاده
/// می‌کند. نمونهٔ آن به‌صورت singleton در تزریق وابستگی ثبت می‌شود.
class TtsService {
  TtsService(this._tts) {
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((_) => _speaking = false);
  }

  final FlutterTts _tts;

  bool _initialized = false;
  bool _speaking = false;
  String? _currentLanguage;

  bool get isSpeaking => _speaking;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// آیا موتور TTS این زبان را پشتیبانی می‌کند؟
  Future<bool> isLanguageAvailable(String languageCode) async {
    try {
      final result = await _tts.isLanguageAvailable(languageCode);
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// تلفظ [text] با زبان مشخص‌شده. اگر متن خالی باشد کاری انجام نمی‌شود.
  ///
  /// وقتی [interrupt] برابر false باشد و تلفظ قبلی هنوز تمام نشده، درخواست
  /// جدید نادیده گرفته می‌شود تا تلفظ نیمه‌کاره قطع نشود.
  Future<void> speak(
    String text, {
    required String languageCode,
    bool interrupt = true,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!interrupt && _speaking) return;

    await _ensureInitialized();
    if (interrupt) {
      await _tts.stop();
      _speaking = false;
    }

    if (_currentLanguage != languageCode) {
      await _tts.setLanguage(languageCode);
      _currentLanguage = languageCode;
    }

    _speaking = true;
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }
}
