import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/common/widgets/stockmate_components.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final DatabaseService db = Get.find<DatabaseService>();

    return Obx(() {
      final t = themeService.t;
      final currency = themeService.currentCurrency.value;

      // Hybrid Data Resolution:
      // If live data exists, compute metrics; otherwise fall back to the exact specification sample data
      final liveSales = db.sales;
      final hasLiveSales = liveSales.isNotEmpty;

      // 1. Annual Revenue Series
      const List<num> specMonthlyData = [1200, 1850, 1420, 2100, 1780, 2340, 1950, 2680, 2210, 2900, 2450, 3100];
      final List<num> annualRevenueData = specMonthlyData;
      const List<String> monthLabels = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"];

      // 2. Best Seller & Best Margin
      String bestSellerName = "USB-C Cable";
      String bestSellerHighlight = "142 sold this month";
      if (hasLiveSales) {
        // Find best seller product
        final Map<String, int> unitsSold = {};
        for (var s in liveSales) {
          unitsSold[s.productName] = (unitsSold[s.productName] ?? 0) + s.quantity;
        }
        if (unitsSold.isNotEmpty) {
          final topEntry = unitsSold.entries.reduce((a, b) => a.value > b.value ? a : b);
          bestSellerName = topEntry.key;
          bestSellerHighlight = "${topEntry.value} sold this month";
        }
      }

      String bestMarginName = "Desk Lamp";
      String bestMarginHighlight = "64% profit margin";
      if (db.products.isNotEmpty) {
        final productsWithMargin = db.products.where((p) => p.sellingPrice > 0).toList();
        if (productsWithMargin.isNotEmpty) {
          double getMargin(p) => ((p.sellingPrice - p.pricePerPiece) / p.sellingPrice) * 100;
          productsWithMargin.sort((a, b) => getMargin(b).compareTo(getMargin(a)));
          final topMarginProduct = productsWithMargin.first;
          bestMarginName = topMarginProduct.displayName;
          bestMarginHighlight = "${getMargin(topMarginProduct).toStringAsFixed(0)}% profit margin";
        }
      }

      // 3. Category Data
      final List<Map<String, dynamic>> categoryData = [
        {"name": "Electronics", "value": 42},
        {"name": "Stationery", "value": 24},
        {"name": "Furniture", "value": 15},
        {"name": "Health", "value": 10},
        {"name": "Kitchen", "value": 9},
      ];

      // 4. Key Metrics
      double aovVal = 37.50;
      if (hasLiveSales) {
        aovVal = db.totalRevenue / (liveSales.isEmpty ? 1 : liveSales.length);
      }
      final double grossMarginVal = (hasLiveSales && db.totalRevenue > 0)
          ? ((db.totalGrossProfit / db.totalRevenue) * 100)
          : 48.6;

      final keyMetrics = [
        {
          "label": "Average Order Value",
          "value": fmt(aovVal, currency),
          "trend": "+5.2%",
          "up": true,
        },
        {
          "label": "Inventory Turnover",
          "value": "4.2x/month",
          "trend": "+0.3x",
          "up": true,
        },
        {
          "label": "Gross Profit Margin",
          "value": "${grossMarginVal.toStringAsFixed(1)}%",
          "trend": "-1.2%",
          "up": false,
        },
        {
          "label": "Stock-out Rate",
          "value": "3.1%",
          "trend": "-0.8%",
          "up": true,
        },
      ];

      return Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Back Navigation & Screen Title
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
                        'Analytics',
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

                // Card 1 – Annual Revenue (BarChart)
                StockMateCard(
                  t: t,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Annual Revenue',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jan–Dec 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: t.textSec,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StockMateBarChart(
                        data: annualRevenueData,
                        labels: monthLabels,
                        colors: t.chartBar,
                        height: 110,
                        t: t,
                      ),
                    ],
                  ),
                ),

                // Row of two cards – Best Seller | Best Margin (Sparklines)
                Row(
                  children: [
                    // Best Seller Card
                    Expanded(
                      child: StockMateCard(
                        t: t,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Seller',
                              style: TextStyle(fontSize: 12, color: t.textSec, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bestSellerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bestSellerHighlight,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.success),
                            ),
                            const SizedBox(height: 8),
                            StockMateSparkline(
                              data: const [20, 35, 28, 45, 38, 52, 48, 61, 55, 72, 68, 80],
                              color: t.success,
                              width: 100,
                              height: 35,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Best Margin Card
                    Expanded(
                      child: StockMateCard(
                        t: t,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Margin',
                              style: TextStyle(fontSize: 12, color: t.textSec, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bestMarginName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bestMarginHighlight,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.accent),
                            ),
                            const SizedBox(height: 8),
                            StockMateSparkline(
                              data: const [60, 62, 61, 63, 64, 63, 65, 64, 66, 65, 64, 64],
                              color: t.accent,
                              width: 100,
                              height: 35,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card 3 – Category Performance (Donut + Legend Bars)
                StockMateCard(
                  t: t,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Performance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StockMateDonutChart(
                            data: categoryData,
                            colors: t.chartBar,
                            size: 120,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: List.generate(categoryData.length, (i) {
                                final d = categoryData[i];
                                final val = d['value'] as int;
                                final color = t.chartBar[i % t.chartBar.length];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            d['name'] as String,
                                            style: TextStyle(fontSize: 11, color: t.textSec, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            '$val%',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.text),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        height: 6,
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
                                              color: color,
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
                ),

                // Card 4 – Key Metrics (Four-row list)
                StockMateCard(
                  t: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Metrics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...keyMetrics.map((m) {
                        final isUp = m['up'] as bool;
                        final trendColor = isUp ? t.success : t.danger;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: t.border, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: t.textSec,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    m['value'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m['trend'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: trendColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
