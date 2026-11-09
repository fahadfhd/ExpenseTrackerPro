import 'package:kept/core/money/money.dart';
import 'package:intl/intl.dart';

/// Currencies the app offers in settings. All use two minor digits, which
/// [Money] relies on.
const supportedCurrencies = <String, String>{
  'INR': 'en_IN',
  'USD': 'en_US',
  'EUR': 'en_IE',
  'GBP': 'en_GB',
  'AED': 'en_AE',
  'SAR': 'en_SA',
};

/// The single place where amounts are turned into display strings.
class CurrencyFormatter {
  CurrencyFormatter({required this.currencyCode})
    : _full = NumberFormat.simpleCurrency(
        locale: supportedCurrencies[currencyCode] ?? 'en_IN',
        name: currencyCode,
        decimalDigits: 2,
      ),
      _whole = NumberFormat.simpleCurrency(
        locale: supportedCurrencies[currencyCode] ?? 'en_IN',
        name: currencyCode,
        decimalDigits: 0,
      ),
      _compact = NumberFormat.compactSimpleCurrency(
        locale: supportedCurrencies[currencyCode] ?? 'en_IN',
        name: currencyCode,
      );

  final String currencyCode;
  final NumberFormat _full;
  final NumberFormat _whole;
  final NumberFormat _compact;

  String get symbol => _full.currencySymbol;

  /// `₹1,234.50`, or `₹1,234` when there are no paise.
  String format(int minor) {
    final major = Money.toMajor(minor);
    return minor % Money.minorPerMajor == 0
        ? _whole.format(major)
        : _full.format(major);
  }

  /// `+₹500` / `−₹500`. The explicit sign keeps meaning independent of color.
  String signed(int minor, {required bool positive}) =>
      '${positive ? '+' : '−'}${format(minor.abs())}';

  /// Short form for chart axes: `₹12K`.
  String compact(int minor) => _compact.format(Money.toMajor(minor));
}
