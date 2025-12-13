class FinansialModel {
  final int id;
  final String title;
  final int category;
  final bool isIncome;
  final String date;
  final double amount;
  final String? description;
  final String? photoUrl;
  final String namaKategori;
  final String namaJenisKategori;
  final String? effectiveMonth;

  FinansialModel({
    required this.id,
    required this.title,
    required this.category,
    required this.isIncome,
    required this.date,
    required this.amount,
    this.description,
    this.photoUrl,
    required this.namaKategori,
    required this.namaJenisKategori,
    this.effectiveMonth,
  });

  factory FinansialModel.fromJson(Map<String, dynamic> json) {
    return FinansialModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category'] is int
          ? json['category'] as int
          : int.tryParse(json['category']?.toString() ?? '') ?? 0,
      isIncome: (json['is_income'] is bool)
          ? json['is_income'] as bool
          : (json['is_income']?.toString() == '1' ||
              json['is_income']?.toString().toLowerCase() == 'true'),
      date: json['date']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      description: json['description']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      namaKategori: json['nama_kategori']?.toString() ?? '',
      namaJenisKategori: json['nama_jenis_kategori']?.toString() ?? '',
      effectiveMonth: json['effective_month']?.toString(),
    );
  }
}
