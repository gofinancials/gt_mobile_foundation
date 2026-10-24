import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

void main() {
  group('AppTextFormatter.formatCurrency', () {
    test('keeps the sign of a negative amount', () {
      // An overdrawn balance printed as a credit (OneBank pilot, 24 Oct).
      expect(AppTextFormatter.formatCurrency(-22096.06), '-₦22,096.06');
      expect(
        AppTextFormatter.formatCurrency(-22096.06, ignoreSymbol: true),
        '-22,096.06',
      );
      expect((-1500).asCurrency(), '-₦1,500.00');
    });

    test('formats positive amounts and zero as before', () {
      expect(AppTextFormatter.formatCurrency(22096.06), '₦22,096.06');
      expect(AppTextFormatter.formatCurrency(0), '₦0.00');
      expect(AppTextFormatter.formatCurrency(-0.0), '₦0.00');
      expect(AppTextFormatter.formatCurrency(null), '');
    });
  });

  group('AppTextFormatter.formatCurrencyShort', () {
    test('keeps the sign of a negative amount', () {
      expect(AppTextFormatter.formatCurrencyShort(-1500), '-₦1.5K');
      expect(AppTextFormatter.formatCurrencyShort(1500), '₦1.5K');
      expect(AppTextFormatter.formatCurrencyShort(-0.0), '₦0.0');
    });
  });
}
