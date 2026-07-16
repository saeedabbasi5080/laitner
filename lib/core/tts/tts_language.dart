/// زبان‌های قابل انتخاب برای تلفظ کلمات با موتور TTS دستگاه.
/// [code] کد BCP-47 است که به [FlutterTts.setLanguage] داده می‌شود.
enum TtsLanguage {
  englishUs('en-US', 'انگلیسی (آمریکا)'),
  englishUk('en-GB', 'انگلیسی (بریتانیا)'),
  french('fr-FR', 'فرانسوی'),
  german('de-DE', 'آلمانی'),
  spanish('es-ES', 'اسپانیایی'),
  italian('it-IT', 'ایتالیایی'),
  arabic('ar-SA', 'عربی'),
  persian('fa-IR', 'فارسی'),
  turkish('tr-TR', 'ترکی استانبولی'),
  russian('ru-RU', 'روسی'),
  chinese('zh-CN', 'چینی'),
  japanese('ja-JP', 'ژاپنی'),
  korean('ko-KR', 'کره‌ای');

  const TtsLanguage(this.code, this.label);

  final String code;
  final String label;

  static TtsLanguage fromCode(String? code) {
    return TtsLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => TtsLanguage.englishUs,
    );
  }
}
