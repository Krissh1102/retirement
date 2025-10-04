import 'package:flutter/material.dart';
import 'package:retierment/widgets/formatters.dart';

class TransactionsTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionsTab({Key? key, required this.transactions})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final type = transaction['type']?.toString() ?? '';
        final isCredit = type == 'sell' || type == 'dividend';
        final isDebit = type == 'buy' || type == 'sip';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isDebit ? Colors.red : Colors.green,
              child: Icon(
                isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
            title: Text(
              transaction['description'] ?? '${type.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(formatDate(transaction['timestamp'])),
                if (transaction['symbol'] != null)
                  Text(
                    transaction['symbol'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
            trailing: Text(
              '${isDebit ? '-' : '+'}₹${formatAmount(transaction['amount']?.toDouble() ?? 0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDebit ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}
