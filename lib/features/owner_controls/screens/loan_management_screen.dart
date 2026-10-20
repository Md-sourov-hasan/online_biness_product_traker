import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/models/loan_model.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/common/widgets/stockmate_components.dart';

class LoanManagementScreen extends StatelessWidget {
  const LoanManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = Get.find<DatabaseService>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = themeService.t;
      final currency = themeService.currentCurrency.value;
      final loans = db.loans;

      final totalBorrowed = loans.fold(0.0, (sum, l) => sum + l.amount);
      final stillOwed = loans.fold(0.0, (sum, l) => sum + l.remaining);
      final paidBack = totalBorrowed - stillOwed;

      return CommonBackgroundScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 4.2 Header (← · 🏦 Loans · amber +)
              _buildHeader(context, t, db),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4.2 Three summary tiles (small 9 px uppercase labels)
                      _buildSummaryTiles(t, currency, totalBorrowed, stillOwed, paidBack),
                      16.verticalSpace,

                      // Empty state or Loan cards
                      if (loans.isEmpty)
                        _buildEmptyState(t)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loans.length,
                          separatorBuilder: (context, index) => 14.verticalSpace,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            return _buildLoanCard(context, t, currency, loan, db);
                          },
                        ),
                      40.verticalSpace,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- Header (← · 🏦 Loans · amber +) ---
  Widget _buildHeader(BuildContext context, ThemeTokens t, DatabaseService db) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: t.input,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: t.border),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: t.text, size: 18.w),
                ),
              ),
              12.horizontalSpace,
              Text(
                '🏦 Loans',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showAddLoanSheet(context, t, db),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: t.warningLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: t.warning.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.add_rounded, color: t.warning, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }

  // --- Three summary tiles (small 9 px uppercase labels) ---
  Widget _buildSummaryTiles(
    ThemeTokens t,
    String currency,
    double totalBorrowed,
    double stillOwed,
    double paidBack,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryTile('TOTAL BORROWED', fmt(totalBorrowed, currency), t.warning, t),
        ),
        8.horizontalSpace,
        Expanded(
          child: _buildSummaryTile('STILL OWED', fmt(stillOwed, currency), t.danger, t),
        ),
        8.horizontalSpace,
        Expanded(
          child: _buildSummaryTile('PAID BACK', fmt(paidBack, currency), t.success, t),
        ),
      ],
    );
  }

  Widget _buildSummaryTile(String label, String value, Color color, ThemeTokens t) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: t.textSec,
              letterSpacing: 0.5,
              fontFamily: 'SF Pro Display',
            ),
          ),
          4.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Empty state ---
  Widget _buildEmptyState(ThemeTokens t) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 50.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: t.warningLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_rounded, size: 40.w, color: t.warning),
            ),
            14.verticalSpace,
            Text(
              'No loans recorded',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            6.verticalSpace,
            Text(
              'Tap + to add a loan',
              style: TextStyle(fontSize: 12.sp, color: t.textSec),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4.3 Loan Card ---
  Widget _buildLoanCard(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Loan loan,
    DatabaseService db,
  ) {
    final state = loan.calculatedState;
    String stateLabel = 'Active';
    Color stateColor = t.warning;
    Color stateBg = t.warningLight;

    switch (state) {
      case LoanState.cleared:
        stateLabel = '✅ Cleared';
        stateColor = t.success;
        stateBg = t.successLight;
        break;
      case LoanState.overdue:
        stateLabel = '⚠️ Overdue';
        stateColor = t.danger;
        stateBg = t.dangerLight;
        break;
      case LoanState.dueSoon:
        stateLabel = '⏰ Due Soon';
        stateColor = t.warning;
        stateBg = t.warningLight;
        break;
      case LoanState.active:
        stateLabel = 'Active';
        stateColor = t.warning;
        stateBg = t.warningLight;
        break;
    }

    final paidAmt = loan.amount - loan.remaining;
    final paidPct = loan.paidPercentage;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Left & Top Right Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Left: ID chip (amber), state pill, type pill, lender name, phone, purpose
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        // ID chip (amber)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: t.warningLight,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            loan.id,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: t.warning,
                            ),
                          ),
                        ),
                        // State pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: stateBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            stateLabel,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: stateColor,
                            ),
                          ),
                        ),
                        // Type pill ("🏦 Bank" or "👤 Person")
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: t.input,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: t.border),
                          ),
                          child: Text(
                            loan.type == 'person' ? '👤 Person' : '🏦 Bank',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: t.textSec,
                            ),
                          ),
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    Text(
                      loan.lender,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (loan.phone.isNotEmpty) ...[
                      3.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Text(loan.phone, style: TextStyle(fontSize: 11.5.sp, color: t.textSec)),
                        ],
                      ),
                    ],
                    if (loan.purpose.isNotEmpty) ...[
                      3.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.description_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Expanded(
                            child: Text(
                              loan.purpose,
                              style: TextStyle(fontSize: 11.5.sp, color: t.textSec),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Top Right: Remaining amount (red, 16 px bold) with caption "remaining"
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(loan.remaining, currency),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: t.danger,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Text('remaining', style: TextStyle(fontSize: 10.sp, color: t.textSec)),
                  if (loan.interestRate > 0) ...[
                    2.verticalSpace,
                    Text(
                      '${loan.interestRate % 1 == 0 ? loan.interestRate.toInt() : loan.interestRate.toStringAsFixed(1)}% p.a.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: t.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          12.verticalSpace,

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: (paidPct / 100.0).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: t.input,
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.isCleared ? t.success : t.warning,
              ),
            ),
          ),
          4.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid ${paidPct.round()}% · ${fmt(paidAmt, currency)}',
                style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: t.textSec),
              ),
              Text(
                'Total ${fmt(loan.amount, currency)}',
                style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w600, color: t.textSec),
              ),
            ],
          ),

          10.verticalSpace,

          // Date tiles (row of 2 or 3 small tiles)
          Row(
            children: [
              Expanded(
                child: _buildSmallDateTile(
                  title: 'Start Date',
                  content: DateFormat('yyyy-MM-dd').format(loan.startDate),
                  textColor: t.text,
                  t: t,
                ),
              ),
              6.horizontalSpace,
              Expanded(
                child: _buildDueDateTile(loan, t),
              ),
              if (loan.monthlyPayment > 0) ...[
                6.horizontalSpace,
                Expanded(
                  child: _buildSmallDateTile(
                    title: 'Monthly EMI',
                    content: fmt(loan.monthlyPayment, currency),
                    textColor: t.warning,
                    t: t,
                  ),
                ),
              ],
            ],
          ),

          12.verticalSpace,

          // Action buttons (one row of 3, 2 when cleared)
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: '📋 Details',
                  color: t.accent,
                  bgColor: t.accentLight,
                  onTap: () => _showDetailsSheet(context, t, currency, loan),
                ),
              ),
              if (!loan.isCleared) ...[
                8.horizontalSpace,
                Expanded(
                  child: _buildButton(
                    label: '💳 Pay',
                    color: t.success,
                    bgColor: t.successLight,
                    onTap: () => _showPaymentSheet(context, t, currency, loan, db),
                  ),
                ),
              ],
              8.horizontalSpace,
              Expanded(
                child: _buildButton(
                  label: loan.isCleared ? '↩ Reopen' : '✅ Mark Cleared',
                  color: loan.isCleared ? t.accent : t.success,
                  bgColor: loan.isCleared ? t.accentLight : t.successLight,
                  onTap: () {
                    if (loan.isCleared) {
                      db.reopenLoan(loan.id);
                    } else {
                      db.markLoanCleared(loan.id);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDateTile({
    required String title,
    required String content,
    required Color textColor,
    required ThemeTokens t,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: t.input,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 8.5.sp, color: t.textSec)),
          2.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              content,
              style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateTile(Loan loan, ThemeTokens t) {
    if (loan.dueDate == null) {
      return _buildSmallDateTile(title: 'Due Date', content: '—', textColor: t.textSec, t: t);
    }

    final days = loan.daysUntilDue ?? 0;
    String suffix = '';
    Color textColor = t.text;
    Color bgColor = t.input;

    if (!loan.isCleared) {
      if (days < 0) {
        suffix = ' (${(-days)}d overdue)';
        textColor = t.danger;
        bgColor = t.dangerLight;
      } else if (days <= 30) {
        suffix = ' (${days}d left)';
        textColor = t.warning;
        bgColor = t.warningLight;
      }
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(loan.dueDate!) + suffix;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Due Date', style: TextStyle(fontSize: 8.5.sp, color: t.textSec)),
          2.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateStr,
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4.4 Add Loan Sheet
  // ===========================================================================
  void _showAddLoanSheet(BuildContext context, ThemeTokens t, DatabaseService db) {
    final loanType = 'bank'.obs; // 'bank' or 'person'
    final lenderCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final emiCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final startDateState = DateTime.now().obs;
    final dueDateState = Rx<DateTime?>(null);
    final interestHint = ''.obs;

    void updateHint() {
      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
      final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
      if (amt > 0 && rate > 0) {
        final yearly = amt * rate / 100.0;
        final currency = ThemeLanguageService.to.currentCurrency.value;
        interestHint.value = '💡 Estimated yearly interest: ${fmt(yearly, currency)}';
      } else {
        interestHint.value = '';
      }
    }

    amountCtrl.addListener(updateHint);
    rateCtrl.addListener(updateHint);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏦 Add Loan',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: t.text),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: t.textSec, size: 22.w),
                  ),
                ],
              ),
              16.verticalSpace,

              // 1. Loan Type toggle (Bank / Person)
              _buildFieldLabel('Loan Type', t),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => loanType.value = 'bank',
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: loanType.value == 'bank' ? t.warningLight : t.input,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: loanType.value == 'bank' ? t.warning : t.border,
                            width: loanType.value == 'bank' ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏦 Bank',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: loanType.value == 'bank' ? t.warning : t.textSec,
                          ),
                        ),
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: GestureDetector(
                      onTap: () => loanType.value = 'person',
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        decoration: BoxDecoration(
                          color: loanType.value == 'person' ? t.warningLight : t.input,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: loanType.value == 'person' ? t.warning : t.border,
                            width: loanType.value == 'person' ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '👤 Person',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: loanType.value == 'person' ? t.warning : t.textSec,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              12.verticalSpace,

              // 2. Bank Name / Lender Name
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(loanType.value == 'bank' ? 'Bank Name *' : 'Lender Name *', t),
                  _buildTextInput(
                    lenderCtrl,
                    loanType.value == 'bank' ? 'e.g. Dutch-Bangla Bank' : 'e.g. Rahim Mia',
                    t,
                  ),
                ],
              )),
              12.verticalSpace,

              // 3. Phone Number (optional)
              _buildFieldLabel('Phone Number (optional)', t),
              _buildTextInput(phoneCtrl, 'e.g. 01711-123456', t, keyboardType: TextInputType.phone),
              12.verticalSpace,

              // 4. Loan Amount (number, "0", required)
              _buildFieldLabel('Loan Amount *', t),
              _buildTextInput(amountCtrl, '0', t, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              12.verticalSpace,

              // 5. Interest Rate % per year (0 if none)
              _buildFieldLabel('Interest Rate % per year (0 if none)', t),
              _buildTextInput(rateCtrl, 'e.g. 12', t, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              12.verticalSpace,

              // 6. Monthly Installment
              _buildFieldLabel('Monthly Installment', t),
              _buildTextInput(emiCtrl, '0 if no fixed EMI', t, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              12.verticalSpace,

              // 7. Purpose / Reason
              _buildFieldLabel('Purpose / Reason', t),
              _buildTextInput(purposeCtrl, 'e.g. Stock purchase, expansion', t),
              12.verticalSpace,

              // 8. Start Date (today)
              _buildFieldLabel('Start Date', t),
              Obx(() => GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDateState.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) startDateState.value = picked;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: t.input,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(startDateState.value),
                        style: TextStyle(fontSize: 13.sp, color: t.text, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                    ],
                  ),
                ),
              )),
              12.verticalSpace,

              // 9. Due / End Date (empty; amber 2 px border)
              _buildFieldLabel('Due / End Date', t),
              Obx(() => GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDateState.value ?? DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) dueDateState.value = picked;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: t.input,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: t.warning, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dueDateState.value != null
                            ? DateFormat('yyyy-MM-dd').format(dueDateState.value!)
                            : 'Select Due Date (Optional)',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: dueDateState.value != null ? t.text : t.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.calendar_month_rounded, size: 16.w, color: t.warning),
                    ],
                  ),
                ),
              )),
              12.verticalSpace,

              // 10. Note (optional)
              _buildFieldLabel('Note (optional)', t),
              _buildTextInput(noteCtrl, 'Any extra details...', t),
              14.verticalSpace,

              // Live hint
              Obx(() {
                if (interestHint.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: t.warningLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: t.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    interestHint.value,
                    style: TextStyle(fontSize: 11.5.sp, color: t.warning, fontWeight: FontWeight.w600),
                  ),
                );
              }),

              // Button: Add Loan (amber)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final lender = lenderCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (lender.isEmpty) {
                      Get.snackbar('Required', 'Please enter lender/bank name.', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (amt <= 0) {
                      Get.snackbar('Required', 'Please enter a valid loan amount.', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                    final emi = double.tryParse(emiCtrl.text.trim()) ?? 0.0;
                    final seq = db.loans.length + 1;
                    final id = 'LN-${seq.toString().padLeft(3, '0')}';

                    final newLoan = Loan(
                      id: id,
                      lender: lender,
                      type: loanType.value,
                      phone: phoneCtrl.text.trim(),
                      amount: amt,
                      remaining: amt,
                      interestRate: rate,
                      startDate: startDateState.value,
                      dueDate: dueDateState.value,
                      monthlyPayment: emi,
                      purpose: purposeCtrl.text.trim(),
                      note: noteCtrl.text.trim(),
                      status: 'active',
                    );

                    db.addLoan(newLoan);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Loan for $lender recorded successfully.'),
                        backgroundColor: t.warning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.warning,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'Add Loan',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4.5 Details Sheet
  // ===========================================================================
  void _showDetailsSheet(BuildContext context, ThemeTokens t, String currency, Loan loan) {
    final paidAmt = loan.amount - loan.remaining;
    final isDuePassed = loan.dueDate != null &&
        loan.dueDate!.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.lender,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: t.text),
                      ),
                      Text(
                        '${loan.id} · ${loan.type == 'person' ? '👤 Personal' : '🏦 Bank'}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: t.warning),
                      ),
                    ],
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Icon(Icons.close_rounded, color: t.textSec, size: 22.w),
                  ),
                ],
              ),
              16.verticalSpace,

              _buildDetailRow('Total Borrowed', fmt(loan.amount, currency), t.warning, t),
              _buildDetailRow('Amount Paid', fmt(paidAmt, currency), t.success, t),
              _buildDetailRow('Remaining', fmt(loan.remaining, currency), t.danger, t),
              _buildDetailRow(
                'Interest Rate',
                loan.interestRate > 0 ? '${loan.interestRate}% p.a.' : 'No interest',
                t.text,
                t,
              ),
              _buildDetailRow(
                'Monthly Payment',
                loan.monthlyPayment > 0 ? fmt(loan.monthlyPayment, currency) : 'No fixed EMI',
                t.text,
                t,
              ),
              _buildDetailRow('Start Date', DateFormat('yyyy-MM-dd').format(loan.startDate), t.text, t),
              _buildDetailRow(
                'Due Date',
                loan.dueDate != null ? DateFormat('yyyy-MM-dd').format(loan.dueDate!) : '—',
                isDuePassed ? t.danger : t.text,
                t,
              ),
              _buildDetailRow('Purpose', loan.purpose.isNotEmpty ? loan.purpose : '—', t.text, t),
              _buildDetailRow('Phone', loan.phone.isNotEmpty ? loan.phone : '—', t.text, t),
              _buildDetailRow(
                'Status',
                loan.isCleared ? '✅ Cleared' : '🔄 Active',
                loan.isCleared ? t.success : t.warning,
                t,
              ),

              // Payment history
              if (loan.payments.isNotEmpty) ...[
                16.verticalSpace,
                Text(
                  '💳 Payment History',
                  style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.success),
                ),
                8.verticalSpace,
                ...loan.payments.map((p) => Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: t.successLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: t.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fmt(p.amount, currency),
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: t.success),
                          ),
                          Text(
                            '${DateFormat('yyyy-MM-dd').format(p.date)} · ${p.note.isNotEmpty ? p.note : 'Repayment'}',
                            style: TextStyle(fontSize: 10.5.sp, color: t.textSec),
                          ),
                        ],
                      ),
                      Text(p.id, style: TextStyle(fontSize: 10.sp, color: t.textSec)),
                    ],
                  ),
                )),
              ],

              if (loan.note.isNotEmpty) ...[
                16.verticalSpace,
                Text(
                  '📝 ${loan.note}',
                  style: TextStyle(fontSize: 11.5.sp, fontStyle: FontStyle.italic, color: t.textMuted),
                ),
              ],

              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4.6 Payment Sheet
  // ===========================================================================
  void _showPaymentSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Loan loan,
    DatabaseService db,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateState = DateTime.now().obs;
    final livePreview = ''.obs;

    void updatePreview() {
      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
      if (amt > 0) {
        final remAfter = (loan.remaining - amt).clamp(0.0, double.infinity);
        if (amt >= loan.remaining) {
          livePreview.value = 'Remaining after payment: ${fmt(0, currency)}  🎉 Fully Cleared!';
        } else {
          livePreview.value = 'Remaining after payment: ${fmt(remAfter, currency)}';
        }
      } else {
        livePreview.value = '';
      }
    }

    amountCtrl.addListener(updatePreview);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💳 Record Payment — ${loan.lender}',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: t.text),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: t.textSec, size: 22.w),
                  ),
                ],
              ),
              16.verticalSpace,

              // Info tiles: Still Owed (red) & Monthly EMI (amber)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: t.dangerLight,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: t.danger.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Still Owed', style: TextStyle(fontSize: 11.sp, color: t.danger)),
                          4.verticalSpace,
                          Text(
                            fmt(loan.remaining, currency),
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: t.danger),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (loan.monthlyPayment > 0) ...[
                    10.horizontalSpace,
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: t.warningLight,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: t.warning.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly EMI', style: TextStyle(fontSize: 11.sp, color: t.warning)),
                            4.verticalSpace,
                            Text(
                              fmt(loan.monthlyPayment, currency),
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: t.warning),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              14.verticalSpace,

              // Payment Amount (number, green 2 px border, placeholder "0", min 0)
              _buildFieldLabel('Payment Amount', t),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: t.text, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: t.textMuted),
                  filled: true,
                  fillColor: t.input,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: t.success, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: t.success, width: 2),
                  ),
                ),
              ),

              // Quick fill button: "Use EMI amount (<EMI>)"
              if (loan.monthlyPayment > 0) ...[
                6.verticalSpace,
                GestureDetector(
                  onTap: () {
                    amountCtrl.text = loan.monthlyPayment % 1 == 0
                        ? loan.monthlyPayment.toInt().toString()
                        : loan.monthlyPayment.toString();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: t.warningLight,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Use EMI amount (${fmt(loan.monthlyPayment, currency)})',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: t.warning),
                    ),
                  ),
                ),
              ],
              12.verticalSpace,

              // Payment Date (today by default)
              _buildFieldLabel('Payment Date', t),
              Obx(() => GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateState.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) dateState.value = picked;
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: t.input,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(dateState.value),
                        style: TextStyle(fontSize: 13.sp, color: t.text, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                    ],
                  ),
                ),
              )),
              12.verticalSpace,

              // Note (optional)
              _buildFieldLabel('Note (optional)', t),
              _buildTextInput(noteCtrl, 'e.g. June installment', t),
              14.verticalSpace,

              // Live preview
              Obx(() {
                if (livePreview.value.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: 14.h),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: t.successLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: t.success.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    livePreview.value,
                    style: TextStyle(fontSize: 12.sp, color: t.success, fontWeight: FontWeight.w700),
                  ),
                );
              }),

              // Button ✅ Record Payment (green)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (amt <= 0) {
                      Get.snackbar('Required', 'Please enter a valid payment amount.', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    final seq = loan.payments.length + 1;
                    final pId = 'PMT-${seq.toString().padLeft(3, '0')}';
                    final entry = LoanPaymentEntry(
                      id: pId,
                      amount: amt,
                      date: dateState.value,
                      note: noteCtrl.text.trim(),
                    );

                    db.recordLoanPaymentEntry(loan.id, entry);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment of ${fmt(amt, currency)} recorded.'),
                        backgroundColor: t.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    '✅ Record Payment',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valColor, ThemeTokens t) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp, color: t.textSec)),
          Text(
            value,
            style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w700, color: valColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeTokens t) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: t.textSec),
      ),
    );
  }

  Widget _buildTextInput(
    TextEditingController controller,
    String hint,
    ThemeTokens t, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(color: t.text, fontSize: 13.5.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.textMuted),
        filled: true,
        fillColor: t.input,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
      ),
    );
  }
}
