import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as 'dd/MM/yyyy'
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
  
  // Format date as 'dd MMM yyyy' (e.g., 15 Jan 2025)
  static String formatDateWithMonth(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }
  
  // Format date as 'dd MMMM yyyy' (e.g., 15 January 2025)
  static String formatDateWithFullMonth(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(date);
  }
  
  // Format date as 'MMMM dd, yyyy' (e.g., January 15, 2025)
  static String formatDateUSStyle(DateTime date) {
    final formatter = DateFormat('MMMM dd, yyyy');
    return formatter.format(date);
  }
  
  // Format date and time as 'dd/MM/yyyy HH:mm'
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }
  
  // Format date and time as 'dd MMM yyyy, hh:mm a' (e.g., 15 Jan 2025, 02:30 PM)
  static String formatDateTimeWithAmPm(DateTime dateTime) {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return formatter.format(dateTime);
  }
  
  // Format time as 'HH:mm' (24-hour format)
  static String formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
  }
  
  // Format time as 'hh:mm a' (12-hour format with AM/PM)
  static String formatTimeWithAmPm(DateTime time) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(time);
  }
  
  // Get relative time (e.g., "2 hours ago", "3 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  // Format date range (e.g., "15-20 Jan 2025", "15 Jan - 20 Feb 2025")
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    final startFormatter = DateFormat('dd');
    final endFormatter = DateFormat('dd MMM yyyy');
    
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      // Same month and year, format as "15-20 Jan 2025"
      return '${startFormatter.format(startDate)}-${endFormatter.format(endDate)}';
    } else {
      // Different month or year, format as "15 Jan - 20 Feb 2025"
      final fullStartFormatter = DateFormat('dd MMM');
      return '${fullStartFormatter.format(startDate)} - ${endFormatter.format(endDate)}';
    }
  }
  
  // Format delivery date (with day name)
  static String formatDeliveryDate(DateTime date) {
    final formatter = DateFormat('EEE, dd MMM yyyy');
    return formatter.format(date);
  }
  
  // Get Indian season based on month
  static String getSeasonFromDate(DateTime date) {
    final month = date.month;
    
    if (month >= 3 && month <= 6) {
      return 'Summer';
    } else if (month >= 7 && month <= 10) {
      return 'Monsoon';
    } else {
      return 'Winter';
    }
  }
  
  // Get crop season based on date (Indian agricultural seasons)
  static String getCropSeasonFromDate(DateTime date) {
    final month = date.month;
    
    if (month >= 6 && month <= 10) {
      return 'Kharif (Monsoon)';
    } else if (month >= 11 || month <= 3) {
      return 'Rabi (Winter)';
    } else {
      return 'Zaid (Summer)';
    }
  }
  
  // Parse date from string (format: dd/MM/yyyy)
  static DateTime? parseDate(String dateString) {
    try {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // Parse date and time from string (format: dd/MM/yyyy HH:mm)
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      final formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
  
  // Calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }
}