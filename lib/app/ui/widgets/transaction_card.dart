// Transaction card widget
import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Transaction Title'),
            SizedBox(height: 8),
            Text('Transaction Description'),
          ],
        ),
      ),
    );
  }
}
