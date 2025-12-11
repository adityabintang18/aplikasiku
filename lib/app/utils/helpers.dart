import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    try {
      // Parse to integer and format with thousands separator
      final number = int.parse(digitsOnly);
      final formatted = _formatter.format(number);

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      // If parsing fails, return the old value
      return oldValue;
    }
  }
}

/// Helper function to parse formatted number string back to double
///
/// Usage:
/// ```dart
/// String formattedText = "1,000,000";
/// double amount = parseFormattedAmount(formattedText);
/// print(amount); // 1000000.0
/// ```
double parseFormattedAmount(String formattedAmount) {
  // Remove all formatting (commas, spaces, etc.)
  String cleanAmount = formattedAmount.replaceAll(RegExp(r'[^\d.]'), '');

  if (cleanAmount.isEmpty) {
    return 0.0;
  }

  return double.tryParse(cleanAmount) ?? 0.0;
}

/// Format amount with thousand separators for display
///
/// Usage:
/// ```dart
/// double amount = 1234567;
/// String formatted = formatAmountDisplay(amount);
/// print(formatted); // "1,234,567"
/// ```
String formatAmountDisplay(double amount) {
  return NumberFormat('#,###').format(amount.toInt());
}

/// Format currency for Indonesian Rupiah
///
/// Usage:
/// ```dart
/// double amount = 1234567;
/// String formatted = formatCurrencyIDR(amount);
/// print(formatted); // "Rp 1,234,567"
/// ```
String formatCurrencyIDR(double amount) {
  return 'Rp ${NumberFormat('#,###').format(amount.toInt())}';
}

// Legacy function - kept for compatibility
String formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}
