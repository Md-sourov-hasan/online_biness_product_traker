import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/investor_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class InvestorManagementScreen extends StatelessWidget {
  const InvestorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = Get.find<DatabaseService>();
    final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, theme),
            Expanded(
              child: Obx(() {
                final investors = db.investors;
                final totalInvested = investors.fold(0.0, (sum, i) => sum + i.initialInvestedAmount);
                final totalWithdrawn = db.investorTransactions
                    .where((t) => t.type == 'withdrawal')
                    .fold(0.0, (sum, t) => sum + t.amount);
                final netActiveCapital = totalInvested - totalWithdrawn;
                final distributable = db.distributableProfit;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Metrics
                      _buildSummaryCards(
                        theme: theme,
                        totalInvested: totalInvested,
                        netActiveCapital: netActiveCapital,
                        distributableProfit: distributable,
                      ),
                      20.verticalSpace,

                      // Section Title & Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registered Investors (${investors.length})',
                            style: getTextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddInvestorDialog(context, db, theme),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Investor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                      12.verticalSpace,

                      if (investors.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.h),
                            child: Column(
                              children: [
                                Icon(Icons.handshake_outlined, size: 48, color: theme.subtextColor),
                                12.verticalSpace,
                                Text('No investors recorded yet.', style: TextStyle(color: theme.subtextColor)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: investors.length,
                          separatorBuilder: (context, index) => 12.verticalSpace,
                          itemBuilder: (context, index) {
                            final inv = investors[index];
                            final activeCap = db.getNetActiveCapitalForInvestor(inv.id);
                            final profitDue = inv.calculateProfitDistribution(distributable);
                            return _buildInvestorCard(context, db, theme, inv, activeCap, profitDue);
                          },
                        ),
                      40.verticalSpace,
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeLanguageService theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.inputBorderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor, size: 20),
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investor Management',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  'Owner Exclusive • Capital, Equity & Profit Distributions',
                  style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required ThemeLanguageService theme,
    required double totalInvested,
    required double netActiveCapital,
    required double distributableProfit,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.inputBorderColor, width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Net Active Capital',
                  value: '৳${netActiveCapital.toStringAsFixed(0)}',
                  color: AppColors.primary,
                  theme: theme,
                ),
              ),
              Container(width: 1, height: 40, color: theme.inputBorderColor),
              Expanded(
                child: _buildMetricTile(
                  label: 'Distributable Profit',
                  value: '৳${distributableProfit.toStringAsFixed(0)}',
                  color: AppColors.success,
                  theme: theme,
                ),
              ),
            ],
          ),
          12.verticalSpace,
          const Divider(height: 1),
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Contributed Capital:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              Text('৳${totalInvested.toStringAsFixed(0)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required ThemeLanguageService theme,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
        4.verticalSpace,
        Text(value, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildInvestorCard(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Investor inv,
    double activeCap,
    double profitDue,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.inputBorderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                    Text(inv.investmentType, style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: inv.status == 'active' ? AppColors.success.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  inv.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: inv.status == 'active' ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Capital:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('৳${activeCap.toStringAsFixed(0)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Equity Ownership %:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${inv.ownershipPercentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profit-Share %:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${inv.profitSharePercentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ],
                ),
                if (inv.ownershipPercentage > 0) ...[
                  4.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Implied Post-Money Valuation:', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                      Text('৳${inv.postMoneyValuation.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
                    ],
                  ),
                ],
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Calculated Profit Due Now:', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.success)),
                    Text('৳${profitDue.toStringAsFixed(0)}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          ),
          10.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showTransactionDialog(context, db, theme, inv, 'withdrawal'),
                icon: const Icon(Icons.arrow_upward, size: 14),
                label: const Text('Withdraw'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                ),
              ),
              8.horizontalSpace,
              ElevatedButton.icon(
                onPressed: () => _showTransactionDialog(context, db, theme, inv, 'distribution'),
                icon: const Icon(Icons.payments_outlined, size: 14),
                label: const Text('Pay Profit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddInvestorDialog(BuildContext context, DatabaseService db, ThemeLanguageService theme) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final equityCtrl = TextEditingController(text: '45.0');
    final profitShareCtrl = TextEditingController(text: '45.0');
    String selectedType = 'Equity Partner';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('Register New Investor', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Investor Name (Required)'),
                ),
                8.verticalSpace,
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Investment Instrument Type'),
                  items: const [
                    DropdownMenuItem(value: 'Equity Partner', child: Text('Equity Partner')),
                    DropdownMenuItem(value: 'Profit-Share Partner', child: Text('Profit-Share Partner')),
                    DropdownMenuItem(value: 'Silent Partner', child: Text('Silent Partner')),
                    DropdownMenuItem(value: 'Fixed ROI', child: Text('Fixed ROI')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val ?? selectedType),
                ),
                8.verticalSpace,
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Invested Capital (৳)'),
                ),
                8.verticalSpace,
                TextField(
                  controller: equityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ownership Equity % (e.g. 45%)'),
                ),
                8.verticalSpace,
                TextField(
                  controller: profitShareCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Contractual Profit-Share % (e.g. 45%)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                final eq = double.tryParse(equityCtrl.text.trim()) ?? 0.0;
                final ps = double.tryParse(profitShareCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty || amount <= 0) return;

                db.addInvestor(Investor(
                  id: const Uuid().v4(),
                  name: name,
                  investmentType: selectedType,
                  initialInvestedAmount: amount,
                  ownershipPercentage: eq,
                  profitSharePercentage: ps,
                ));
                Navigator.pop(ctx);
                Get.snackbar('Investor Added', '$name recorded successfully.', snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('Save Investor'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDialog(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Investor inv,
    String type,
  ) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          type == 'withdrawal' ? 'Record Capital Withdrawal' : 'Record Profit Distribution',
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Investor: ${inv.name}', style: TextStyle(color: theme.subtextColor, fontSize: 13.sp)),
            12.verticalSpace,
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (৳)'),
            ),
            8.verticalSpace,
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Transaction Note / Reference'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt <= 0) return;

              db.addInvestorTransaction(InvestorTransaction(
                id: const Uuid().v4(),
                investorId: inv.id,
                type: type,
                amount: amt,
                notes: notesCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              Get.snackbar('Success', 'Transaction recorded.', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
