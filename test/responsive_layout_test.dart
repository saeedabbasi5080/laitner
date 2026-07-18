import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/responsive.dart';

void main() {
  test('fitCardSize keeps 3:4 when height allows', () {
    final size = fitCardSize(availableWidth: 300, availableHeight: 800);
    expect(size.width, 300);
    expect(size.height, closeTo(400, 0.001));
  });

  test('fitCardSize shrinks to available height on short screens', () {
    final size = fitCardSize(availableWidth: 300, availableHeight: 280);
    expect(size.height, 280);
    expect(size.width, closeTo(210, 0.001));
  });
}
