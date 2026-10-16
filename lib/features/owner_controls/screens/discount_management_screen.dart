import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/discount_rule_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class DiscountManagementScreen extends StatelessWidget {
  const DiscountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = Get.find<DatabaseService>();
    final AuthService auth = Get.find<AuthService>();
    final PermissionService perm = Get.find<PermissionService>();
    final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, theme, perm),
            Expanded(
              child: Obx(() {
                final rules = db.discountRules;
                final activeRules = rules.where((r) => r.isCurrentlyActive).toList();
                final pendingRules = rules.where((r) => r.status == 'pending').toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Metrics
                      _buildSummaryRow(theme, activeRules.length, pendingRules.length, rules.length),
                      20.verticalSpace,

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount Rules & Authorizations',
                            style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showRequestDiscountDialog(context, db, auth, theme),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(perm.isOwner ? 'Create Rule' : 'Request Discount'),
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

                      if (rules.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.h),
                            child: Column(
                              children: [
                                Icon(Icons.discount_outlined, size: 48, color: theme.subtextColor),
                                12.verticalSpace,
                                Text('No discount authorizations recorded.', style: TextStyle(color: theme.subtextColor)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rules.length,
                          separatorBuilder: (context, index) => 12.verticalSpace,
                          itemBuilder: (context, index) {
                            final rule = rules[index];
                            return _buildDiscountCard(context, db, auth, perm, theme, rule);
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

  Widget _buildAppBar(BuildContext context, ThemeLanguageService theme, PermissionService perm) {
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
                  'Discount Approvals & Campaigns',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  perm.isOwner ? 'Owner Approval Gateway' : 'Manager Request Workflow',
                  style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeLanguageService theme, int active, int pending, int total) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.inputBorderColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCountBadge('Currently Active', active, AppColors.success, theme),
          Container(width: 1, height: 35, color: theme.inputBorderColor),
          _buildCountBadge('Pending Owner Approval', pending, Colors.orange, theme),
          Container(width: 1, height: 35, color: theme.inputBorderColor),
          _buildCountBadge('Total Rules', total, AppColors.primary, theme),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color, ThemeLanguageService theme) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: color)),
        4.verticalSpace,
        Text(label, style: TextStyle(fontSize: 10.sp, color: theme.subtextColor)),
      ],
    );
  }

  Widget _buildDiscountCard(
    BuildContext context,
    DatabaseService db,
    AuthService auth,
    PermissionService perm,
    ThemeLanguageService theme,
    DiscountRule rule,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isOwner = perm.isOwner;

    Color badgeColor;
    if (rule.status == 'approved') {
      badgeColor = rule.isCurrentlyActive ? AppColors.success : Colors.grey;
    } else if (rule.status == 'rejected') {
      badgeColor = Colors.redAccent;
    } else {
      badgeColor = Colors.orange;
    }

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
                child: Text(rule.name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  rule.status == 'approved' && !rule.isCurrentlyActive ? 'EXPIRED' : rule.status.toUpperCase(),
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: badgeColor),
                ),
              ),
            ],
          ),
          8.verticalSpace,
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
                    Text('Discount Rate:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${rule.discountPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Scope:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${rule.scope.toUpperCase()}${rule.targetValue.isNotEmpty ? " (${rule.targetValue})" : ""}',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.textColor)),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Validity Period:', style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
                    Text('${dateFormat.format(rule.startDate)} - ${dateFormat.format(rule.endDate)}',
                        style: TextStyle(fontSize: 11.sp, color: theme.textColor)),
                  ],
                ),
                if (rule.requesterName.isNotEmpty) ...[
                  4.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Requested By:', style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                      Text(rule.requesterName, style: TextStyle(fontSize: 11.sp, color: theme.textColor)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (rule.reason.isNotEmpty) ...[
            8.verticalSpace,
            Text('Reason: ${rule.reason}', style: TextStyle(fontSize: 11.sp, fontStyle: FontStyle.italic, color: theme.subtextColor)),
          ],

          // Owner Approval Actions
          if (isOwner && rule.status == 'pending') ...[
            12.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => db.rejectDiscount(rule.id),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Reject'),
                ),
                10.horizontalSpace,
                ElevatedButton(
                  onPressed: () {
                    final userName = auth.currentUser.value?.name ?? 'Owner';
                    final userId = auth.currentUser.value?.id ?? 'owner';
                    db.approveDiscount(rule.id, userId, userName);
                    Get.snackbar('Approved', '${rule.name} authorized for store sales.', snackPosition: SnackPosition.BOTTOM);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                  child: const Text('Approve Discount'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRequestDiscountDialog(
    BuildContext context,
    DatabaseService db,
    AuthService auth,
    ThemeLanguageService theme,
  ) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '10.0');
    final reasonCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String selectedScope = 'all';
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('Discount Authorization Request', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Campaign / Rule Name (e.g. Weekend Flash Sale)'),
                ),
                8.verticalSpace,
                DropdownButtonFormField<String>(
                  initialValue: selectedScope,
                  decoration: const InputDecoration(labelText: 'Discount Scope'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Products')),
                    DropdownMenuItem(value: 'brand', child: Text('Specific Brand')),
                    DropdownMenuItem(value: 'category', child: Text('Specific Category')),
                  ],
                  onChanged: (val) => setState(() => selectedScope = val ?? selectedScope),
                ),
                if (selectedScope != 'all') ...[
                  8.verticalSpace,
                  TextField(
                    controller: targetCtrl,
                    decoration: InputDecoration(labelText: 'Target $selectedScope name (e.g. Samsung)'),
                  ),
                ],
                8.verticalSpace,
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount Percentage (%)'),
                ),
                8.verticalSpace,
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Business Reason for Discount'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty || rate <= 0) return;

                final isOwner = auth.isSuperAdmin;
                final user = auth.currentUser.value;

                final rule = DiscountRule(
                  id: const Uuid().v4(),
                  name: name,
                  scope: selectedScope,
                  targetValue: targetCtrl.text.trim(),
                  discountPercentage: rate,
                  startDate: start,
                  endDate: end,
                  requesterId: user?.id ?? '',
                  requesterName: user?.name ?? 'Manager',
                  status: isOwner ? 'approved' : 'pending',
                  approverName: isOwner ? (user?.name ?? 'Owner') : '',
                  approverId: isOwner ? (user?.id ?? 'owner') : '',
                  reason: reasonCtrl.text.trim(),
                );

                db.requestDiscount(rule);
                Navigator.pop(ctx);
                Get.snackbar(
                  isOwner ? 'Discount Active' : 'Request Submitted',
                  isOwner ? 'Discount authorized and active.' : 'Discount submitted for Owner approval.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
