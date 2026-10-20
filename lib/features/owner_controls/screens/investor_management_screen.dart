import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/models/investor_model.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/common/widgets/stockmate_components.dart';

class InvestorManagementScreen extends StatelessWidget {
  const InvestorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = Get.find<DatabaseService>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = themeService.t;
      final currency = themeService.currentCurrency.value;
      final investors = db.investors;
      final netProfit = db.effectiveNetProfit;

      final totalInvested = investors.fold(0.0, (sum, i) => sum + i.totalInvested);
      final totalWithdrawn = investors.fold(0.0, (sum, i) => sum + i.totalWithdrawn);
      final netActive = totalInvested - totalWithdrawn;

      return CommonBackgroundScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 3.2 Header (← · 👥 Investors · purple +)
              _buildHeader(context, t, db, netProfit),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3.2 Three summary tiles in one row
                      _buildSummaryTiles(t, currency, totalInvested, totalWithdrawn, netActive),
                      16.verticalSpace,

                      // 3.2 Profit Share Summary box (shown when at least one investor exists)
                      if (investors.isNotEmpty) ...[
                        _buildProfitShareSummaryBox(t, currency, investors, netProfit),
                        16.verticalSpace,
                      ],

                      // Empty state or Investor cards
                      if (investors.isEmpty)
                        _buildEmptyState(t)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: investors.length,
                          separatorBuilder: (context, index) => 14.verticalSpace,
                          itemBuilder: (context, index) {
                            final inv = investors[index];
                            return _buildInvestorCard(context, t, currency, inv, netProfit, db);
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

  // --- Header (← · 👥 Investors · purple +) ---
  Widget _buildHeader(BuildContext context, ThemeTokens t, DatabaseService db, double netProfit) {
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
                '👥 Investors',
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
            onTap: () => _showAddInvestorSheet(context, t, db, netProfit),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: t.purpleLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: t.purple.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.add_rounded, color: t.purple, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }

  // --- Three summary tiles in one row ---
  Widget _buildSummaryTiles(
    ThemeTokens t,
    String currency,
    double totalInvested,
    double totalWithdrawn,
    double netActive,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildTile(
            title: 'Total Invested',
            value: fmt(totalInvested, currency),
            valueColor: t.purple,
            t: t,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: _buildTile(
            title: 'Withdrawn',
            value: fmt(totalWithdrawn, currency),
            valueColor: t.danger,
            t: t,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: _buildTile(
            title: 'Net Active',
            value: fmt(netActive, currency),
            valueColor: t.success,
            t: t,
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    required String value,
    required Color valueColor,
    required ThemeTokens t,
  }) {
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
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
              color: t.textSec,
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
                color: valueColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profit Share Summary box (purple-to-blue gradient) ---
  Widget _buildProfitShareSummaryBox(
    ThemeTokens t,
    String currency,
    List<Investor> investors,
    double netProfit,
  ) {
    final sharingInvestors = investors.where((i) => i.profitShare > 0).toList();
    final totalProfitDistributed = sharingInvestors.fold(
      0.0,
      (sum, i) => sum + i.calculateProfitDue(netProfit),
    );

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.purple.withValues(alpha: 0.9),
            t.accent.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: t.purple.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Profit Share Summary (Net Profit: ${fmt(netProfit, currency)})',
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'SF Pro Display',
            ),
          ),
          10.verticalSpace,
          if (sharingInvestors.isEmpty)
            Text(
              'No profit share % set on any investor yet.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            ...sharingInvestors.map((i) {
              final shareFormatted = i.profitShare % 1 == 0
                  ? i.profitShare.toInt().toString()
                  : i.profitShare.toStringAsFixed(1);
              final profitAmt = i.calculateProfitDue(netProfit);

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${i.name} ($shareFormatted%)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    Text(
                      fmt(profitAmt, currency),
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
            8.verticalSpace,
            Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
            6.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Profit Distributed',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  fmt(totalProfitDistributed, currency),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState(ThemeTokens t) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 50.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: t.purpleLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_alt_rounded, size: 40.w, color: t.purple),
            ),
            14.verticalSpace,
            Text(
              'No investors yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            6.verticalSpace,
            Text(
              'Tap + to add your first investor',
              style: TextStyle(fontSize: 12.sp, color: t.textSec),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3.3 Investor Card ---
  Widget _buildInvestorCard(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Investor inv,
    double netProfit,
    DatabaseService db,
  ) {
    final profitDue = inv.calculateProfitDue(netProfit);
    final dateFormatted = DateFormat('yyyy-MM-dd').format(inv.date);

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
              // Top Left: ID chip, status pill, name, optional lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // ID chip
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: t.purpleLight,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            inv.id,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: t.purple,
                            ),
                          ),
                        ),
                        6.horizontalSpace,
                        // Status pill (Active green / Inactive red)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: inv.isActive ? t.successLight : t.dangerLight,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            inv.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: inv.isActive ? t.success : t.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    Text(
                      inv.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (inv.phone.isNotEmpty) ...[
                      3.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Text(
                            inv.phone,
                            style: TextStyle(fontSize: 11.5.sp, color: t.textSec),
                          ),
                        ],
                      ),
                    ],
                    if (inv.email.isNotEmpty) ...[
                      2.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Text(
                            inv.email,
                            style: TextStyle(fontSize: 11.5.sp, color: t.textSec),
                          ),
                        ],
                      ),
                    ],
                    2.verticalSpace,
                    Text(
                      '📅 Joined: $dateFormatted',
                      style: TextStyle(fontSize: 11.sp, color: t.textSec),
                    ),
                    if (inv.note.isNotEmpty) ...[
                      3.verticalSpace,
                      Text(
                        inv.note,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontStyle: FontStyle.italic,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Top Right: Initial invest amount in purple with "invested" caption
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(inv.investAmount, currency),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: t.purple,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Text(
                    'invested',
                    style: TextStyle(fontSize: 10.sp, color: t.textSec),
                  ),
                  if (inv.profitShare > 0) ...[
                    2.verticalSpace,
                    Text(
                      '${inv.profitShare % 1 == 0 ? inv.profitShare.toInt() : inv.profitShare.toStringAsFixed(1)}% share',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: t.success,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          12.verticalSpace,
          Container(height: 1, color: t.border),
          10.verticalSpace,

          // Metric strip (3 or 4 small tiles in a row)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Net Balance',
                  value: fmt(inv.netBalance, currency),
                  color: t.success,
                  t: t,
                ),
              ),
              6.horizontalSpace,
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Invested',
                  value: fmt(inv.totalInvested, currency),
                  color: t.purple,
                  t: t,
                ),
              ),
              6.horizontalSpace,
              Expanded(
                child: _buildMetricTile(
                  label: 'Withdrawn',
                  value: fmt(inv.totalWithdrawn, currency),
                  color: t.danger,
                  t: t,
                ),
              ),
              if (inv.profitShare > 0) ...[
                6.horizontalSpace,
                Expanded(
                  child: _buildMetricTile(
                    label: 'Profit Due',
                    value: fmt(profitDue, currency),
                    color: t.warning,
                    t: t,
                  ),
                ),
              ],
            ],
          ),

          // Re-invested banner (only if re-investments exist)
          if (inv.reinvestments.isNotEmpty) ...[
            10.verticalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: t.successLight,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: t.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🔄 Re-invested',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: t.success,
                    ),
                  ),
                  Text(
                    '${fmt(inv.totalReinvestments, currency)} (${inv.reinvestments.length} time${inv.reinvestments.length > 1 ? 's' : ''})',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: t.success,
                    ),
                  ),
                ],
              ),
            ),
          ],

          12.verticalSpace,

          // Action buttons (2 × 2 grid, each at least 45% width)
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: '📋 Details',
                  color: t.accent,
                  bgColor: t.accentLight,
                  onTap: () => _showDetailsSheet(context, t, currency, inv, netProfit),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _buildActionButton(
                  label: '🔄 Re-Invest',
                  color: t.success,
                  bgColor: t.successLight,
                  onTap: () => _showReinvestSheet(context, t, currency, inv, db),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: '💸 Withdrawal',
                  color: t.danger,
                  bgColor: t.dangerLight,
                  onTap: () => _showWithdrawalSheet(context, t, currency, inv, db),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _buildActionButton(
                  label: inv.isActive ? '⏸ Deactivate' : '▶ Activate',
                  color: inv.isActive ? t.warning : t.success,
                  bgColor: inv.isActive ? t.warningLight : t.successLight,
                  onTap: () => db.toggleInvestorStatus(inv.id),
                ),
              ),
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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.sp, color: t.textSec),
          ),
          3.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3.4 Add Investor Sheet
  // ===========================================================================
  void _showAddInvestorSheet(
    BuildContext context,
    ThemeTokens t,
    DatabaseService db,
    double netProfit,
  ) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final shareCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();
    String liveProfitHint = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateHint() {
              final share = double.tryParse(shareCtrl.text.trim()) ?? 0.0;
              if (share > 0) {
                final amt = netProfit * (share / 100);
                final currency = ThemeLanguageService.to.currentCurrency.value;
                setSheetState(() {
                  liveProfitHint =
                      '💡 This investor will receive ${share % 1 == 0 ? share.toInt() : share.toStringAsFixed(1)}% of net profit = ${fmt(amt, currency)} this year';
                });
              } else {
                setSheetState(() {
                  liveProfitHint = '';
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
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
                          'Add Investor',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: t.text,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.close_rounded, color: t.textSec, size: 22.w),
                        ),
                      ],
                    ),
                    16.verticalSpace,

                    // 1. Full Name (text, "e.g. Rahim Uddin", required)
                    _buildFieldLabel('Full Name *', t),
                    _buildTextInput(nameCtrl, 'e.g. Rahim Uddin', t),
                    12.verticalSpace,

                    // 2. Phone Number (text, "e.g. 01711-123456", optional)
                    _buildFieldLabel('Phone Number', t),
                    _buildTextInput(phoneCtrl, 'e.g. 01711-123456', t, keyboardType: TextInputType.phone),
                    12.verticalSpace,

                    // 3. Email (optional)
                    _buildFieldLabel('Email (optional)', t),
                    _buildTextInput(emailCtrl, 'e.g. rahim@email.com', t, keyboardType: TextInputType.emailAddress),
                    12.verticalSpace,

                    // 4. Investment Amount (number, "0.00", required)
                    _buildFieldLabel('Investment Amount *', t),
                    _buildTextInput(amountCtrl, '0.00', t, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                    12.verticalSpace,

                    // 5. Profit Share % (number, "e.g. 25", optional, default 0)
                    _buildFieldLabel('Profit Share %', t),
                    _buildTextInput(
                      shareCtrl,
                      'e.g. 25',
                      t,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => updateHint(),
                    ),
                    12.verticalSpace,

                    // 6. Investment Date (date, default today; purple 2 px border, required)
                    _buildFieldLabel('Investment Date *', t),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => pickedDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: t.input,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: t.purple, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('yyyy-MM-dd').format(pickedDate),
                              style: TextStyle(fontSize: 13.sp, color: t.text, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 16.w, color: t.purple),
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // 7. Note (optional)
                    _buildFieldLabel('Note (optional)', t),
                    _buildTextInput(noteCtrl, 'e.g. Silent partner, equipment investor', t),
                    14.verticalSpace,

                    // Live hint
                    if (liveProfitHint.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 14.h),
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: t.purpleLight,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: t.purple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          liveProfitHint,
                          style: TextStyle(fontSize: 11.5.sp, color: t.purple, fontWeight: FontWeight.w600),
                        ),
                      ),

                    // Button: Add Investor (full width, purple)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter investor full name.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid investment amount.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final share = double.tryParse(shareCtrl.text.trim()) ?? 0.0;
                          final seq = db.investors.length + 1;
                          final id = 'INV-${seq.toString().padLeft(3, '0')}';

                          final newInvestor = Investor(
                            id: id,
                            name: name,
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            investAmount: amt,
                            profitShare: share,
                            date: pickedDate,
                            note: noteCtrl.text.trim(),
                            status: 'active',
                          );

                          db.addInvestor(newInvestor);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Investor $name added successfully.'),
                              backgroundColor: t.purple,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.purple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          'Add Investor',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 3.5 Details Sheet
  // ===========================================================================
  void _showDetailsSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Investor inv,
    double netProfit,
  ) {
    final profitDue = inv.calculateProfitDue(netProfit);
    final joinDate = DateFormat('yyyy-MM-dd').format(inv.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
                // Title = investor name; subtitle = ID in blue
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.name,
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: t.text),
                        ),
                        Text(
                          inv.id,
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: t.accent),
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

                // 10 detail rows
                _buildDetailRow('Initial Investment', fmt(inv.investAmount, currency), t.purple, t),
                _buildDetailRow('Re-Investments', fmt(inv.totalReinvestments, currency), t.success, t),
                _buildDetailRow('Total Invested', fmt(inv.totalInvested, currency), t.purple, t),
                _buildDetailRow('Profit Share', '${inv.profitShare % 1 == 0 ? inv.profitShare.toInt() : inv.profitShare.toStringAsFixed(1)}%', t.success, t),
                _buildDetailRow('Profit Due', fmt(profitDue, currency), t.success, t),
                _buildDetailRow('Total Withdrawn', fmt(inv.totalWithdrawn, currency), t.danger, t),
                _buildDetailRow('Net Balance', fmt(inv.netBalance, currency), t.accent, t),
                _buildDetailRow('Join Date', joinDate, t.text, t),
                _buildDetailRow('Phone', inv.phone.isNotEmpty ? inv.phone : '—', t.text, t),
                _buildDetailRow('Email', inv.email.isNotEmpty ? inv.email : '—', t.text, t),

                // Re-investment history
                if (inv.reinvestments.isNotEmpty) ...[
                  16.verticalSpace,
                  Text(
                    '🔄 Re-Investment History',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.success),
                  ),
                  8.verticalSpace,
                  ...inv.reinvestments.map((r) => Container(
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
                              fmt(r.amount, currency),
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: t.success),
                            ),
                            Text(
                              '${DateFormat('yyyy-MM-dd').format(r.date)} · ${r.note.isNotEmpty ? r.note : 'Re-investment'}',
                              style: TextStyle(fontSize: 10.5.sp, color: t.textSec),
                            ),
                          ],
                        ),
                        Text(r.id, style: TextStyle(fontSize: 10.sp, color: t.textSec)),
                      ],
                    ),
                  )),
                ],

                // Withdrawal history
                if (inv.withdrawals.isNotEmpty) ...[
                  16.verticalSpace,
                  Text(
                    '💸 Withdrawal History',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w700, color: t.danger),
                  ),
                  8.verticalSpace,
                  ...inv.withdrawals.map((w) => Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: t.dangerLight,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: t.danger.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmt(w.amount, currency),
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: t.danger),
                            ),
                            Text(
                              '${DateFormat('yyyy-MM-dd').format(w.date)} · ${w.note.isNotEmpty ? w.note : 'Withdrawal'}',
                              style: TextStyle(fontSize: 10.5.sp, color: t.textSec),
                            ),
                          ],
                        ),
                        Text(w.id, style: TextStyle(fontSize: 10.sp, color: t.textSec)),
                      ],
                    ),
                  )),
                ],

                if (inv.note.isNotEmpty) ...[
                  16.verticalSpace,
                  Text(
                    '📝 ${inv.note}',
                    style: TextStyle(fontSize: 11.5.sp, fontStyle: FontStyle.italic, color: t.textMuted),
                  ),
                ],

                20.verticalSpace,
              ],
            ),
          ),
        );
      },
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

  // ===========================================================================
  // 3.6 Withdrawal Sheet
  // ===========================================================================
  void _showWithdrawalSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Investor inv,
    DatabaseService db,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
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
                          'Withdrawal — ${inv.name}',
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

                    // Info bar: "Available Balance" = initial + re-investments − withdrawals (purple)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: t.purpleLight,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: t.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: t.purple),
                          ),
                          Text(
                            fmt(inv.netBalance, currency),
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: t.purple),
                          ),
                        ],
                      ),
                    ),
                    14.verticalSpace,

                    // Withdrawal Amount (number, red 2 px border, placeholder "0.00", min 0)
                    _buildFieldLabel('Withdrawal Amount', t),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: t.text, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: t.textMuted),
                        filled: true,
                        fillColor: t.input,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: t.danger, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: t.danger, width: 2),
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // Date
                    _buildFieldLabel('Date', t),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => pickedDate = picked);
                        }
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
                              DateFormat('yyyy-MM-dd').format(pickedDate),
                              style: TextStyle(fontSize: 13.sp, color: t.text, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // Note (optional)
                    _buildFieldLabel('Note (optional)', t),
                    _buildTextInput(noteCtrl, 'e.g. Monthly profit payout', t),
                    16.verticalSpace,

                    // Button Record Withdrawal (red)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          if (amt > inv.netBalance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Withdrawal amount (${fmt(amt, currency)}) exceeds Available Balance (${fmt(inv.netBalance, currency)}).',
                                ),
                                backgroundColor: t.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final seq = inv.withdrawals.length + 1;
                          final wId = 'WD-${seq.toString().padLeft(3, '0')}';
                          final withdrawal = InvestorSubRecord(
                            id: wId,
                            amount: amt,
                            date: pickedDate,
                            note: noteCtrl.text.trim(),
                          );

                          db.addInvestorWithdrawal(inv.id, withdrawal);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Withdrawal of ${fmt(amt, currency)} recorded.'),
                              backgroundColor: t.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.danger,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          'Record Withdrawal',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 3.7 Re-Invest Sheet
  // ===========================================================================
  void _showReinvestSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Investor inv,
    DatabaseService db,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime pickedDate = DateTime.now();
    String liveTotalPreview = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updatePreview() {
              final add = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (add > 0) {
                setSheetState(() {
                  liveTotalPreview = 'New Total: ${fmt(inv.totalInvested + add, currency)}';
                });
              } else {
                setSheetState(() {
                  liveTotalPreview = '';
                });
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
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
                          '🔄 Re-Invest — ${inv.name}',
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

                    // Info bars
                    _buildInfoRow('Initial Investment', fmt(inv.investAmount, currency), t.success, t.successLight),
                    if (inv.reinvestments.isNotEmpty) ...[
                      6.verticalSpace,
                      _buildInfoRow('Previous Re-investments', fmt(inv.totalReinvestments, currency), t.success, t.successLight),
                    ],
                    6.verticalSpace,
                    _buildInfoRow('Total Invested So Far', fmt(inv.totalInvested, currency), t.purple, t.purpleLight),
                    14.verticalSpace,

                    // Re-Investment Amount (number, green 2 px border, placeholder "0.00")
                    _buildFieldLabel('Re-Investment Amount', t),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => updatePreview(),
                      style: TextStyle(color: t.text, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: '0.00',
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
                    12.verticalSpace,

                    // Date
                    _buildFieldLabel('Date', t),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: pickedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => pickedDate = picked);
                        }
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
                              DateFormat('yyyy-MM-dd').format(pickedDate),
                              style: TextStyle(fontSize: 13.sp, color: t.text, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // Note (optional)
                    _buildFieldLabel('Note (optional)', t),
                    _buildTextInput(noteCtrl, 'e.g. Q2 profit reinvested', t),
                    14.verticalSpace,

                    // Live preview
                    if (liveTotalPreview.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 14.h),
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: t.successLight,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: t.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          liveTotalPreview,
                          style: TextStyle(fontSize: 12.sp, color: t.success, fontWeight: FontWeight.w700),
                        ),
                      ),

                    // Button: ✅ Confirm Re-Investment (green)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid amount.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final seq = inv.reinvestments.length + 1;
                          final rId = 'RI-${seq.toString().padLeft(3, '0')}';
                          final reinvestment = InvestorSubRecord(
                            id: rId,
                            amount: amt,
                            date: pickedDate,
                            note: noteCtrl.text.trim(),
                          );

                          db.addInvestorReinvestment(inv.id, reinvestment);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Re-investment of ${fmt(amt, currency)} added.'),
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
                          '✅ Confirm Re-Investment',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String title, String val, Color color, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: color)),
          Text(val, style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.w800, color: color)),
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
