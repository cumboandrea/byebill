import 'package:intl/intl.dart';

String formatCurrency(double amount, [String symbol = '€']) {
  // El separador decimal sigue a la moneda: coma para €, punto para el resto.
  final NumberFormat format = NumberFormat.currency(
    locale: symbol == '€' ? 'es_ES' : 'en_US',
    symbol: symbol,
    decimalDigits: 2,
  );
  return format.format(amount);
}

String formatDate(DateTime date) {
  final format = DateFormat('dd/MM/yyyy');
  return format.format(date);
}

String formatDateShort(DateTime date) {
  final format = DateFormat('d MMM', 'es_ES');
  return format.format(date);
}

int daysUntil(DateTime target) {
  final now = DateTime.now();
  return DateTime(target.year, target.month, target.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
}

bool isOverdue(DateTime d) {
  return daysUntil(d) < 0;
}
