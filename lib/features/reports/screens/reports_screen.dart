import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/report_export_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/common/widgets/stockmate_components.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Navigation / Filter States per Spec Section 3
  String period = "monthly"; // "daily", "weekly", "monthly", "yearly"
  String tab = "summary"; // "summary" (Charts), "products" (Top Products), "export" (Export)
  String yearTab = "overview"; // "overview", "quarterly", "monthly", "pl"

  // Standard report constant datasets per Section 6.1
  static const Map<String, List<num>> salesData = {
    "daily": [42, 58, 71, 63, 89, 95, 77],
    "weekly": [380, 510, 620, 490, 710, 840, 680],
    "monthly": [1200, 1850, 1420, 2100, 1780, 2340, 1950, 2680, 2210, 2900, 2450, 3100],
    "yearly": [18400, 24600, 31200, 38900],
  };

  static const Map<String, List<num>> profitData = {
    "daily": [18, 25, 31, 27, 38, 42, 33],
    "weekly": [160, 215, 270, 210, 305, 360, 290],
    "monthly": [520, 800, 610, 910, 770, 1010, 840, 1160, 950, 1250, 1060, 1340],
    "yearly": [7200, 10100, 13400, 17220],
  };

  static const Map<String, List<String>> labels = {
    "daily": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    "weekly": ["W1", "W2", "W3", "W4", "W5", "W6", "W7"],
    "monthly": ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
    "yearly": ["2022", "2023", "2024", "2025"],
  };

  static const List<Map<String, dynamic>> categoryData = [
    {"name": "Electronics", "value": 42},
    {"name": "Stationery", "value": 24},
    {"name": "Furniture", "value": 15},
    {"name": "Health", "value": 10},
    {"name": "Kitchen", "value": 9},
  ];

  static const List<Map<String, dynamic>> topProducts = [
    {"name": "USB-C Cable 2m", "sold": 142, "revenue": 1844.58, "profit": 1351.58},
    {"name": "HDMI Cable 1.5m", "sold": 93, "revenue": 1487.07, "profit": 1068.57},
    {"name": "Desk Lamp LED", "sold": 61, "revenue": 3049.39, "profit": 1952.39},
    {"name": "Wireless Mouse", "sold": 44, "revenue": 1539.56, "profit": 1011.56},
    {"name": "Coffee Mug 350ml", "sold": 38, "revenue": 379.62, "profit": 265.62},
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final DatabaseService db = Get.find<DatabaseService>();
    final PermissionService perm = Get.find<PermissionService>();
    final ReportExportService exportService = Get.find<ReportExportService>();

    return Obx(() {
      final t = themeService.t;
      final currency = themeService.currentCurrency.value;

      // Staff access guard
      if (perm.isStaff) {
        return Scaffold(
          backgroundColor: t.bg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_person_rounded, size: 56, color: t.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Financial Reports Restricted',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Under Section 6 (Role-Based Access Control), Staff accounts do not have permission to view store margins, COGS, or business profit reports.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: t.textSec),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4.1 Header row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/settings');
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: t.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '←',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: t.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // 4.2 Period selector (Segmented Control)
                _buildPeriodSelector(t),
                const SizedBox(height: 14),

                // Body based on selected period
                if (period == "yearly")
                  _buildYearlyReport(t, currency, db)
                else
                  _buildStandardReport(t, currency, db, exportService),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // 4.2 Period Selector (Segmented Control)
  // ---------------------------------------------------------------------------
  Widget _buildPeriodSelector(ThemeTokens t) {
    const periods = ["daily", "weekly", "monthly", "yearly"];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = period == p;
          final title = p.substring(0, 1).toUpperCase() + p.substring(1);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  period = p;
                  tab = "summary"; // resets tab to summary per Section 3
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? t.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? t.text : t.textSec,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Standard Report (Daily / Weekly / Monthly)
  // ---------------------------------------------------------------------------
  Widget _buildStandardReport(
    ThemeTokens t,
    String currency,
    DatabaseService db,
    ReportExportService exportService,
  ) {
    final curSales = salesData[period]!;
    final curProfit = profitData[period]!;
    final curLabels = labels[period]!;

    final totalSales = curSales.fold<num>(0, (sum, v) => sum + v).toDouble();
    final totalProfit = curProfit.fold<num>(0, (sum, v) => sum + v).toDouble();
    final margin = totalSales > 0 ? ((totalProfit / totalSales) * 100).toStringAsFixed(1) : "0.0";
    final avgSale = (totalSales / curSales.length);

    // Hybrid expenses: use live totalExpenses if present, or fallback 3520 (spec sample total)
    final double totalExpenses = db.totalExpenses > 0 ? db.totalExpenses : 3520.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4.3 KPI tiles (2x2 grid)
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                label: 'Total Revenue',
                value: fmt(totalSales, currency),
                valueColor: t.accent,
                t: t,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiTile(
                label: 'Gross Profit',
                value: fmt(totalProfit, currency),
                valueColor: t.success,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                label: 'Margin',
                value: '$margin%',
                valueColor: t.purple,
                t: t,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiTile(
                label: 'Avg Sale',
                value: fmt(avgSale, currency),
                valueColor: t.warning,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4.4 Net profit banner
        StockMateNetBanner(
          profit: totalProfit,
          exp: totalExpenses,
          currency: currency,
          t: t,
        ),
        const SizedBox(height: 14),

        // 4.5 Tab switcher (Charts | Top Products | Export)
        _buildSubTabSwitcher(
          options: const [
            {"key": "summary", "label": "Charts"},
            {"key": "products", "label": "Top Products"},
            {"key": "export", "label": "Export"},
          ],
          selectedKey: tab,
          onSelect: (k) => setState(() => tab = k),
          t: t,
        ),
        const SizedBox(height: 14),

        // Sub-tab content
        if (tab == "summary") ...[
          // Revenue Bar Chart
          StockMateCard(
            t: t,
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
                ),
                const SizedBox(height: 4),
                Text(
                  '${period[0].toUpperCase()}${period.substring(1)} breakdown',
                  style: TextStyle(fontSize: 11, color: t.textSec, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                StockMateBarChart(
                  data: curSales,
                  labels: curLabels,
                  colors: t.chartBar,
                  height: 100,
                  t: t,
                ),
              ],
            ),
          ),

          // Profit Bar Chart
          StockMateCard(
            t: t,
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
                ),
                const SizedBox(height: 4),
                Text(
                  '${period[0].toUpperCase()}${period.substring(1)} breakdown',
                  style: TextStyle(fontSize: 11, color: t.textSec, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                StockMateBarChart(
                  data: curProfit,
                  labels: curLabels,
                  colors: [t.success],
                  height: 100,
                  t: t,
                ),
              ],
            ),
          ),

          // Category Revenue Split
          _buildCategoryDonutCard(t),
        ] else if (tab == "products") ...[
          // 4.7 Top Products Tab
          _buildTopProductsCard(t, currency),
        ] else if (tab == "export") ...[
          // 4.8 Export Tab
          _buildExportCard(t, exportService),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Yearly Report (Overview / Quarterly / Monthly / P&L)
  // ---------------------------------------------------------------------------
  Widget _buildYearlyReport(ThemeTokens t, String currency, DatabaseService db) {
    // 5.1 Year Badge Row
    const yoyRevenue = 24.7;
    const yoyProfit = 28.5;

    // 5.2 Annual Constants
    const annualRevenue = 38900.0;
    const grossProfit = 17220.0;
    final totalExpenses = db.totalExpenses > 0 ? db.totalExpenses : 9900.0;
    final netProfit = grossProfit - totalExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year Badge Row (Section 5.1)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: t.textSec, fontFamily: 'SF Pro Display'),
                children: [
                  const TextSpan(text: 'Full Year · '),
                  TextSpan(
                    text: '2025',
                    style: TextStyle(fontWeight: FontWeight.w700, color: t.accent),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _buildYoYChip('Rev +$yoyRevenue% YoY', true, t),
                const SizedBox(width: 6),
                _buildYoYChip('Profit +$yoyProfit% YoY', true, t),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 5.2 Annual KPI Tiles (4 tiles)
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                label: 'Annual Revenue',
                value: fmt(annualRevenue, currency),
                valueColor: t.accent,
                t: t,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiTile(
                label: 'Gross Profit',
                value: fmt(grossProfit, currency),
                valueColor: t.success,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildKpiTile(
                label: 'Total Expenses',
                value: fmt(totalExpenses, currency),
                valueColor: t.danger,
                t: t,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiTile(
                label: 'Net Profit',
                value: fmt(netProfit, currency),
                valueColor: t.purple,
                t: t,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Net Profit Banner
        StockMateNetBanner(
          profit: grossProfit,
          exp: totalExpenses,
          label: '2025 NET PROFIT',
          currency: currency,
          t: t,
        ),
        const SizedBox(height: 14),

        // 5.3 Yearly Sub-tab Control (Overview | Quarterly | Monthly | P&L)
        _buildSubTabSwitcher(
          options: const [
            {"key": "overview", "label": "Overview"},
            {"key": "quarterly", "label": "Quarterly"},
            {"key": "monthly", "label": "Monthly"},
            {"key": "pl", "label": "P&L"},
          ],
          selectedKey: yearTab,
          onSelect: (k) => setState(() => yearTab = k),
          t: t,
          fontSize: 10,
        ),
        const SizedBox(height: 14),

        // Yearly Sub-tab Content
        if (yearTab == "overview") ...[
          _buildYearlyOverviewTab(t),
        ] else if (yearTab == "quarterly") ...[
          _buildYearlyQuarterlyTab(t, currency),
        ] else if (yearTab == "monthly") ...[
          _buildYearlyMonthlyTab(t, currency),
        ] else if (yearTab == "pl") ...[
          _buildYearlyPlTab(t, currency, db),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5.4 Yearly: Overview Sub-tab
  // ---------------------------------------------------------------------------
  Widget _buildYearlyOverviewTab(ThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue — Year over Year',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 2),
              Text(
                '2022 · 2023 · 2024 · 2025',
                style: TextStyle(fontSize: 11, color: t.textSec),
              ),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: const [18400, 24600, 31200, 38900],
                labels: const ["2022", "2023", "2024", "2025"],
                colors: t.chartBar,
                height: 110,
                t: t,
              ),
            ],
          ),
        ),
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gross Profit — Year over Year',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 2),
              Text(
                '2022 · 2023 · 2024 · 2025',
                style: TextStyle(fontSize: 11, color: t.textSec),
              ),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: const [7200, 10100, 13400, 17220],
                labels: const ["2022", "2023", "2024", "2025"],
                colors: [
                  t.success,
                  t.withHexSuffix(t.success, "cc"),
                  t.withHexSuffix(t.success, "99"),
                  t.success,
                ],
                height: 100,
                t: t,
              ),
            ],
          ),
        ),
        _buildCategoryDonutCard(t),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5.5 Yearly: Quarterly Sub-tab
  // ---------------------------------------------------------------------------
  Widget _buildYearlyQuarterlyTab(ThemeTokens t, String currency) {
    const quarters = [
      {"name": "Q1", "revenue": 8200, "profit": 3540, "expenses": 2100, "net": 1440},
      {"name": "Q2", "revenue": 9800, "profit": 4230, "expenses": 2400, "net": 1830},
      {"name": "Q3", "revenue": 11400, "profit": 4920, "expenses": 2800, "net": 2120},
      {"name": "Q4", "revenue": 9500, "profit": 4530, "expenses": 2600, "net": 1930},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quarterly Revenue vs Profit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 12),
              Row(
                children: quarters.map((q) {
                  final isNetPos = (q['net'] as int) >= 0;
                  final netColor = isNetPos ? t.success : t.danger;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            q['name'] as String,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.accent),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fmt(q['revenue'] as num, currency),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${fmt(q['profit'] as num, currency)}',
                            style: TextStyle(fontSize: 10, color: t.success, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '−${fmt(q['expenses'] as num, currency)}',
                            style: TextStyle(fontSize: 10, color: t.danger, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            height: 3,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: netColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Net ${fmt(q['net'] as num, currency)}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: netColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quarterly Revenue Chart',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: const [8200, 9800, 11400, 9500],
                labels: const ["Q1", "Q2", "Q3", "Q4"],
                colors: t.chartBar,
                height: 100,
                t: t,
              ),
            ],
          ),
        ),
        StockMateCard(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Profit by Quarter',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: const [1440, 1830, 2120, 1930],
                labels: const ["Q1", "Q2", "Q3", "Q4"],
                colors: [
                  t.purple,
                  t.withHexSuffix(t.purple, "cc"),
                  t.withHexSuffix(t.purple, "99"),
                  t.purple,
                ],
                height: 90,
                t: t,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5.6 Yearly: Monthly Sub-tab
  // ---------------------------------------------------------------------------
  Widget _buildYearlyMonthlyTab(ThemeTokens t, String currency) {
    const List<num> monthlyRevenue2025 = [2100, 2450, 2900, 3200, 3600, 3800, 3400, 3700, 4100, 4400, 4200, 4700];
    const List<num> monthlyProfit2025 = [910, 1060, 1250, 1380, 1560, 1640, 1470, 1600, 1770, 1900, 1810, 2030];
    const List<num> monthlyNet2025 = [390, 520, 690, 800, 960, 1040, 890, 980, 1130, 1240, 1160, 1360];
    const monthLetters = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Revenue — 2025',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 2),
              Text('All 12 months', style: TextStyle(fontSize: 11, color: t.textSec)),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: monthlyRevenue2025,
                labels: monthLetters,
                colors: t.chartBar,
                height: 100,
                t: t,
              ),
            ],
          ),
        ),
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Gross Profit — 2025',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 2),
              Text('All 12 months', style: TextStyle(fontSize: 11, color: t.textSec)),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: monthlyProfit2025,
                labels: monthLetters,
                colors: [t.success],
                height: 90,
                t: t,
              ),
            ],
          ),
        ),
        StockMateCard(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Net Profit — 2025',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 2),
              Text('After expenses deducted', style: TextStyle(fontSize: 11, color: t.textSec)),
              const SizedBox(height: 12),
              StockMateBarChart(
                data: monthlyNet2025,
                labels: monthLetters,
                colors: [t.purple],
                height: 90,
                t: t,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Best month: ', style: TextStyle(fontSize: 11, color: t.textSec)),
                  Text(
                    'December — ${fmt(1360, currency)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.success),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5.7 Yearly: P&L Sub-tab (Statement & Key Ratios)
  // ---------------------------------------------------------------------------
  Widget _buildYearlyPlTab(ThemeTokens t, String currency, DatabaseService db) {
    // Live expenses grouping with fallback
    final liveExpenses = db.expenses;
    final Map<String, double> expensesByCategory = {};
    if (liveExpenses.isNotEmpty) {
      for (var e in liveExpenses) {
        expensesByCategory[e.category] = (expensesByCategory[e.category] ?? 0) + e.amount;
      }
    } else {
      expensesByCategory.addAll({
        "Rent": 9600,
        "Salaries": 28800,
        "Utilities": 1440,
        "Marketing": 2400,
        "Other": 1860,
      });
    }
    final totalOpEx = liveExpenses.isNotEmpty ? db.totalExpenses : 9900.0;

    // Live loans
    final liveLoans = db.loans;
    final totalLoanDebt = liveLoans.fold(0.0, (sum, l) => sum + db.getOutstandingLoanPrincipal(l.id));

    // Live receivables (money lent)
    final liveReceivables = db.receivables;
    final totalMoneyLent = liveReceivables.fold(0.0, (sum, r) => sum + db.getOutstandingReceivablePrincipal(r.id));

    // Live investors
    final liveInvestors = db.investors.where((i) => i.profitSharePercentage > 0 || i.ownershipPercentage > 0).toList();
    final double netProfitYear = 7320.0;
    double totalToInvestors = 0.0;
    if (liveInvestors.isNotEmpty) {
      totalToInvestors = liveInvestors.fold(0.0, (sum, i) {
        final share = i.profitSharePercentage > 0 ? i.profitSharePercentage : i.ownershipPercentage;
        return sum + (netProfitYear * (share / 100));
      });
    } else {
      // Prototype demo investors: 25% and 15%
      totalToInvestors = (netProfitYear * 0.25) + (netProfitYear * 0.15); // 1830 + 1098 = 2928
    }
    final ownerProfit = netProfitYear - totalToInvestors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // P&L Statement Card
        StockMateCard(
          t: t,
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Text(
                '📋 Profit & Loss Statement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Financial Year 2025',
                style: TextStyle(fontSize: 12, color: t.textMuted),
              ),
              const SizedBox(height: 14),

              // Block 1: Revenue (accentLight / accent)
              _buildPlBlock(
                title: 'REVENUE',
                mainColor: t.accent,
                bgColor: t.accentLight,
                t: t,
                lines: [
                  {"label": "Product Sales", "value": fmt(36400, currency)},
                  {"label": "Service Revenue", "value": fmt(1800, currency)},
                  {"label": "Other Income", "value": fmt(700, currency)},
                ],
                totalLabel: 'Total Revenue',
                totalValue: fmt(38900, currency),
              ),

              // Block 2: COGS (warningLight / warning)
              _buildPlBlock(
                title: 'COST OF GOODS SOLD',
                mainColor: t.warning,
                bgColor: t.warningLight,
                t: t,
                lines: [
                  {"label": "Inventory Purchases", "value": fmt(16400, currency)},
                  {"label": "Shipping / Freight", "value": fmt(2100, currency)},
                  {"label": "Packaging", "value": fmt(1180, currency)},
                ],
                totalLabel: 'Total COGS',
                totalValue: fmt(19680, currency),
              ),

              // Block 3: Gross Profit Row (successLight / success)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: t.successLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gross Profit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.success),
                    ),
                    Text(
                      fmt(17220, currency),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.success),
                    ),
                  ],
                ),
              ),

              // Block 4: Operating Expenses (dangerLight / danger)
              _buildPlBlock(
                title: 'OPERATING EXPENSES',
                mainColor: t.danger,
                bgColor: t.dangerLight,
                t: t,
                lines: expensesByCategory.entries.map((entry) {
                  return {
                    "label": entry.key,
                    "value": fmt(entry.value, currency),
                  };
                }).toList(),
                totalLabel: 'Total Expenses',
                totalValue: fmt(totalOpEx, currency),
              ),

              // Block 5: 🏦 Loan Liabilities (warningLight / warning)
              _buildPlLoansBlock(t, currency, liveLoans, totalLoanDebt),

              // Block 6: 🤝 Money Lent Out (accentLight / accent)
              _buildPlMoneyLentBlock(t, currency, liveReceivables, totalMoneyLent),

              // Block 7: NET PROFIT Box (gradient purple+22 to accent+22, border purple+44)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      t.withHexSuffix(t.purple, "22"),
                      t.withHexSuffix(t.accent, "22"),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.withHexSuffix(t.purple, "44"),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET PROFIT',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.purple),
                        ),
                        Text(
                          'After all deductions',
                          style: TextStyle(fontSize: 11, color: t.purple.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    Text(
                      fmt(netProfitYear, currency),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: t.purple),
                    ),
                  ],
                ),
              ),

              // Block 8: 👥 Investor Profit Distribution (purpleLight / purple)
              _buildPlInvestorBlock(t, currency, liveInvestors, totalToInvestors, ownerProfit),
            ],
          ),
        ),

        // Key Ratios Card (Section 5.7)
        StockMateCard(
          t: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Key Ratios',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
              ),
              const SizedBox(height: 8),
              _buildRatioRow('Gross Margin', '44.3%', t.success, t),
              _buildRatioRow('Net Margin', '18.8%', t.purple, t),
              _buildRatioRow('Expense Ratio', '25.4%', t.danger, t),
              _buildRatioRow('Revenue Growth YoY', '+24.7%', t.accent, t),
              _buildRatioRow('Profit Growth YoY', '+28.5%', t.success, t),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets for P&L Blocks ---
  Widget _buildPlBlock({
    required String title,
    required Color mainColor,
    required Color bgColor,
    required ThemeTokens t,
    required List<Map<String, String>> lines,
    required String totalLabel,
    required String totalValue,
  }) {
    final dividerColor = t.withHexSuffix(mainColor, "22");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mainColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ...lines.map((l) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l['label']!, style: TextStyle(fontSize: 13, color: t.text)),
                  Text(l['value']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mainColor)),
                Text(totalValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: mainColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlLoansBlock(ThemeTokens t, String currency, List liveLoans, double totalLoanDebt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.warningLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏦 LOAN LIABILITIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.warning,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          if (liveLoans.isNotEmpty)
            ...liveLoans.map((l) {
              final isCleared = l.status == 'cleared';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.withHexSuffix(t.warning, "22"), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                          children: [
                            TextSpan(text: l.lenderName),
                            TextSpan(
                              text: isCleared ? ' (Cleared)' : ' (Active)',
                              style: TextStyle(fontSize: 10, color: t.textSec),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCleared ? '✅ Cleared' : '${fmt(l.principalAmount, currency)} left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCleared ? t.success : t.danger,
                      ),
                    ),
                  ],
                ),
              );
            })
          else ...[
            _buildSampleLoanRow("BRAC Bank Commercial", "(Active)", "${fmt(100000, currency)} left", false, t),
            _buildSampleLoanRow("City Bank SME Facility", "(Active)", "${fmt(5000, currency)} left", false, t),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Outstanding',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.warning),
                ),
                Text(
                  fmt(totalLoanDebt > 0 ? totalLoanDebt : 105000, currency),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleLoanRow(String lender, String status, String rightText, bool isCleared, ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.withHexSuffix(t.warning, "22"), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                children: [
                  TextSpan(text: lender),
                  TextSpan(text: ' $status', style: TextStyle(fontSize: 10, color: t.textSec)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rightText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isCleared ? t.success : t.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlMoneyLentBlock(ThemeTokens t, String currency, List liveReceivables, double totalMoneyLent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.accentLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🤝 MONEY LENT OUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.accent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          if (liveReceivables.isNotEmpty)
            ...liveReceivables.map((r) {
              final isReturned = r.status == 'returned';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.withHexSuffix(t.accent, "22"), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                          children: [
                            TextSpan(text: r.debtorName),
                            TextSpan(
                              text: ' (${r.notes.isNotEmpty ? r.notes : "—"})',
                              style: TextStyle(fontSize: 10, color: t.textSec),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReturned ? '✅ Returned' : '${fmt(r.principalAmount, currency)} pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isReturned ? t.success : t.danger,
                      ),
                    ),
                  ],
                ),
              );
            })
          else ...[
            _buildSampleLentRow("Rahim Brothers Ltd", "(Wholesale consign)", "${fmt(5000, currency)} pending", false, t),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Still Pending',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.accent),
                ),
                Text(
                  fmt(totalMoneyLent > 0 ? totalMoneyLent : 5000, currency),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleLentRow(String debtor, String reason, String rightText, bool isReturned, ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.withHexSuffix(t.accent, "22"), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                children: [
                  TextSpan(text: debtor),
                  TextSpan(text: ' $reason', style: TextStyle(fontSize: 10, color: t.textSec)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rightText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isReturned ? t.success : t.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlInvestorBlock(
    ThemeTokens t,
    String currency,
    List liveInvestors,
    double totalToInvestors,
    double ownerProfit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.purpleLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👥 INVESTOR PROFIT DISTRIBUTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.purple,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (liveInvestors.isNotEmpty)
            ...liveInvestors.map((i) {
              final share = i.profitSharePercentage > 0 ? i.profitSharePercentage : i.ownershipPercentage;
              final shareAmt = 7320.0 * (share / 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                          children: [
                            TextSpan(text: i.name),
                            TextSpan(
                              text: ' ($share% · invested ${fmt(i.initialInvestedAmount, currency)})',
                              style: TextStyle(fontSize: 10, color: t.textSec),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fmt(shareAmt, currency),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.purple),
                    ),
                  ],
                ),
              );
            })
          else ...[
            _buildSampleInvestorRow("Sarah Jenkins", "25%", 50000, 1830, currency, t),
            _buildSampleInvestorRow("Michael Chen", "15%", 30000, 1098, currency, t),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total to Investors', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.purple)),
                Text(fmt(totalToInvestors, currency), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.purple)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 1,
            color: t.withHexSuffix(t.purple, "33"),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🏆 Owner’s Profit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.success)),
              Text(fmt(ownerProfit, currency), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleInvestorRow(String name, String share, num invested, num shareAmt, String currency, ThemeTokens t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: t.text, fontFamily: 'SF Pro Display'),
                children: [
                  TextSpan(text: name),
                  TextSpan(
                    text: ' ($share · invested ${fmt(invested, currency)})',
                    style: TextStyle(fontSize: 10, color: t.textSec),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fmt(shareAmt, currency),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioRow(String label, String value, Color color, ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: t.textSec, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Products Tab Component (Section 4.7)
  // ---------------------------------------------------------------------------
  Widget _buildTopProductsCard(ThemeTokens t, String currency) {
    return StockMateCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Products by Revenue',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topProducts.length,
            separatorBuilder: (context, index) => Divider(color: t.border, height: 1),
            itemBuilder: (context, i) {
              final p = topProducts[i];
              final barColor = t.chartBar[i % t.chartBar.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // Rank Badge: 28x28, radius 8, chartBar[i] with alpha 33
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: t.withHexSuffix(barColor, "33"),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: barColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & sub-line
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p['sold']} sold · Profit: ${fmt(p['profit'] as num, currency)}',
                            style: TextStyle(fontSize: 11, color: t.textSec),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Revenue & Margin label
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt(p['revenue'] as num, currency),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'High margin',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: t.success),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export Tab Component (Section 4.8)
  // ---------------------------------------------------------------------------
  Widget _buildExportCard(ThemeTokens t, ReportExportService exportService) {
    return StockMateCard(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Report',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Download $period report as a file',
            style: TextStyle(fontSize: 11, color: t.textSec),
          ),
          const SizedBox(height: 14),
          _buildExportButton(
            title: 'Export as PDF',
            subtitle: 'Formatted printable report',
            icon: Icons.picture_as_pdf_rounded,
            iconColor: t.danger,
            t: t,
            onTap: () async {
              await exportService.exportProfitLossReportPdf();
              Get.snackbar('Export Started', 'Generating PDF report...');
            },
          ),
          _buildExportButton(
            title: 'Export as XLSX',
            subtitle: 'Excel spreadsheet with charts',
            icon: Icons.table_view_rounded,
            iconColor: t.success,
            t: t,
            onTap: () async {
              await exportService.exportSalesToCsv();
              Get.snackbar('Export Ready', 'Exporting formatted spreadsheet...');
            },
          ),
          _buildExportButton(
            title: 'Export as CSV',
            subtitle: 'Raw data for analysis',
            icon: Icons.grid_on_rounded,
            iconColor: t.accent,
            t: t,
            onTap: () async {
              await exportService.exportInventoryToCsv();
              Get.snackbar('Export Ready', 'Exporting CSV data...');
            },
          ),
          _buildExportButton(
            title: 'Share via Drive',
            subtitle: 'Upload to Google Drive',
            icon: Icons.cloud_upload_rounded,
            iconColor: t.purple,
            t: t,
            onTap: () {
              Get.snackbar('Google Drive', 'Preparing cloud storage link...');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required ThemeTokens t,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: t.textSec)),
              ],
            ),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Donut Card (Section 4.6)
  // ---------------------------------------------------------------------------
  Widget _buildCategoryDonutCard(ThemeTokens t) {
    return StockMateCard(
      t: t,
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Revenue Split',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StockMateDonutChart(
                data: categoryData,
                colors: t.chartBar,
                size: 110,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: List.generate(categoryData.length, (i) {
                    final d = categoryData[i];
                    final val = d['value'] as int;
                    final barColor = t.chartBar[i % t.chartBar.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(d['name'] as String, style: TextStyle(fontSize: 11, color: t.textSec)),
                              Text('$val%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.text)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 5,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: t.surfaceAlt,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (val / 100.0).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KPI Tile Helper (Section 4.3)
  // ---------------------------------------------------------------------------
  Widget _buildKpiTile({
    required String label,
    required String value,
    required Color valueColor,
    required ThemeTokens t,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: t.textSec, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoYChip(String text, bool isPositive, ThemeTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? t.successLight : t.dangerLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPositive ? t.success : t.danger,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Sub-Tab Switcher (Segmented Control)
  // ---------------------------------------------------------------------------
  Widget _buildSubTabSwitcher({
    required List<Map<String, String>> options,
    required String selectedKey,
    required Function(String) onSelect,
    required ThemeTokens t,
    double fontSize = 11,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selectedKey == opt['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? t.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: t.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  opt['label']!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? t.text : t.textSec,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
