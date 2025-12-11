import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasiku/app/data/models/enhanced_financial_model.dart';
import 'package:aplikasiku/app/ui/components/base/base_widget.dart';

class TransactionCard extends BaseWidget {
  final TransactionModel transaction;

  const TransactionCard({Key? key, required this.transaction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/transaction-detail', extra: transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: BaseWidget.background,
          border: Border.all(color: BaseWidget.border, width: 1),
          borderRadius: BaseWidget.borderRadius,
        ),
        child: Padding(
          padding: BaseWidget.paddingMedium,
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildTransactionInfo()),
              const SizedBox(width: 8),
              _buildAmount(),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: BaseWidget.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: BaseWidget.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          _getCategoryEmoji(transaction.categoryName),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildTransactionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.title,
          style: BaseWidget.bodyStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(transaction.categoryName, style: BaseWidget.captionStyle),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transaction.isIncome
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BaseWidget.smallBorderRadius,
              ),
              child: Text(
                transaction.transactionTypeName,
                style: TextStyle(
                  fontSize: 10,
                  color: transaction.isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Text(
        transaction.formattedAmount,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: transaction.isIncome ? Colors.green : Colors.red,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    final emojiMap = {
      'Belanja': '🛍️',
      'Bonus': '🎁',
      'Gaji': '💰',
      'Hiburan': '🎬',
      'Investasi': '📈',
      'Kesehatan': '🩺',
      'Lain-lain': '📋',
      'Makanan & Minuman': '🍽️',
      'Pendidikan': '🎓',
      'Tabungan': '🏦',
      'Tagihan & Utilitas': '💡',
      'Transportasi': '🚗',
    };
    return emojiMap[category] ?? '📦';
  }
}
