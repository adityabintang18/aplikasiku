import 'package:flutter/material.dart' hide MaterialApp, Scaffold;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/controllers/statistic_controller.dart';
import 'package:aplikasiku/app/controllers/home_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/loading_widget.dart';
import 'package:aplikasiku/app/utils/helpers.dart';

class StatisticPage extends GetView<StatisticController> {
  StatisticPage({super.key});
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

  // Access HomeController to get transaction types for filtering
  final HomeController? homeController =
      Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

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
    // Auto trigger data loading when page is opened
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

        return _buildMainContent();
      }),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFilterSection(),
            const SizedBox(height: 24),
            _buildTabsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Statistics',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }

  Widget _buildFilterSection() {
    return Builder(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('Filter section tapped!');
              _showFilterModal(context);
            },
            borderRadius: BorderRadius.circular(12),
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
                      return _buildFilterText();
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
        );
      },
    );
  }

  Widget _buildFilterText() {
    final year = controller.selectedYear.value;
    final month = controller.selectedMonth.value;
    final typeId = controller.selectedJenisKategori.value;
    String typeLabel = 'All Types';

    if (typeId != 'all' && homeController != null) {
      try {
        final type = homeController!.transactionTypes.firstWhereOrNull(
          (t) => t['id'].toString() == typeId,
        );
        typeLabel = type?['nama'] ?? type?['name'] ?? 'Unknown';
      } catch (e) {
        typeLabel = 'Unknown Type';
      }
    }

    return Text(
      'Filter: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime(year, month))} • $typeLabel',
      style: TextStyle(fontSize: 14, color: foreground),
    );
  }

  Widget _buildTabsSection() {
    return Column(
      children: [
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
          _safeFormatCurrency(controller.totalIncome),
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Expense',
          _safeFormatCurrency(controller.totalExpense),
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Balance',
          _safeFormatCurrency(controller.netBalance),
          primary,
        ),
      ],
    );
  }

  String _safeFormatCurrency(int amount) {
    try {
      return currency.format(amount);
    } catch (e) {
      return 'Rp ${formatAmountDisplay(amount.toDouble())}';
    }
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
          getCategoryLabel: (item) => _safeGetCategoryLabel(item['category']),
        ),
        const SizedBox(height: 16),
        _buildDistributionChart(
          title: 'Expense Distribution',
          isEmpty: controller.expenseData.isEmpty,
          data: controller.expenseData,
          getCategoryLabel: (item) => _safeGetCategoryLabel(item['category']),
        ),
        const SizedBox(height: 16),
        _buildIncomeVsExpenseBarChart(),
      ],
    );
  }

  String _safeGetCategoryLabel(dynamic category) {
    try {
      return controller.getCategoryLabel(category);
    } catch (e) {
      return 'Unknown Category';
    }
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
          else if (data.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No data available',
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
                  sections: _buildPieChartSections(data),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(data, getCategoryLabel),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final item = entry.value;
      final amount = (item['amount'] ?? 0).toDouble();
      final totalValue = data
          .map((d) => (d['amount'] ?? 0).toDouble())
          .where((v) => v > 0)
          .fold(0.0, (a, b) => a + b);

      return PieChartSectionData(
        value: amount,
        color: chartColors[entry.key % chartColors.length],
        radius: totalValue > 0 ? 60 : 0,
        title: '',
      );
    }).toList();
  }

  Widget _buildChartLegend(
    List<Map<String, dynamic>> data,
    String Function(Map<String, dynamic>) getCategoryLabel,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.asMap().entries.map((entry) {
        final item = entry.value;
        final label = getCategoryLabel(item);
        final amount = item['amount'] ?? 0;

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
            Text(
              label,
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(width: 8),
            Text(
              _safeFormatCurrency(amount),
              style: TextStyle(fontSize: 12, color: foreground),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildIncomeVsExpenseBarChart() {
    final data = controller.incomeVsExpenseData;

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
          if (data.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              ),
            )
          else
            SizedBox(
              height: 280, // Increased height for better spacing
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => background,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = data[group.x.toInt()];
                        final isIncome = rodIndex == 0;
                        return BarTooltipItem(
                          '${isIncome ? "Income" : "Expense"}: ${_safeFormatCurrency(rod.toY.round())}',
                          TextStyle(
                            color: isIncome
                                ? const Color(0xFF14B8A6)
                                : const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: _calculateMaxY(data),
                  barGroups: _buildBarChartGroups(data),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index]['month'] ?? '',
                                style: TextStyle(fontSize: 10, color: muted),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 70, // Increased reserved space
                        interval: _calculateYAxisInterval(data),
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          final formatted = _formatCompactCurrency(value);
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              formatted,
                              style: TextStyle(fontSize: 9, color: muted),
                              textAlign: TextAlign.right,
                            ),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateYAxisInterval(data),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: border.withOpacity(0.3),
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: border.withOpacity(0.5), width: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> data) {
    final values = data
        .expand<num>((e) => [e['income'] ?? 0, e['expense'] ?? 0])
        .where((v) => v > 0)
        .toList();
    if (values.isEmpty) return 5000000.0; // 5M default
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    // Round up to nearest nice number
    final roundedMax = _roundUpToNiceNumber(maxValue * 1.15);
    return roundedMax;
  }

  double _calculateYAxisInterval(List<Map<String, dynamic>> data) {
    final maxY = _calculateMaxY(data);
    // Create 4-5 intervals for Y-axis
    return maxY / 4;
  }

  double _roundUpToNiceNumber(double value) {
    if (value <= 1000000) {
      return (value / 100000).round() * 100000.0;
    } else if (value <= 10000000) {
      return (value / 1000000).round() * 1000000.0;
    } else {
      return (value / 10000000).round() * 10000000.0;
    }
  }

  String _formatCompactCurrency(dynamic value) {
    try {
      final numValue = value.toDouble();
      if (numValue >= 1000000000) {
        return '${(numValue / 1000000000).toStringAsFixed(1)}B';
      } else if (numValue >= 1000000) {
        return '${(numValue / 1000000).toStringAsFixed(1)}M';
      } else if (numValue >= 1000) {
        return '${(numValue / 1000).toStringAsFixed(0)}K';
      } else {
        return numValue.toStringAsFixed(0);
      }
    } catch (e) {
      return '0';
    }
  }

  List<BarChartGroupData> _buildBarChartGroups(
      List<Map<String, dynamic>> data) {
    return data.asMap().entries.map((entry) {
      final chartData = entry.value;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (chartData['income'] ?? 0).toDouble(),
            color: const Color(0xFF14B8A6),
            width: 16, // Optimal width to prevent overlap
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
          BarChartRodData(
            toY: (chartData['expense'] ?? 0).toDouble(),
            color: const Color(0xFFEF4444),
            width: 16, // Optimal width to prevent overlap
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
          ),
        ],
      );
    }).toList();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget vs Spent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddCategoryDialog(context),
                      icon: const Icon(Icons.add, size: 20, color: primary),
                      style: IconButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      tooltip: 'Tambah Kategori',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (controller.budgetVsSpent.isEmpty)
                  Text(
                    'No budget data available.',
                    style: TextStyle(fontSize: 13, color: muted),
                  )
                else
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
                          'name': _safeGetCategoryLabel(
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
    final percentage =
        budget > 0 ? ((spent.toDouble() / budget) * 100).round() : 0;
    final isOverBudget = percentage > 85;
    final isWarning = percentage > 70;
    final categoryLabel = _safeGetCategoryLabel(
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
                        'Spent: ${_safeFormatCurrency(spent)}',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      Text(
                        'Budget: ${_safeFormatCurrency(budget)}',
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
                            widthFactor: (percentage / 100).clamp(0.0, 1.0),
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
                    '${_safeFormatCurrency(budget - spent)} remaining',
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
    final name = category['name'] ?? 'Unknown';
    final value = category['value'] ?? 0;

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
              name,
              style: TextStyle(fontSize: 14, color: foreground),
            ),
          ),
          Text(
            _safeFormatCurrency(value),
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

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final RxBool isAdding = false.obs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final RxString deskripsiValue = 'Pengeluaran'.obs;

        return Obx(() {
          return AlertDialog(
            backgroundColor: background,
            title: const Text('Tambah Kategori Transaksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  controller: nameController,
                  placeholder: const Text('Nama kategori'),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Padding(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Radio<String>(
                                    value: 'Pengeluaran',
                                    groupValue: deskripsiValue.value,
                                    onChanged: (value) {
                                      if (value != null) deskripsiValue(value);
                                    },
                                    activeColor: primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text('Pengeluaran'),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Radio<String>(
                                    value: 'Pemasukan',
                                    groupValue: deskripsiValue.value,
                                    onChanged: (value) {
                                      if (value != null) deskripsiValue(value);
                                    },
                                    activeColor: primary,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const Text('Pemasukan'),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed:
                    isAdding.value ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ShadButton(
                onPressed: isAdding.value
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: const Text('Nama kategori diperlukan'),
                                description: const Text(
                                    'Silakan masukkan nama kategori'),
                              ),
                            );
                          }
                          return;
                        }

                        try {
                          isAdding(true);
                          await homeController?.addCategory(
                            name,
                            deskripsi: deskripsiValue.value,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ShadToaster.of(context).show(
                              ShadToast(
                                title: const Text('Berhasil'),
                                description: Text(
                                    'Kategori "$name" berhasil ditambahkan'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast.destructive(
                                title: const Text('Gagal'),
                                description: const Text(
                                    'Gagal menambahkan kategori. Silakan coba lagi.'),
                              ),
                            );
                          }
                        } finally {
                          isAdding(false);
                        }
                      },
                child: isAdding.value
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tambah'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    if (!context.mounted) return;

    int localMonth = controller.selectedMonth.value;
    int localYear = controller.selectedYear.value;
    String localTransactionType = controller.selectedJenisKategori.value;

    showDialog(
      context: context,
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
                  const SizedBox(height: 24),
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
                            try {
                              await controller.changeFilters(
                                localMonth,
                                localYear,
                                localTransactionType,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (e) {
                              // Handle filter change error
                              if (dialogContext.mounted) {
                                ShadToaster.of(dialogContext).show(
                                  ShadToast.destructive(
                                    title: const Text('Error'),
                                    description: const Text(
                                        'Failed to apply filters. Please try again.'),
                                  ),
                                );
                              }
                            }
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
        ? _safeGetCategoryLabel(existingBudget['category'])
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
                        placeholder: const Text('Enter budget amount'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          ThousandsFormatter(),
                        ],
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
                              final budgetText = budgetController.text
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              final budget = int.tryParse(budgetText) ?? 0;

                              if (budget <= 0) {
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
