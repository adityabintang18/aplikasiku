import 'package:intl/intl.dart';

class TransactionType {
  static const String income = 'income';
  static const String expense = 'expense';
  static const String transfer = 'transfer';
}

class TransactionModel {
  final int id;
  final String title;
  final int categoryId;
  final bool isIncome;
  final DateTime date;
  final double amount;
  final String? description;
  final String? photoUrl;
  final String categoryName;
  final String transactionTypeName;

  TransactionModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.isIncome,
    required this.date,
    required this.amount,
    this.description,
    this.photoUrl,
    required this.categoryName,
    required this.transactionTypeName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      categoryId: _parseInt(json['category']) ?? 0,
      isIncome: _parseBool(json['is_income']),
      date: _parseDateTime(json['date']),
      amount: _parseDouble(json['amount']) ?? 0.0,
      description: json['description']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      categoryName: json['nama_kategori']?.toString() ?? '',
      transactionTypeName: json['nama_jenis_kategori']?.toString() ?? '',
    );
  }

  // Helper methods for parsing
  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // Fallback to current date if parsing fails
      }
    }
    return DateTime.now();
  }

  // Business logic methods
  String get transactionType =>
      isIncome ? TransactionType.income : TransactionType.expense;

  String get formattedAmount {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return currency.format(amount);
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  String get shortDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari ini';
    if (dateOnly == yesterday) return 'Kemarin';
    return DateFormat('dd/MM', 'id_ID').format(date);
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  // Copy with method for immutability
  TransactionModel copyWith({
    int? id,
    String? title,
    int? categoryId,
    bool? isIncome,
    DateTime? date,
    double? amount,
    String? description,
    String? photoUrl,
    String? categoryName,
    String? transactionTypeName,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      isIncome: isIncome ?? this.isIncome,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      categoryName: categoryName ?? this.categoryName,
      transactionTypeName: transactionTypeName ?? this.transactionTypeName,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': categoryId,
      'is_income': isIncome,
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
      'photo_url': photoUrl,
      'nama_kategori': categoryName,
      'nama_jenis_kategori': transactionTypeName,
    };
  }

  // Equality override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $formattedAmount, date: $formattedDate)';
  }
}
