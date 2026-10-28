/// Reading and normalising Iranian mobile numbers.
///
/// The rules here are a mirror of `PhoneNumbers` in the backend
/// (`src/domain/.../PhoneNumbers.java`), not an independent opinion. The app
/// needs them for two reasons: to tell the user they typed something impossible
/// before spending a request on it, and to show the number the way the server
/// will return it.
///
/// Deliberately duplicating the logic rather than asking the server. A wrong
/// number should be caught with no network at all — the app must work offline,
/// and a validation that needs a round trip is not available offline.
library;

abstract final class PhoneNumbers {
  /// Iranian mobile numbers are `0912 123 4567` — eleven digits, leading zero.
  static const int nationalLength = 11;
  static const int subscriberLength = 10;

  /// The national prefix, without which a ten-digit number is meaningless.
  static const String mobilePrefix = '09';

  /// The prefix every Iranian mobile operator's number begins with, after the
  /// leading national zero.
  ///
  /// Not just `9`: `090`, `091`, `093` and `099` are also allocated, but a number
  /// whose second digit is `1` is a fixed line — `021`, `031` and the rest — not
  /// a mobile. The operator codes that are actually in use all begin `9`.
  static const String mobileOperatorPrefix = '9';

  /// Folds the digit characters Persian and Arabic keyboards produce.
  ///
  /// Without this the check rejects every number typed on an Iranian keyboard:
  /// those keyboards emit U+06F0–U+06F9, which are digits to a person and
  /// letters to a regular expression.
  static String foldDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      buffer.writeCharCode(_fold(rune));
    }
    return buffer.toString();
  }

  static int _fold(int rune) {
    // Persian digits, U+06F0..U+06F9.
    if (rune >= 0x06F0 && rune <= 0x06F9) return 0x30 + (rune - 0x06F0);
    // Arabic-Indic digits, U+0660..U+0669. Kept for keyboards set to Arabic.
    if (rune >= 0x0660 && rune <= 0x0669) return 0x30 + (rune - 0x0660);
    return rune;
  }

  /// Keeps only digits, after folding.
  static String digitsOnly(String input) =>
      foldDigits(input).replaceAll(RegExp(r'[^0-9]'), '');

  /// Whether this could be a valid mobile number.
  ///
  /// Structural only. It cannot tell a real number from one nobody owns, and it
  /// does not pretend to: that check costs a request and belongs to the server.
  ///
  /// Accepts the two spellings a person is likely to type — the national form
  /// `0912 123 4567` and the international `+98 912 123 4567` — because both are
  /// the same number and refusing either would be a decision about house style,
  /// not about correctness.
  static bool isValid(String input) {
    final digits = digitsOnly(input);
    final national = _toNational(digits);
    if (national == null) return false;
    if (!national.startsWith(mobilePrefix)) return false;
    // The digit after the national zero is the operator's, and every mobile
    // operator code starts with 9. Checking the second digit rather than the
    // third is what keeps `02112345678` — a valid-looking eleven-digit number —
    // out while letting `0912` through.
    return national.substring(1).startsWith(mobileOperatorPrefix);
  }

  /// Puts any accepted spelling into the eleven-digit national form.
  ///
  /// Returns null when the input is neither shape, rather than guessing: the
  /// caller has to be able to tell "not a number" from "a number I could not
  /// parse".
  static String? _toNational(String digits) {
    if (digits.length == nationalLength) return digits;

    // The international form without its plus: `98` then ten digits.
    final countryCode = '98';
    if (digits.length == countryCode.length + subscriberLength &&
        digits.startsWith(countryCode)) {
      return '0${digits.substring(countryCode.length)}';
    }

    return null;
  }

  /// Groups a valid number for reading: `0912 123 4567`.
  ///
  /// Returns the input unchanged when it is not valid, because a formatter that
  /// silently mangles a number the user is still typing is worse than one that
  /// leaves it alone. Always the national form, so `+98 912...` and
  /// `0912...` produce the same string.
  static String toDisplay(String input) {
    final national = _toNational(digitsOnly(input));
    if (national == null || !isValid(national)) return input;
    return '${national.substring(0, 4)} '
        '${national.substring(4, 7)} '
        '${national.substring(7)}';
  }

  /// The digits as the server stores them: `989121234567`.
  ///
  /// Empty when the number is not valid, so a caller cannot accidentally send a
  /// half-normalised number and be told it is invalid by the server.
  static String toCanonical(String input) {
    final national = _toNational(digitsOnly(input));
    if (national == null || !isValid(national)) return '';
    return '98${national.substring(1)}';
  }

  /// Whether the typed input could still become a valid number.
  ///
  /// Used to decide whether to show a complaint, not whether to send. It says
  /// "you are done typing something wrong", which is a different question from
  /// "this is a valid number".
  static bool looksIncomplete(String input) {
    final digits = digitsOnly(input);
    if (digits.isEmpty) return false;
    return digits.length < nationalLength || !isValid(digits);
  }
}
