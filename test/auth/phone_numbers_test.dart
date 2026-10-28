import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/phone_numbers.dart';

void main() {
  group('isValid', () {
    test('accepts a national Iranian mobile number', () {
      expect(PhoneNumbers.isValid('09121234567'), isTrue);
    });

    test('accepts the same number in any grouping', () {
      expect(PhoneNumbers.isValid('0912 123 4567'), isTrue);
      expect(PhoneNumbers.isValid('0912-123-4567'), isTrue);
      expect(PhoneNumbers.isValid('+98 912 123 4567'), isTrue);
    });

    test('accepts Persian digits, which an Iranian keyboard emits', () {
      // The failure this prevents is silent and total: every number typed on an
      // Iranian keyboard was rejected, because those digits are letters to a
      // regular expression.
      expect(PhoneNumbers.isValid('۰۹۱۲۱۲۳۴۵۶۷'), isTrue);
      expect(PhoneNumbers.isValid('۰۹۱۲ ۱۲۳ ۴۵۶۷'), isTrue);
    });

    test('accepts Arabic-Indic digits', () {
      expect(PhoneNumbers.isValid('٠٩١٢١٢٣٤٥٦٧'), isTrue);
    });

    test('rejects a landline', () {
      expect(PhoneNumbers.isValid('02112345678'), isFalse);
    });

    test('rejects a number whose subscriber part does not start with 9', () {
      expect(PhoneNumbers.isValid('08121234567'), isFalse);
    });

    test('rejects a number that is too short or too long', () {
      expect(PhoneNumbers.isValid('0912123456'), isFalse);
      expect(PhoneNumbers.isValid('091212345678'), isFalse);
      expect(PhoneNumbers.isValid(''), isFalse);
    });
  });

  group('toDisplay', () {
    test('groups a valid number for reading', () {
      expect(PhoneNumbers.toDisplay('09121234567'), '0912 123 4567');
    });

    test('groups a number with Persian digits too', () {
      expect(PhoneNumbers.toDisplay('۰۹۱۲۱۲۳۴۵۶۷'), '0912 123 4567');
    });

    test('leaves an invalid number exactly as typed', () {
      // A formatter that mangles a number the user is still typing is worse than
      // one that leaves it alone.
      expect(PhoneNumbers.toDisplay('0912'), '0912');
      expect(PhoneNumbers.toDisplay('08121234567'), '08121234567');
    });
  });

  group('toCanonical', () {
    test('produces the form the server stores', () {
      expect(PhoneNumbers.toCanonical('09121234567'), '989121234567');
    });

    test('agrees across every accepted spelling', () {
      final expected = '989121234567';
      expect(PhoneNumbers.toCanonical('0912 123 4567'), expected);
      expect(PhoneNumbers.toCanonical('+989121234567'), expected);
      expect(PhoneNumbers.toCanonical('۰۹۱۲۱۲۳۴۵۶۷'), expected);
    });

    test('is empty for an invalid number, so nothing half-normalised is sent', () {
      expect(PhoneNumbers.toCanonical('0812'), '');
      expect(PhoneNumbers.toCanonical('0912123456'), '');
    });
  });

  group('digitsOnly', () {
    test('strips separators and keeps only digits', () {
      expect(PhoneNumbers.digitsOnly('0912 123-4567'), '09121234567');
    });

    test('folds Persian digits to Latin ones', () {
      expect(PhoneNumbers.digitsOnly('۰۹۱۲۱۲۳۴۵۶۷'), '09121234567');
    });

    test('folds Arabic-Indic digits to Latin ones', () {
      expect(PhoneNumbers.digitsOnly('٠٩١٢'), '0912');
    });

    test('returns empty for letters', () {
      expect(PhoneNumbers.digitsOnly('abc'), '');
    });
  });

  group('looksIncomplete', () {
    test('says a partial number is incomplete', () {
      expect(PhoneNumbers.looksIncomplete('0912'), isTrue);
    });

    test('says nothing for an empty field', () {
      // An empty field is not yet a mistake; complaining about it would put a
      // red message under a box the user has not typed in.
      expect(PhoneNumbers.looksIncomplete(''), isFalse);
    });

    test('says nothing for a complete valid number', () {
      expect(PhoneNumbers.looksIncomplete('09121234567'), isFalse);
    });
  });
}
