import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/controllers/home_controller.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';
import 'package:aplikasiku/app/ui/widgets/add_transaction_modal.dart';
import 'package:aplikasiku/app/ui/widgets/loading_widget.dart';
import 'package:aplikasiku/app/ui/widgets/error_widget.dart';
import 'package:aplikasiku/app/ui/widgets/error_boundary.dart';
import 'package:aplikasiku/app/ui/widgets/update_required_page.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<HomeController>();
  final logger = Logger();

  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color primary = Color(0xFF0F172A);

  bool _firstLoad = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    Future.microtask(() async {
      await controller.onPageEnter(); // Auto refresh when entering page
      if (mounted) setState(() => _firstLoad = false);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return UpdateRequiredPage(
      forceUpdateOnPageEnter: true,
      child: SafeArea(
        child: ErrorBoundary(
          onError: (context, error, stack) => AppErrorWidget(
            error: error as AppException,
            onRetry: () => controller.refreshData(),
          ),
          child: Obx(() {
            if (controller.isInitialLoading.value || _firstLoad) {
              return const AppLoadingWidget(
                message: 'Loading your dashboard...',
                type: LoadingType.homePage,
              );
            }

            final summary = controller.summary;
            final transaksi = List<FinansialModel>.from(
              controller.filteredTransactions,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting card with padding
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildGreetingCard(),
                  ),

                  // Transaction type filter with padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTransactionTypeFilter(),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSummaryCard(summary, currency),
                  ),
                  // Full width summary card (no padding constraint)

                  // Rest of content with padding
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryMenu(),
                        const SizedBox(height: 24),
                        Text(
                          "Highlights",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHighlightCard(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Transactions",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: foreground,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/transaction'),
                              child: Text(
                                "See All",
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._getRecentTransactions(transaksi, currency),
                        const SizedBox(height: 24),
                        _buildTipsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _getRecentTransactions(
    List<FinansialModel> transaksi,
    NumberFormat currency,
  ) {
    if (transaksi.isEmpty) {
      return [
        Obx(() {
          if (controller.transactionsError.value != null) {
            return AppErrorWidget(
              error: controller.transactionsError.value!,
              onRetry: () => controller.fetchAllTransaksi(),
            );
          }
          return Container(
            height: 80,
            decoration: BoxDecoration(
              color: accent,
              border: Border.all(color: border, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "No transactions yet.",
                style: TextStyle(
                  color: muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ];
    }
    return transaksi
        .take(5)
        .map((t) => _buildTransactionItem(t, currency))
        .toList();
  }

  Widget _buildGreetingCard() {
    return Obx(() {
      if (controller.userInfoError.value != null) {
        return AppErrorWidget(
          error: controller.userInfoError.value!,
          onRetry: () => controller.fetchUserInfo(),
        );
      }

      if (controller.isUserInfoLoading.value) {
        return Container(
          decoration: BoxDecoration(
            color: accent,
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: AppLoadingWidget(type: LoadingType.pulse, size: 16),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLoadingWidget(type: LoadingType.skeleton, size: 12),
                    SizedBox(height: 8),
                    AppLoadingWidget(type: LoadingType.skeleton, size: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      final userInfo = controller.userInfo;
      final userName = (userInfo['name'] ?? "User").toString();

      final nameWords = userName.split(' ');
      final displayedName =
          nameWords.length > 2 ? nameWords.sublist(0, 2).join(' ') : userName;
      final greeting = _getGreeting();

      return Container(
        decoration: BoxDecoration(
          color: accent,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: border,
                  backgroundImage: userInfo['photo_url'] != null
                      ? NetworkImage(userInfo['photo_url'])
                      : const AssetImage('assets/avatar.png') as ImageProvider,
                  child: userInfo['photo_url'] == null
                      ? Text(
                          _getInitials(userName),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                    Text(
                      '$displayedName!',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () => controller.refreshData(),
              icon: Icon(Icons.refresh_rounded, color: muted),
              style: IconButton.styleFrom(
                backgroundColor: background,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else if (hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return parts[0][0].toUpperCase();
      }
    }
    return "U";
  }

  Widget _buildSummaryCard(Map summary, NumberFormat currency) {
    return Obx(() {
      if (controller.isSummaryLoading.value &&
          !controller.isInitialLoading.value) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Balance",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Loading...",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final isEmpty = summary.isEmpty || summary['total'] == null;
      final balance = !isEmpty ? (summary['total']['balance'] ?? 0) : 0;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currency.format(balance ?? 0),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Access",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCategoryItem(
              icon: Icons.money_rounded,
              label: "Transaction",
              color: Colors.green,
              route: "/transaction",
              onTap: () => showDialog(
                context: context,
                builder: (context) => const AddTransactionModal(),
              ),
            ),
            _buildCategoryItem(
              icon: Icons.savings_rounded,
              label: "Savings",
              color: primary,
              route: "/savings",
              onTap: () => context.go("/savings"),
            ),
            _buildCategoryItem(
              icon: Icons.flag_rounded,
              label: "Goals",
              color: Colors.purple,
              route: "/goals",
              onTap: () => context.go("/goals"),
            ),
            _buildCategoryItem(
              icon: Icons.insert_chart_rounded,
              label: "Reports",
              color: Colors.blue,
              route: "/reports",
              onTap: () => context.go("/reports"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required Color color,
    required String route,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard() {
    return Obx(() {
      final summary = controller.summary;

      final total = summary['total'];
      final thisMonth =
          total != null && total['balance'] != null ? total['balance'] : 0;
      final spent =
          total != null && total['expense'] != null ? total['expense'] : 0;
      final income =
          total != null && total['income'] != null ? total['income'] : 0;
      final saved = (income - spent) > 0 ? (income - spent) : 0;

      final currency = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      );

      // Don't show skeleton if we're just filtering transactions, not loading initial data
      if (controller.isSummaryLoading.value &&
          controller.filteredTransaksiList.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AppLoadingWidget(type: LoadingType.skeleton, size: 16),
              AppLoadingWidget(type: LoadingType.skeleton, size: 16),
              AppLoadingWidget(type: LoadingType.skeleton, size: 16),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _HighlightItem(
              label: "This Month",
              value: currency.format(thisMonth ?? 0),
            ),
            _HighlightItem(label: "Spent", value: currency.format(spent ?? 0)),
            _HighlightItem(label: "Saved", value: currency.format(saved ?? 0)),
          ],
        ),
      );
    });
  }

  Widget _buildTransactionItem(FinansialModel t, NumberFormat currency) {
    final isIncome = t.isIncome;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          t.title,
          style: TextStyle(fontWeight: FontWeight.w500, color: foreground),
        ),
        subtitle: Text(
          DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.tryParse(t.date) ?? DateTime.now()),
          style: TextStyle(color: muted),
        ),
        trailing: Text(
          "${isIncome ? '+' : '-'}${currency.format(t.amount)}",
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Obx(() {
      if (controller.isDailyTipLoading.value) {
        return Container(
          decoration: BoxDecoration(
            color: accent,
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: const AppLoadingWidget(type: LoadingType.skeleton, size: 14),
        );
      }

      final rawTip = controller.dailyTip.value.isNotEmpty
          ? controller.dailyTip.value
          : "Set a monthly savings target and track it regularly to stay consistent.";

      // Clean up the tip: remove formatting and clean the text
      String cleanedTip = rawTip;

      // Remove quote marks and extra formatting from Hugging Face API
      cleanedTip = cleanedTip
          .replaceAll('**"', '')
          .replaceAll('"', '')
          .replaceAll('**', '');
      cleanedTip = cleanedTip.replaceAll(
        '**',
        '',
      ); // Remove remaining bold markers

      // Clean up whitespace and newlines
      cleanedTip = cleanedTip.replaceAll(
        '\n\n',
        ' ',
      ); // Replace double newlines with space
      cleanedTip = cleanedTip.replaceAll(
        '\n',
        ' ',
      ); // Replace single newlines with space
      cleanedTip = cleanedTip.replaceAll(
        '  ',
        ' ',
      ); // Replace multiple spaces with single space
      cleanedTip = cleanedTip.trim();

      // Handle italic text in parentheses - make it a separate line with proper formatting
      if (cleanedTip.contains('*(') && cleanedTip.contains(')*')) {
        cleanedTip = cleanedTip.replaceAllMapped(
          RegExp(r'\*\((.*?)\)\*'),
          (match) => '\n\n(${match.group(1)})',
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: accent,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Tips Finansial",
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              cleanedTip,
              style: TextStyle(color: foreground, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTransactionTypeFilter() {
    return Obx(() {
      final transactionTypes = controller.transactionTypes;
      if (controller.isTransactionTypesLoading.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const AppLoadingWidget(type: LoadingType.skeleton, size: 16),
        );
      }

      if (transactionTypes.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showAddTransactionTypeDialog(),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              ...transactionTypes.map((type) {
                final typeId = type['id']?.toString() ?? '';
                final typeName = type['nama'] ?? 'Unknown';
                return Row(
                  children: [
                    _buildFilterChip(typeName, typeId),
                    const SizedBox(width: 8),
                  ],
                );
              }).toList(),
              IconButton(
                onPressed: () => _showAddTransactionTypeDialog(),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showAddTransactionTypeDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Transaction Type'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter type name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final nama = nameController.text.trim();
                if (nama.isNotEmpty) {
                  controller.addJenisKategori(nama);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = controller.selectedTransactionTypeId.value == value;
    final isLoading = controller.isTransactionsLoading.value && isSelected;

    if (isLoading) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3), width: 1),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.setTransactionTypeFilter(value);
        }
      },
      backgroundColor: isSelected ? primary.withOpacity(0.1) : accent,
      selectedColor: primary.withOpacity(0.2),
      checkmarkColor: primary,
      labelStyle: TextStyle(
        color: isSelected ? primary : foreground,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? primary : border, width: 1),
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final String label;
  final String value;

  const _HighlightItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }
}
