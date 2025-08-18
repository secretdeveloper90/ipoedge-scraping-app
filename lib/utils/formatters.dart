import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IpoFormatters {
  // Date formatting
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    
    try {
      DateTime date;
      // Try different date formats
      if (dateString.contains('-')) {
        date = DateTime.parse(dateString);
      } else if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return dateString; // Return original if can't parse
        }
      } else {
        return dateString; // Return original if format not recognized
      }
      
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  // Format date range for upcoming IPOs
  static String formatDateRange(String? openDate, String? closeDate) {
    if (openDate == null || closeDate == null) return '';
    
    try {
      final open = DateTime.parse(openDate);
      final close = DateTime.parse(closeDate);
      
      if (open.year == close.year && open.month == close.month) {
        return '${open.day} - ${DateFormat('dd MMM yyyy').format(close)}';
      } else {
        return '${DateFormat('dd MMM').format(open)} - ${DateFormat('dd MMM yyyy').format(close)}';
      }
    } catch (e) {
      return '$openDate - $closeDate';
    }
  }

  // Currency formatting
  static String formatCurrency(double? amount) {
    if (amount == null) return '';
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Issue size formatting
  static String formatIssueSize(String? issueSize) {
    if (issueSize == null || issueSize.isEmpty) return '';
    
    // If already formatted, return as is
    if (issueSize.contains('Cr') || issueSize.contains('L') || issueSize.contains('₹')) {
      return issueSize;
    }
    
    // Try to parse as number and format
    try {
      final amount = double.parse(issueSize.replaceAll(RegExp(r'[^\d.]'), ''));
      if (amount >= 10000000) {
        return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
      } else if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(1)} L';
      } else {
        return '₹${amount.toStringAsFixed(0)}';
      }
    } catch (e) {
      return issueSize;
    }
  }

  // Percentage formatting with color
  static String formatPercentage(double? percentage) {
    if (percentage == null) return '';
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%';
  }

  // Get color for percentage values
  static Color getPercentageColor(double? percentage) {
    if (percentage == null) return Colors.grey;
    return percentage >= 0 ? Colors.green : Colors.red;
  }

  // Format subscription data
  static String formatSubscription(double? subscription) {
    if (subscription == null) return '';
    return '${subscription.toStringAsFixed(2)} times';
  }

  // Get color for subscription
  static Color getSubscriptionColor(double? subscription) {
    if (subscription == null) return Colors.grey;
    return subscription >= 1.0 ? Colors.green : Colors.red;
  }

  // Format lot size
  static String formatLotSize(int? lotSize) {
    if (lotSize == null) return '';
    return '$lotSize shares';
  }

  // Extract additional data fields safely
  static String? getAdditionalDataString(Map<String, dynamic>? additionalData, String key) {
    if (additionalData == null) return null;
    final value = additionalData[key];
    return value?.toString();
  }

  static double? getAdditionalDataDouble(Map<String, dynamic>? additionalData, String key) {
    if (additionalData == null) return null;
    final value = additionalData[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? getAdditionalDataInt(Map<String, dynamic>? additionalData, String key) {
    if (additionalData == null) return null;
    final value = additionalData[key];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
