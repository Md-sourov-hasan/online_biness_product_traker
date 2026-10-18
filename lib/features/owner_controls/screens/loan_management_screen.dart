import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/loan_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class LoanManagementScreen extends StatelessWidget {
  const LoanManagementScreen({super.key});

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
                final loans = db.loans;
                final totalBorrowed = loans.fold(0.0, (sum, l) => sum + l.principalBorrowed);
                final totalOutstanding = loans.fold(0.0, (sum, l) => sum + db.getOutstandingLoanPrincipal(l.id));
                final totalInterestPaid = db.loanPayments.fold(0.0, (sum, p) => sum + p.interestPaid);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Metrics
                      _buildSummaryCard(
                        theme: theme,
                        totalBorrowed: totalBorrowed,
                        totalOutstanding: totalOutstanding,
                        totalInterestPaid: totalInterestPaid,
                      ),
                      20.verticalSpace,

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active & Past Loans (${loans.length})',
                            style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddLoanDialog(context, db, theme),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Loan'),
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

                      if (loans.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.h),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 48, color: theme.subtextColor),
                                12.verticalSpace,
                                Text('No loan records found.', style: TextStyle(color: theme.subtextColor)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loans.length,
                          separatorBuilder: (context, index) => 12.verticalSpace,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final rem = db.getOutstandingLoanPrincipal(loan.id);
                            return _buildLoanCard(context, db, theme, loan, rem);
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
                  'Borrowed Loans & Liabilities',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  'Owner Exclusive • Bank & P2P Business Financing',
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
    required double totalBorrowed,
    required double totalOutstanding,
    required double totalInterestPaid,
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
                    Text('Total Outstanding Debt', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                    4.verticalSpace,
                    Text('৳${totalOutstanding.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.redAccent)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: theme.inputBorderColor),
              Expanded(
                child: Column(
                  children: [
                    Text('Total Interest Paid', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                    4.verticalSpace,
                    Text('৳${totalInterestPaid.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: AppColors.secondary)),
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
              Text('Original Principal Borrowed:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              Text('৳${totalBorrowed.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Loan loan,
    double remainingPrincipal,
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
                    Text(loan.lenderName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                    Text('${loan.lenderType} • ${loan.purpose}', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: loan.status == 'paid' ? AppColors.success.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  loan.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: loan.status == 'paid' ? AppColors.success : Colors.orange,
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
                    Text('Remaining Principal Liability:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('৳${remainingPrincipal.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: remainingPrincipal > 0 ? Colors.redAccent : AppColors.success)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Interest Terms:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${loan.interestRate}% ${loan.interestRateUnit} (${loan.interestMethod})',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Principal Borrowed:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('৳${loan.principalBorrowed.toStringAsFixed(0)}', style: TextStyle(fontSize: 12.sp, color: theme.textColor)),
                  ],
                ),
              ],
            ),
          ),
          12.verticalSpace,
          if (remainingPrincipal > 0)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showRepaymentDialog(context, db, theme, loan, remainingPrincipal),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Pay Repayment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context, DatabaseService db, ThemeLanguageService theme) {
    final lenderCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final principalCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '12.0');
    String lenderType = 'Bank';
    String interestMethod = 'Simple';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('Record Borrowed Loan', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: lenderType,
                  decoration: const InputDecoration(labelText: 'Lender Category'),
                  items: const [
                    DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'Individual', child: Text('Individual')),
                    DropdownMenuItem(value: 'Business', child: Text('Business')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => lenderType = val ?? lenderType),
                ),
                8.verticalSpace,
                TextField(
                  controller: lenderCtrl,
                  decoration: const InputDecoration(labelText: 'Lender Name (e.g. City Bank)'),
                ),
                8.verticalSpace,
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose (e.g. Emergency Stock)'),
                ),
                8.verticalSpace,
                TextField(
                  controller: principalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Principal Borrowed (৳)'),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Interest Rate %'),
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: interestMethod,
                        decoration: const InputDecoration(labelText: 'Method'),
                        items: const [
                          DropdownMenuItem(value: 'Simple', child: Text('Simple')),
                          DropdownMenuItem(value: 'Reducing Balance', child: Text('Reducing')),
                          DropdownMenuItem(value: 'Flat', child: Text('Flat')),
                        ],
                        onChanged: (val) => setState(() => interestMethod = val ?? interestMethod),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final lender = lenderCtrl.text.trim();
                final principal = double.tryParse(principalCtrl.text.trim()) ?? 0.0;
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                if (lender.isEmpty || principal <= 0) return;

                db.addLoan(Loan(
                  id: const Uuid().v4(),
                  lenderType: lenderType,
                  lenderName: lender,
                  purpose: purposeCtrl.text.trim(),
                  principalBorrowed: principal,
                  interestRate: rate,
                  interestMethod: interestMethod,
                ));
                Navigator.pop(ctx);
                Get.snackbar('Loan Added', 'Borrowed loan liability created.', snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('Save Loan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepaymentDialog(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Loan loan,
    double remaining,
  ) {
    final principalPaidCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
    final interestPaidCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Loan Repayment (Spec Section 12.3)', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lender: ${loan.lenderName}', style: TextStyle(fontSize: 13.sp, color: theme.subtextColor)),
            4.verticalSpace,
            Text('Separates Principal (Liability) vs Interest (Expense)',
                style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
            12.verticalSpace,
            TextField(
              controller: principalPaidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Principal Repayment (৳) - Reduces Debt'),
            ),
            8.verticalSpace,
            TextField(
              controller: interestPaidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Interest Paid (৳) - Operating Expense'),
            ),
            8.verticalSpace,
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Payment Reference / Bank slip'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final pPaid = double.tryParse(principalPaidCtrl.text.trim()) ?? 0.0;
              final iPaid = double.tryParse(interestPaidCtrl.text.trim()) ?? 0.0;
              if (pPaid <= 0 && iPaid <= 0) return;

              db.recordLoanPayment(LoanPayment(
                id: const Uuid().v4(),
                loanId: loan.id,
                totalAmount: pPaid + iPaid,
                principalPaid: pPaid,
                interestPaid: iPaid,
                notes: notesCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              Get.snackbar('Repayment Recorded', 'Allocated: Principal ৳$pPaid, Interest ৳$iPaid',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Post Payment'),
          ),
        ],
      ),
    );
  }
}
