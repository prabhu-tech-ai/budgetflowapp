const Map<String, String> currencySymbols = {
  'INR': '₹',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
};

const List<String> supportedCurrencyCodes = ['INR', 'USD', 'EUR', 'GBP'];

String currencyDisplayName(String code) {
  switch (code) {
    case 'INR':
      return 'Indian Rupee';
    case 'USD':
      return 'US Dollar';
    case 'EUR':
      return 'Euro';
    case 'GBP':
      return 'Pound Sterling';
    default:
      return code;
  }
}

String formatCurrencyAmount(double amount, String currencyCode) {
  final symbol = currencySymbols[currencyCode] ?? '₹';
  return '$symbol ${amount.toStringAsFixed(0)}';
}
