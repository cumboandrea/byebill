import 'package:byebill/core/constants/app_strings.dart';
import 'package:byebill/core/utils/date_utils.dart' as d;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date utilities', () {
    test('formatCurrency formats euros with comma decimals', () {
      expect(d.formatCurrency(47.99), contains('47,99'));
      expect(d.formatCurrency(47.99), contains('€'));
      expect(d.formatCurrency(0), contains('0,00'));
    });

    test('formatDate uses dd/MM/yyyy (es locale)', () {
      final DateTime date = DateTime(2026, 9, 30);
      expect(d.formatDate(date), '30/09/2026');
    });

    test('daysUntil computes day difference ignoring time', () {
      final DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 2);
      final DateTime inFive = today.add(const Duration(days: 5, hours: 20));
      expect(d.daysUntil(inFive), 5);
    });

    test('AppStrings.badgeDays returns correct messages', () {
      expect(AppStrings.badgeDays(-1), 'Vencido');
      expect(AppStrings.badgeDays(0), 'Hoy');
      expect(AppStrings.badgeDays(1), 'Faltan 1 día');
      expect(AppStrings.badgeDays(12), 'Faltan 12 días');
    });

    test('isOverdue flags past dates', () {
      expect(d.isOverdue(DateTime.now().subtract(const Duration(days: 1))),
          isTrue);
      expect(
          d.isOverdue(DateTime.now().add(const Duration(days: 3))), isFalse);
    });
  });
}
