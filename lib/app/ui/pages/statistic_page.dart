import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/controllers/statistic_controller.dart';
import 'package:aplikasiku/app/controllers/home_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/error_boundary.dart';
import '../../core/errors/app_exception.dart';

class StatisticPage extends GetView<StatisticController> {
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color primary = Color(0xFF0F172A);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final compactCurrency = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 1,
  );

  final RxString selectedTab = 'overview'.obs;
  final RxBool isAddingBudget = false.obs;

  // Buffer filter state untuk modal filter UI (sementara, diterapkan saat tekan Terapkan)
  final RxString filterTypeBuffer = 'all'.obs;
  final RxString transactionTypeFilterBuffer = 'all'.obs;
  final RxInt monthBuffer = 0.obs;
  final RxInt yearBuffer = 0.obs;

  // Access HomeController to get transaction types for filtering
  final HomeController? homeController = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : null;

  final List<Color> chartColors = [
    const Color(0xFF14B8A6),
    const Color(0xFF06B6D4),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    // Call onPageEnter when page is built (refreshes data every time page is entered)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageEnter();
    });

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingWidget(
            message: 'Loading statistics...',
            type: LoadingType.profilePage,
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showFilterModal(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          color: primary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            final year = controller.selectedYear.value;
                            final month = controller.selectedMonth.value;
                            final typeId =
                                controller.selectedJenisKategori.value;
                            String typeLabel = 'All Types';
                            if (typeId != 'all' && homeController != null) {
                              final type = homeController!.transactionTypes
                                  .firstWhereOrNull(
                                    (t) => t['id'].toString() == typeId,
                                  );
                              typeLabel =
                                  type?['nama'] ?? type?['name'] ?? 'Unknown';
                            }
                            return Text(
                              'Filter: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month))} • $typeLabel',
                              style: TextStyle(fontSize: 14, color: foreground),
                            );
                          }),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ShadTabs<String>(
                  value: selectedTab.value,
                  onChanged: (value) {
                    selectedTab.value = value;
                  },
                  tabs: const [
                    ShadTab(value: 'overview', child: Text('Overview')),
                    ShadTab(value: 'category', child: Text('Category Details')),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(
                  () => selectedTab.value == 'overview'
                      ? _buildOverviewTab()
                      : _buildCategoryTab(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        _buildSummaryCard(
          'Income',
          currency.format(controller.totalIncome),
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Expense',
          currency.format(controller.totalExpense),
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Balance',
          currency.format(controller.netBalance),
          primary,
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _buildSummarySection(),
        const SizedBox(height: 16),
        _buildDistributionChart(
          title: 'Income Distribution',
          isEmpty: controller.incomeDistributionData.isEmpty,
          data: controller.incomeDistributionData,
          getCategoryLabel: (item) =>
              controller.getCategoryLabel(item['category']),
        ),
        const SizedBox(height: 16),
        _buildDistributionChart(
          title: 'Expense Distribution',
          isEmpty: controller.expenseData.isEmpty,
          data: controller.expenseData,
          getCategoryLabel: (item) =>
              controller.getCategoryLabel(item['category']),
        ),
        const SizedBox(height: 16),
        _buildIncomeVsExpenseBarChart(),
      ],
    );
  }

  Widget _buildDistributionChart({
    required String title,
    required bool isEmpty,
    required List<Map<String, dynamic>> data,
    required String Function(Map<String, dynamic>) getCategoryLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No ${title.toLowerCase()} data',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {},
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: data.asMap().entries.map((entry) {
                    final item = entry.value;
                    final totalValue = data
                        .map((d) => (d['amount'] ?? 0).toDouble())
                        .where((v) => v > 0)
                        .fold(0.0, (a, b) => a + b);

                    return PieChartSectionData(
                      value: (item['amount'] ?? 0).toDouble(),
                      color: chartColors[entry.key % chartColors.length],
                      radius: totalValue > 0 ? 60 : 0,
                      title: '',
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                final item = entry.value;
                final label = getCategoryLabel(item);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: chartColors[entry.key % chartColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 12, color: muted)),
                    const SizedBox(width: 8),
                    Text(
                      currency.format(item['amount'] ?? 0),
                      style: TextStyle(fontSize: 12, color: foreground),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(),
                ),
                alignment: BarChartAlignment.spaceAround,
                maxY: () {
                  final values = controller.incomeVsExpenseData
                      .expand<num>((e) => [e['income'] ?? 0, e['expense'] ?? 0])
                      .where((v) => v > 0)
                      .toList();
                  if (values.isEmpty) return 5500.0;
                  return values.reduce((a, b) => a > b ? a : b).toDouble() *
                      1.2;
                }(),
                barGroups: controller.incomeVsExpenseData.asMap().entries.map((
                  entry,
                ) {
                  final data = entry.value;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (data['income'] ?? 0).toDouble(),
                        color: const Color(0xFF14B8A6),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: (data['expense'] ?? 0).toDouble(),
                        color: const Color(0xFFEF4444),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() <
                            controller.incomeVsExpenseData.length) {
                          return Text(
                            controller.incomeVsExpenseData[value
                                    .toInt()]['month'] ??
                                '',
                            style: TextStyle(fontSize: 12, color: muted),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        final formatted = compactCurrency
                            .format(value)
                            .replaceAll('.0', '');
                        return Text(
                          formatted,
                          style: TextStyle(fontSize: 11, color: muted),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab() {
    return Builder(
      builder: (context) => Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget vs Spent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 16),
                ...controller.budgetVsSpent.map(
                  (category) => _buildCategoryItem(category, context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Spending Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.topSpendingCategories.isEmpty)
                  Text(
                    'No spending data available.',
                    style: TextStyle(fontSize: 13, color: muted),
                  )
                else
                  ...controller.topSpendingCategories.asMap().entries.map(
                    (entry) => _buildTopCategoryItem(entry.key + 1, {
                      'name': controller.getCategoryLabel(
                        entry.value['category'],
                      ),
                      'value': entry.value['amount'] ?? 0,
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> category,
    BuildContext context,
  ) {
    final spent = (category['spent'] ?? 0) as int;
    final budget = (category['budget'] ?? 0) as int;
    final percentage = budget > 0
        ? ((spent.toDouble() / budget) * 100).round()
        : 0;
    final isOverBudget = percentage > 85;
    final isWarning = percentage > 70;
    final categoryLabel = controller.getCategoryLabel(
      category['category'] ?? category['category_id'],
    );

    return Column(
      children: [
        Row(
          children: [
            Text('📦', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showBudgetDialog(
                          context,
                          existingBudget: category,
                        ),
                        icon: Icon(Icons.edit, size: 16, color: primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ${currency.format(spent)}',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      Text(
                        'Budget: ${currency.format(budget)}',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isOverBudget
                                    ? Colors.red
                                    : isWarning
                                    ? Colors.yellow
                                    : primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currency.format(budget - spent)} remaining',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (category != controller.budgetVsSpent.last)
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopCategoryItem(int rank, Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category['name'],
              style: TextStyle(fontSize: 14, color: foreground),
            ),
          ),
          Text(
            currency.format(category['value']),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = controller.selectedJenisKategori.value == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.changeJenisKategori(value);
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

  void _showFilterModal(BuildContext context) {
    if (!context.mounted) return;

    int localMonth = controller.selectedMonth.value; // This is correct (1-12)
    int localYear = controller.selectedYear.value;
    String localTransactionType = controller.selectedJenisKategori.value;

    showDialog(
      context: context, // Gunakan context dari builder
      builder: (context) => Dialog(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: StatefulBuilder(
            builder: (dialogContext, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Statistik',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(Icons.close, color: muted),
                      ),
                    ],
                  ),
                  // Date Filter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMonthDropdown(localMonth, (val) {
                              if (val != null) setState(() => localMonth = val);
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildYearDropdown(localYear, (val) {
                              if (val != null) setState(() => localYear = val);
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Transaction Category Filter (Jenis Transaksi)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jenis Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (builderContext) {
                          final types = homeController?.transactionTypes ?? [];
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.5,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildModalTransactionTypeChip(
                                'all',
                                'Semua',
                                localTransactionType,
                                (val) {
                                  setState(() => localTransactionType = val);
                                },
                              ),
                              ...types.map(
                                (type) => _buildModalTransactionTypeChip(
                                  type['id'].toString(),
                                  type['nama'] ?? type['name'] ?? 'Unknown',
                                  localTransactionType,
                                  (val) {
                                    setState(() => localTransactionType = val);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              final now = DateTime.now();
                              localMonth = now.month;
                              localYear = now.year;
                              localTransactionType = 'all';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(color: foreground),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadButton(
                          onPressed: () async {
                            await controller.changeFilters(
                              localMonth,
                              localYear,
                              localTransactionType,
                            );
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown(int currentMonth, ValueChanged<int?> onChanged) {
    final months = List.generate(12, (index) => index + 1);
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: currentMonth,
        isExpanded: true,
        underline: const SizedBox(),
        items: months.map((month) {
          return DropdownMenuItem<int>(
            value: month,
            child: Text(
              DateFormat('MMMM', 'id_ID').format(DateTime(2020, month)),
              style: TextStyle(color: foreground, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildYearDropdown(
    int currentYearValue,
    ValueChanged<int?> onChanged,
  ) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);
    years.add(currentYearValue);
    final uniqueYears = years.toSet().toList()..sort();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: currentYearValue,
        isExpanded: true,
        underline: const SizedBox(),
        items: uniqueYears.map((year) {
          return DropdownMenuItem<int>(
            value: year,
            child: Text(
              year.toString(),
              style: TextStyle(color: foreground, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModalFilterChipBuffered(
    String value,
    String label,
    RxString bufferValue,
  ) {
    final bool isSelected = bufferValue.value == value;
    return Container(
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primary : background,
        border: Border.all(color: isSelected ? primary : border),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? primaryForeground : foreground,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildModalTransactionTypeChip(
    String value,
    String label,
    String groupValue,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : background,
          border: Border.all(color: isSelected ? primary : border),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? primary : foreground,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final initialYear = controller.selectedYear.value;
    final initialMonth = controller.selectedMonth.value;
    int selectedYear = initialYear;
    int selectedMonth = initialMonth;
    final List<int> years = List.generate(15, (index) => 2018 + index);
    final List<int> months = List.generate(12, (index) => index + 1);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Bulan dan Tahun'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedMonth = value);
                    },
                    items: months
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat(
                                'MMMM',
                                'id_ID',
                              ).format(DateTime(2020, month)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedYear,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedYear = value);
                    },
                    items: years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.changePeriod(selectedMonth, selectedYear);
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBudgetDialog(
    BuildContext context, {
    Map<String, dynamic>? existingBudget,
  }) async {
    final TextEditingController budgetController = TextEditingController(
      text: existingBudget != null
          ? (existingBudget['budget'] ?? 0).toString()
          : '',
    );
    final bool isEdit = existingBudget != null;
    final int categoryId = existingBudget?['category_id'] ?? 0;
    String categoryName = existingBudget != null
        ? controller.getCategoryLabel(existingBudget['category'])
        : '';

    await showDialog(
      context: context,
      barrierDismissible: !isAddingBudget.value,
      builder: (dialogContext) {
        return Obx(() {
          return IgnorePointer(
            ignoring: isAddingBudget.value,
            child: Stack(
              children: [
                AlertDialog(
                  title: Text(isEdit ? 'Edit Budget' : 'Add Budget'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdit) Text('Category: $categoryName'),
                      const SizedBox(height: 16),
                      ShadInput(
                        controller: budgetController,
                        placeholder: Text('Enter budget amount'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isAddingBudget.value
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    ShadButton(
                      onPressed: isAddingBudget.value
                          ? null
                          : () async {
                              final budget = int.tryParse(
                                budgetController.text,
                              );
                              if (budget == null || budget <= 0) {
                                if (context.mounted) {
                                  ShadToaster.of(context).show(
                                    ShadToast.destructive(
                                      title: const Text('Invalid budget value'),
                                      description: const Text(
                                        'Please enter a valid budget greater than 0.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                isAddingBudget(true);
                                await controller.addBudget(categoryId, budget);
                                Navigator.of(dialogContext).pop();
                                if (context.mounted) {
                                  ShadToaster.of(context).show(
                                    ShadToast(
                                      title: Text(
                                        isEdit
                                            ? "Budget updated"
                                            : "Budget added",
                                      ),
                                      description: Text(
                                        isEdit
                                            ? "Budget successfully updated for $categoryName."
                                            : "Budget successfully added for $categoryName.",
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ShadToaster.of(context).show(
                                    ShadToast.destructive(
                                      title: const Text('Failed'),
                                      description: Text(
                                        "Failed to ${isEdit ? 'update' : 'add'} budget. Please try again.",
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                isAddingBudget(false);
                              }
                            },
                      child: isAddingBudget.value
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
                if (isAddingBudget.value)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.07),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          );
        });
      },
    );
  }
}
