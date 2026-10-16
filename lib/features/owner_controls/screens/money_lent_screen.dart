import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/receivable_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class MoneyLentScreen extends StatelessWidget {
  const MoneyLentScreen({super.key});

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
                final recs = db.receivables;
                final totalLent = recs.fold(0.0, (sum, r) => sum + r.amountLent);
                final totalOutstanding = recs.fold(0.0, (sum, r) => sum + db.getOutstandingReceivablePrincipal(r.id));
                final totalReturned = totalLent - totalOutstanding;
                final overallReturnPct = totalLent > 0 ? (totalReturned / totalLent) * 100.0 : 0.0;
                final totalInterestIncome = db.receivablePayments.fold(0.0, (sum, p) => sum + p.interestReceived);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Metrics
                      _buildSummaryCard(
                        theme: theme,
                        totalLent: totalLent,
                        totalOutstanding: totalOutstanding,
                        overallReturnPct: overallReturnPct,
                        totalInterestIncome: totalInterestIncome,
                      ),
                      20.verticalSpace,

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lent Records (${recs.length})',
                            style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddReceivableDialog(context, db, theme),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Lend Money'),
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

                      if (recs.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.h),
                            child: Column(
                              children: [
                                Icon(Icons.outbox_rounded, size: 48, color: theme.subtextColor),
                                12.verticalSpace,
                                Text('No money-lent records found.', style: TextStyle(color: theme.subtextColor)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recs.length,
                          separatorBuilder: (context, index) => 12.verticalSpace,
                          itemBuilder: (context, index) {
                            final rec = recs[index];
                            final rem = db.getOutstandingReceivablePrincipal(rec.id);
                            final pct = db.getPrincipalReturnPercentage(rec.id);
                            return _buildReceivableCard(context, db, theme, rec, rem, pct);
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
                  'Money Lent / Receivables',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  'Owner Exclusive • Outstanding Receivables & Collections',
                  style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required ThemeLanguageService theme,
    required double totalLent,
    required double totalOutstanding,
    required double overallReturnPct,
    required double totalInterestIncome,
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
                child: Column(
                  children: [
                    Text('Outstanding Receivable', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                    4.verticalSpace,
                    Text('৳${totalOutstanding.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: theme.inputBorderColor),
              Expanded(
                child: Column(
                  children: [
                    Text('Principal Returned %', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                    4.verticalSpace,
                    Text('${overallReturnPct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ],
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
              Text('Original Principal Lent:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              Text('৳${totalLent.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
            ],
          ),
          4.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Interest Income Received:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              Text('৳${totalInterestIncome.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Receivable rec,
    double rem,
    double pct,
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
                    Text(rec.borrower, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                    Text(rec.purpose.isEmpty ? 'General Borrowing' : rec.purpose,
                        style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: rec.status == 'returned' ? AppColors.success.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  rec.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: rec.status == 'returned' ? AppColors.success : AppColors.primary,
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
                    Text('Outstanding Amount:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('৳${rem.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: rem > 0 ? AppColors.primary : AppColors.success)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Principal Return Rate:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Principal Lent:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('৳${rec.amountLent.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, color: theme.textColor)),
                  ],
                ),
                if (rec.interestRate > 0) ...[
                  4.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Agreed Interest:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                      Text('${rec.interestRate}% ${rec.interestRateUnit}',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          12.verticalSpace,
          if (rem > 0)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showCollectRepaymentDialog(context, db, theme, rec, rem),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Record Return'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddReceivableDialog(BuildContext context, DatabaseService db, ThemeLanguageService theme) {
    final borrowerCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Record Money Lent', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: borrowerCtrl,
                decoration: const InputDecoration(labelText: 'Borrower Name (Required)'),
              ),
              8.verticalSpace,
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Lent (৳)'),
              ),
              8.verticalSpace,
              TextField(
                controller: purposeCtrl,
                decoration: const InputDecoration(labelText: 'Purpose / Note'),
              ),
              8.verticalSpace,
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Interest Rate % (0 for none)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final b = borrowerCtrl.text.trim();
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              final r = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
              if (b.isEmpty || amt <= 0) return;

              db.addReceivable(Receivable(
                id: const Uuid().v4(),
                borrower: b,
                amountLent: amt,
                interestRate: r,
                purpose: purposeCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              Get.snackbar('Recorded', 'Money lent record created.', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  void _showCollectRepaymentDialog(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Receivable rec,
    double remaining,
  ) {
    final principalCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
    final interestCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Record Return (Spec Section 13.2)', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Borrower: ${rec.borrower}', style: TextStyle(fontSize: 13.sp, color: theme.subtextColor)),
            4.verticalSpace,
            Text('Principal returned reduces asset; Interest is recognized income.',
                style: TextStyle(fontSize: 11.sp, color: AppColors.success, fontWeight: FontWeight.w600)),
            12.verticalSpace,
            TextField(
              controller: principalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Principal Returned (৳)'),
            ),
            8.verticalSpace,
            TextField(
              controller: interestCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interest Income Received (৳)'),
            ),
            8.verticalSpace,
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Payment Note / Receipt No.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final pRet = double.tryParse(principalCtrl.text.trim()) ?? 0.0;
              final iRec = double.tryParse(interestCtrl.text.trim()) ?? 0.0;
              if (pRet <= 0 && iRec <= 0) return;

              db.recordReceivablePayment(ReceivablePayment(
                id: const Uuid().v4(),
                receivableId: rec.id,
                principalReturned: pRet,
                interestReceived: iRec,
                notes: notesCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              Get.snackbar('Payment Recorded', 'Received: Principal ৳$pRet, Interest ৳$iRec',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }
}
