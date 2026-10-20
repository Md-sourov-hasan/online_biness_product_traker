import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/models/receivable_model.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/common/widgets/stockmate_components.dart';

class MoneyLentScreen extends StatelessWidget {
  const MoneyLentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = Get.find<DatabaseService>();
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = themeService.t;
      final currency = themeService.currentCurrency.value;
      final recs = db.receivables;

      // 5.2 Summary Calculations
      // TOTAL LENT (blue) = sum of amount, all records
      final totalLent = recs.fold(0.0, (sum, r) => sum + r.amount);
      // STILL OUT (red) = sum of remaining, all records
      final stillOut = recs.fold(0.0, (sum, r) => sum + r.remaining);
      // RETURNED (green) = sum of all return entries
      final totalReturned = recs.fold(0.0, (sum, r) => sum + r.totalReturned);

      return CommonBackgroundScaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 5.2 Header (← · 🤝 Money Lent · blue +)
              _buildHeader(context, t, db),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 5.2 Three summary tiles
                      _buildSummaryTiles(t, currency, totalLent, stillOut, totalReturned),
                      16.verticalSpace,

                      // Empty state or Record cards
                      if (recs.isEmpty)
                        _buildEmptyState(t)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recs.length,
                          separatorBuilder: (context, index) => 14.verticalSpace,
                          itemBuilder: (context, index) {
                            final rec = recs[index];
                            return _buildRecordCard(context, t, currency, rec, db);
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

  // --- 5.2 Header (← · 🤝 Money Lent · blue +) ---
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
                '🤝 Money Lent',
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
            onTap: () => _showAddMoneyLentSheet(context, t, db),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: t.accentLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: t.accent.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.add_rounded, color: t.accent, size: 20.w),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5.2 Three summary tiles ---
  Widget _buildSummaryTiles(
    ThemeTokens t,
    String currency,
    double totalLent,
    double stillOut,
    double returned,
  ) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            t: t,
            title: 'TOTAL LENT',
            amount: fmt(totalLent, currency),
            color: t.accent,
            bgColor: t.accentLight,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: _summaryTile(
            t: t,
            title: 'STILL OUT',
            amount: fmt(stillOut, currency),
            color: t.danger,
            bgColor: t.dangerLight,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: _summaryTile(
            t: t,
            title: 'RETURNED',
            amount: fmt(returned, currency),
            color: t.success,
            bgColor: t.successLight,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required ThemeTokens t,
    required String title,
    required String amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
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
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
              fontFamily: 'SF Pro Display',
            ),
          ),
          6.verticalSpace,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 16.sp,
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

  // --- Empty State ---
  Widget _buildEmptyState(ThemeTokens t) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🤝', style: TextStyle(fontSize: 48.sp)),
          12.verticalSpace,
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: t.text,
              fontFamily: 'SF Pro Display',
            ),
          ),
          6.verticalSpace,
          Text(
            'Tap + to record money you gave out',
            style: TextStyle(
              fontSize: 13.sp,
              color: t.textSec,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }

  // --- 5.3 Record card ---
  Widget _buildRecordCard(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Receivable rec,
    DatabaseService db,
  ) {
    // Overdue / Due soon status logic
    final isReturned = rec.isReturned;
    final isOverdue = rec.isOverdue;
    final isDueSoon = rec.isDueSoon;
    final daysDiff = rec.daysUntilDue;

    // Status pill label & color
    String statusLabel = '⏳ Pending';
    Color statusColor = t.danger;
    Color statusBg = t.dangerLight;

    if (isReturned) {
      statusLabel = '✅ Returned';
      statusColor = t.success;
      statusBg = t.successLight;
    } else if (rec.status.toLowerCase() == 'partially_returned' || rec.totalReturned > 0) {
      statusLabel = '🔄 Partial';
      statusColor = t.warning;
      statusBg = t.warningLight;
    }

    final returnPct = rec.returnedPercentage;

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.border),
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Top-left ID + Pills + Name, Top-right Remaining + caption
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Left
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // ID chip (blue)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: t.accentLight,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            rec.id,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: t.accent,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        // Status pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        // Overdue / Due Soon pill (when not returned)
                        if (!isReturned && isOverdue)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: t.dangerLight,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '⚠️ Overdue',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: t.danger,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          )
                        else if (!isReturned && isDueSoon)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: t.warningLight,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '⏰ Due Soon',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: t.warning,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                      ],
                    ),
                    8.verticalSpace,
                    // Person name (16 px bold)
                    Text(
                      rec.person,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: t.text,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (rec.phone.isNotEmpty) ...[
                      4.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Text(
                            rec.phone,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: t.textSec,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (rec.reason.isNotEmpty) ...[
                      4.verticalSpace,
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined, size: 12.w, color: t.textSec),
                          4.horizontalSpace,
                          Expanded(
                            child: Text(
                              rec.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: t.textSec,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    4.verticalSpace,
                    Text(
                      '📅 Given: ${DateFormat('yyyy-MM-dd').format(rec.date)}${rec.dueDate != null ? ' · Due: ${DateFormat('yyyy-MM-dd').format(rec.dueDate!)}' : ''}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: t.textMuted,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    // Countdown line (when not fully returned and due date exists)
                    if (!isReturned && daysDiff != null) ...[
                      4.verticalSpace,
                      Text(
                        isOverdue
                            ? '${daysDiff.abs()} days overdue'
                            : '$daysDiff days left',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isOverdue
                              ? t.danger
                              : (isDueSoon ? t.warning : t.textMuted),
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Top Right: Remaining amount (18 px bold; green if returned, red otherwise)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(rec.remaining, currency),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isReturned ? t.success : t.danger,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  2.verticalSpace,
                  Text(
                    isReturned ? 'fully returned' : 'still pending',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isReturned ? t.success : t.textSec,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ],
          ),

          14.verticalSpace,

          // Progress bar: fill width = (sum of returns / amount) %
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: (returnPct / 100.0).clamp(0.0, 1.0),
                  minHeight: 6.h,
                  backgroundColor: t.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isReturned ? t.success : t.accent,
                  ),
                ),
              ),
              6.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Returned ${returnPct.toStringAsFixed(0)}% · ${fmt(rec.totalReturned, currency)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: t.textSec,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  Text(
                    'Total lent ${fmt(rec.amount, currency)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: t.textSec,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ],
          ),

          14.verticalSpace,
          Divider(color: t.border, height: 1),
          10.verticalSpace,

          // Action buttons (wrapping row):
          // 📋 Details
          // 💵 Record Return (hidden when returned)
          // ✅ Mark Returned / ↩ Reopen
          // 🗑 delete (small red square)
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _actionButton(
                t: t,
                label: '📋 Details',
                color: t.text,
                bgColor: t.input,
                onTap: () => _showDetailsSheet(context, t, currency, rec),
              ),
              if (!isReturned)
                _actionButton(
                  t: t,
                  label: '💵 Record Return',
                  color: t.success,
                  bgColor: t.successLight,
                  onTap: () => _showRecordReturnSheet(context, t, currency, rec, db),
                ),
              _actionButton(
                t: t,
                label: isReturned ? '↩ Reopen' : '✅ Mark Returned',
                color: isReturned ? t.accent : t.success,
                bgColor: isReturned ? t.accentLight : t.successLight,
                onTap: () {
                  if (isReturned) {
                    db.reopenReceivable(rec.id);
                  } else {
                    db.markReceivableReturned(rec.id);
                  }
                },
              ),
              // 🗑 delete (small red square)
              GestureDetector(
                onTap: () => _confirmDelete(context, t, rec, db),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: t.dangerLight,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: t.danger.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: t.danger, size: 16.w),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required ThemeTokens t,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ThemeTokens t, Receivable rec, DatabaseService db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        title: Text(
          'Delete Record?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: t.text,
            fontFamily: 'SF Pro Display',
          ),
        ),
        content: Text(
          'Are you sure you want to remove the money lent record for ${rec.person} (${rec.id})?',
          style: TextStyle(
            fontSize: 13.sp,
            color: t.textSec,
            fontFamily: 'SF Pro Display',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: t.textSec)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              db.deleteReceivable(rec.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: t.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5.4 Record Money Lent sheet
  // ===========================================================================
  void _showAddMoneyLentSheet(BuildContext context, ThemeTokens t, DatabaseService db) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final noteController = TextEditingController();

    DateTime givenDate = DateTime.now();
    DateTime? expectedReturnDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18.w,
                right: 18.w,
                top: 18.h,
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
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🤝 Record Money Lent',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: t.text,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.close_rounded, color: t.textSec, size: 20.w),
                        ),
                      ],
                    ),
                    16.verticalSpace,

                    // 1. Person's Name
                    _formLabel(t, "Person's Name", required: true),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: nameController,
                      hint: 'Who did you give money to?',
                    ),
                    12.verticalSpace,

                    // 2. Phone Number
                    _formLabel(t, 'Phone Number (optional)'),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: phoneController,
                      hint: 'e.g. 01711-123456',
                      keyboardType: TextInputType.phone,
                    ),
                    12.verticalSpace,

                    // 3. Amount Given
                    _formLabel(t, 'Amount Given', required: true),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: amountController,
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    12.verticalSpace,

                    // 4. Reason / Purpose
                    _formLabel(t, 'Reason / Purpose'),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: reasonController,
                      hint: 'e.g. Medical, shop rent, personal help',
                    ),
                    12.verticalSpace,

                    // 5 & 6. Date Given (left) & Expected Return Date (right)
                    Row(
                      children: [
                        // Left: Date Given (today)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel(t, 'Date Given', required: true),
                              6.verticalSpace,
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: givenDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => givenDate = picked);
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
                                        DateFormat('yyyy-MM-dd').format(givenDate),
                                        style: TextStyle(fontSize: 13.sp, color: t.text),
                                      ),
                                      Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        10.horizontalSpace,
                        // Right: Expected Return Date (empty, blue 2px border)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _formLabel(t, 'Expected Return Date'),
                              6.verticalSpace,
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: expectedReturnDate ?? DateTime.now().add(const Duration(days: 30)),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2035),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => expectedReturnDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: t.input,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: t.accent, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        expectedReturnDate != null
                                            ? DateFormat('yyyy-MM-dd').format(expectedReturnDate!)
                                            : 'Select date',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: expectedReturnDate != null ? t.text : t.textMuted,
                                        ),
                                      ),
                                      Icon(Icons.event_outlined, size: 16.w, color: t.accent),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    12.verticalSpace,

                    // 7. Note (optional)
                    _formLabel(t, 'Note (optional)'),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: noteController,
                      hint: 'Any extra details...',
                      maxLines: 2,
                    ),
                    20.verticalSpace,

                    // Save Button: ✅ Save Record (blue)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;

                          if (name.isEmpty) {
                            Get.snackbar('Required Field', 'Please enter person\'s name',
                                backgroundColor: t.danger, colorText: Colors.white);
                            return;
                          }
                          if (amt <= 0) {
                            Get.snackbar('Required Field', 'Please enter a valid amount',
                                backgroundColor: t.danger, colorText: Colors.white);
                            return;
                          }

                          final newId = 'LT-${(db.receivables.length + 1).toString().padLeft(3, '0')}';
                          final newRecord = Receivable(
                            id: newId,
                            person: name,
                            phone: phoneController.text.trim(),
                            amount: amt,
                            remaining: amt,
                            date: givenDate,
                            dueDate: expectedReturnDate,
                            reason: reasonController.text.trim(),
                            note: noteController.text.trim(),
                            status: 'pending',
                            returns: [],
                          );

                          db.addReceivable(newRecord);
                          Navigator.of(context).pop();
                          Get.snackbar('Saved', 'Money lent record created successfully.',
                              backgroundColor: t.accent, colorText: Colors.white);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                          '✅ Save Record',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
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
  // 5.5 Details sheet (title = person; subtitle = ID)
  // ===========================================================================
  void _showDetailsSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Receivable rec,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String statusLabel = '⏳ Pending';
        Color statusColor = t.danger;
        if (rec.isReturned) {
          statusLabel = '✅ Returned';
          statusColor = t.success;
        } else if (rec.status.toLowerCase() == 'partially_returned' || rec.totalReturned > 0) {
          statusLabel = '🔄 Partial';
          statusColor = t.warning;
        }

        return Container(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: 30.h,
          ),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title = person, Subtitle = ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.person,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: t.text,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        2.verticalSpace,
                        Text(
                          rec.id,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: t.accent,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close_rounded, color: t.textSec, size: 20.w),
                    ),
                  ],
                ),
                16.verticalSpace,

                // Key metrics rows
                _detailRow(t, 'Amount Given', fmt(rec.amount, currency), valueColor: t.accent),
                _detailRow(t, 'Amount Returned', fmt(rec.totalReturned, currency), valueColor: t.success),
                _detailRow(t, 'Still Pending', fmt(rec.remaining, currency), valueColor: t.danger),
                _detailRow(t, 'Status', statusLabel, valueColor: statusColor),
                _detailRow(t, 'Date Given', DateFormat('yyyy-MM-dd').format(rec.date)),
                _detailRow(
                  t,
                  'Expected Return',
                  rec.dueDate != null ? DateFormat('yyyy-MM-dd').format(rec.dueDate!) : '—',
                ),
                _detailRow(t, 'Phone', rec.phone.isNotEmpty ? rec.phone : '—'),
                _detailRow(t, 'Reason', rec.reason.isNotEmpty ? rec.reason : '—'),

                // Return History
                if (rec.returns.isNotEmpty) ...[
                  18.verticalSpace,
                  Text(
                    '💵 Return History',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  10.verticalSpace,
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rec.returns.length,
                    separatorBuilder: (context, index) => 8.verticalSpace,
                    itemBuilder: (context, index) {
                      final item = rec.returns[index];
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: t.successLight,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: t.success.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fmt(item.amount, currency),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: t.success,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                2.verticalSpace,
                                Text(
                                  '${DateFormat('yyyy-MM-dd').format(item.date)}${item.note.isNotEmpty ? ' · ${item.note}' : ''}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: t.textSec,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              item.id,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: t.textMuted,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // Note in italics
                if (rec.note.isNotEmpty) ...[
                  16.verticalSpace,
                  Text(
                    '📝 ${rec.note}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: t.textMuted,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 5.6 Record Return sheet (title "💵 Record Return — <person>")
  // ===========================================================================
  void _showRecordReturnSheet(
    BuildContext context,
    ThemeTokens t,
    String currency,
    Receivable rec,
    DatabaseService db,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime returnDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final typedAmt = double.tryParse(amountController.text.trim()) ?? 0.0;
            final remainingAfter = (rec.remaining - typedAmt).clamp(0.0, double.infinity);
            final isFullyReturned = typedAmt >= rec.remaining && rec.remaining > 0;

            return Container(
              padding: EdgeInsets.only(
                left: 18.w,
                right: 18.w,
                top: 18.h,
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
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '💵 Record Return — ${rec.person}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: t.text,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(Icons.close_rounded, color: t.textSec, size: 20.w),
                        ),
                      ],
                    ),
                    16.verticalSpace,

                    // Two tiles: Still Pending (red) and Original Amount (blue)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: t.dangerLight,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Still Pending',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: t.danger,
                                  ),
                                ),
                                4.verticalSpace,
                                Text(
                                  fmt(rec.remaining, currency),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: t.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        10.horizontalSpace,
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: t.accentLight,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Original Amount',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: t.accent,
                                  ),
                                ),
                                4.verticalSpace,
                                Text(
                                  fmt(rec.amount, currency),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: t.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    16.verticalSpace,

                    // Amount Returned (number, green 2 px border)
                    _formLabel(t, 'Amount Returned', required: true),
                    6.verticalSpace,
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: t.success, width: 2),
                      ),
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(fontSize: 15.sp, color: t.text, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: t.textMuted, fontSize: 14.sp),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                          border: InputBorder.none,
                          fillColor: t.input,
                          filled: true,
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    8.verticalSpace,

                    // Quick-fill button: "Full amount (<remaining>)"
                    GestureDetector(
                      onTap: () {
                        amountController.text = rec.remaining.toStringAsFixed(0);
                        setSheetState(() {});
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: t.accentLight,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Full amount (${fmt(rec.remaining, currency)})',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: t.accent,
                          ),
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // Return Date
                    _formLabel(t, 'Return Date'),
                    6.verticalSpace,
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: returnDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setSheetState(() => returnDate = picked);
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
                              DateFormat('yyyy-MM-dd').format(returnDate),
                              style: TextStyle(fontSize: 13.sp, color: t.text),
                            ),
                            Icon(Icons.calendar_today_rounded, size: 16.w, color: t.textSec),
                          ],
                        ),
                      ),
                    ),
                    12.verticalSpace,

                    // Note (optional)
                    _formLabel(t, 'Note (optional)'),
                    6.verticalSpace,
                    _formInput(
                      t: t,
                      controller: noteController,
                      hint: 'e.g. Returned in cash',
                    ),
                    14.verticalSpace,

                    // Live preview: Still pending after this: <max(0, remaining - amount)> plus 🎉 Fully Returned!
                    if (typedAmt > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isFullyReturned ? t.successLight : t.input,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isFullyReturned ? t.success.withValues(alpha: 0.3) : t.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Still pending after this: ${fmt(remainingAfter, currency)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: isFullyReturned ? t.success : t.text,
                              ),
                            ),
                            if (isFullyReturned) ...[
                              6.horizontalSpace,
                              Text(
                                '🎉 Fully Returned!',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: t.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    20.verticalSpace,

                    // Button: ✅ Save Return (green)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            Get.snackbar('Invalid Amount', 'Please enter a valid amount',
                                backgroundColor: t.danger, colorText: Colors.white);
                            return;
                          }

                          final entryId = 'RT-${(rec.returns.length + 1).toString().padLeft(3, '0')}';
                          final returnEntry = MoneyLentReturnEntry(
                            id: entryId,
                            amount: amt,
                            date: returnDate,
                            note: noteController.text.trim(),
                          );

                          db.recordReceivableReturn(rec.id, returnEntry);
                          Navigator.of(context).pop();
                          Get.snackbar('Return Recorded', 'Payment recorded successfully.',
                              backgroundColor: t.success, colorText: Colors.white);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.success,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                          '✅ Save Return',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets ---
  Widget _detailRow(ThemeTokens t, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: t.textSec,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? t.text,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
          6.verticalSpace,
          Divider(color: t.border.withValues(alpha: 0.5), height: 1),
        ],
      ),
    );
  }

  Widget _formLabel(ThemeTokens t, String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: t.text,
            fontFamily: 'SF Pro Display',
          ),
        ),
        if (required)
          Text(' *', style: TextStyle(color: t.danger, fontSize: 12.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _formInput({
    required ThemeTokens t,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: t.input,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: t.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14.sp, color: t.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.textMuted, fontSize: 13.sp),
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
