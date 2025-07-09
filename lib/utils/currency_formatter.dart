import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Format amount in Indian Rupees
  static String formatINR(double amount, {bool symbol = true, int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol ? '₹' : '',
      decimalDigits: decimalDigits,
    );
    
    return formatter.format(amount);
  }
  
  // Format as percentage
  static String formatPercentage(double value, {int decimalDigits = 1}) {
    final formatter = NumberFormat.percentPattern('en_IN')
      ..maximumFractionDigits = decimalDigits;
    
    return formatter.format(value / 100);
  }
  
  // Format with thousand separator
  static String formatWithThousandSeparator(double value, {int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPattern('en_IN')
      ..maximumFractionDigits = decimalDigits;
    
    return formatter.format(value);
  }
  
  // Format with compact notation (K, M, B)
  static String formatCompact(double value) {
    final formatter = NumberFormat.compact(locale: 'en_IN');
    
    return formatter.format(value);
  }
  
  // Format as price per unit
  static String formatPricePerUnit(double price, String unit) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    
    return '${formatter.format(price)}/$unit';
  }
  
  // Format amount in different currencies
  static String formatCurrency(double amount, String currencyCode, {int decimalDigits = 2}) {
    String symbol;
    
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      case 'GBP':
        symbol = '£';
        break;
      case 'JPY':
        symbol = '¥';
        break;
      case 'INR':
        symbol = '₹';
        break;
      default:
        symbol = currencyCode;
    }
    
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    
    return formatter.format(amount);
  }
  
  // Convert currency
  static double convertCurrency(double amount, double exchangeRate) {
    return amount * exchangeRate;
  }
  
  // Calculate discount percentage
  static String calculateDiscountPercentage(double originalPrice, double discountedPrice) {
    final discount = originalPrice - discountedPrice;
    final percentage = (discount / originalPrice) * 100;
    
    return '${percentage.toStringAsFixed(0)}%';
  }
}