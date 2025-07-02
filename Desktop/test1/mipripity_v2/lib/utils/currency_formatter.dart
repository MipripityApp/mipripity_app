import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A utility class to handle currency formatting consistently across the app
class CurrencyFormatter {
  /// Returns a formatted price in Nigerian Naira (₦) with proper formatting
  /// for display on all Android devices.
  /// 
  /// Handles large numbers by converting to K, M, B (thousands, millions, billions)
  /// for better readability.
  static String formatNaira(num amount, {bool useAbbreviations = true, int decimalPlaces = 0}) {
    // For large numbers, use abbreviations if requested
    if (useAbbreviations) {
      if (amount >= 1e9) {
        return '₦${(amount / 1e9).toStringAsFixed(decimalPlaces)}B';
      } else if (amount >= 1e6) {
        return '₦${(amount / 1e6).toStringAsFixed(decimalPlaces)}M';
      } else if (amount >= 1e3) {
        return '₦${(amount / 1e3).toStringAsFixed(decimalPlaces)}K';
      }
    }

    // Use proper NumberFormat for other amounts
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: decimalPlaces,
    ).format(amount);
  }

  /// Format a price without any currency symbol
  static String formatNumber(num amount, {int decimalPlaces = 0}) {
    final formatter = NumberFormat.decimalPattern('en_NG');
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    return formatter.format(amount);
  }
  
  /// Format price with custom currency symbol
  static String formatWithSymbol(num amount, String symbol, {int decimalPlaces = 0}) {
    if (amount >= 1e9) {
      return '$symbol${(amount / 1e9).toStringAsFixed(decimalPlaces)}B';
    } else if (amount >= 1e6) {
      return '$symbol${(amount / 1e6).toStringAsFixed(decimalPlaces)}M';
    } else if (amount >= 1e3) {
      return '$symbol${(amount / 1e3).toStringAsFixed(decimalPlaces)}K';
    } else {
      return '$symbol${NumberFormat.currency(
        locale: 'en_NG',
        symbol: '',
        decimalDigits: decimalPlaces,
      ).format(amount)}';
    }
  }

  /// Format percentage values (e.g., "25.5%")
  static String formatPercentage(num percentage, {int decimalPlaces = 1}) {
    return '${percentage.toStringAsFixed(decimalPlaces)}%';
  }

  /// Extract numeric value from a formatted currency string
  static num extractNumericValue(String formattedPrice) {
    // Remove all non-numeric characters except for decimal points
    final numericString = formattedPrice.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericString) ?? 0;
  }

  /// Returns a TextStyle with the CustomFont family for the Naira symbol
  static TextStyle getNairaTextStyle({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
  }) {
    return TextStyle(
      fontFamily: 'CustomFont',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Returns a RichText widget with properly formatted Naira symbol using CustomFont
  static RichText formatNairaRichText(
    num amount, {
    TextStyle? textStyle,
    TextStyle? symbolStyle,
    bool useAbbreviations = true,
  }) {
    // Format the amount
    String formatted = formatNaira(amount, useAbbreviations: useAbbreviations, decimalPlaces: 0);
    
    // Extract the symbol and amount parts
    String symbol = '₦';
    String amountText = formatted.substring(1); // Remove the symbol
    
    // Default text style if not provided
    textStyle ??= const TextStyle();
    
    // Symbol style with CustomFont if not provided
    symbolStyle ??= getNairaTextStyle(
      fontSize: textStyle.fontSize ?? 14.0,
      fontWeight: textStyle.fontWeight ?? FontWeight.normal,
      color: textStyle.color ?? Colors.black,
    );
    
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: symbol,
            style: symbolStyle,
          ),
          TextSpan(
            text: amountText,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}