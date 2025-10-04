import 'package:intl/intl.dart';

String formatAmount(double amount) {
  if (amount >= 10000000) {
    return '${(amount / 10000000).toStringAsFixed(2)}Cr';
  } else if (amount >= 100000) {
    return '${(amount / 100000).toStringAsFixed(2)}L';
  } else if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(2)}K';
  } else {
    return amount.toStringAsFixed(0);
  }
}

String formatDate(dynamic timestamp) {
  if (timestamp == null) return 'Unknown date';

  try {
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = DateTime.parse(timestamp.toString());
    }
    return DateFormat('dd MMM yyyy').format(date);
  } catch (e) {
    return 'Invalid date';
  }
}