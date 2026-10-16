import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/policy_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class PolicyControlScreen extends StatefulWidget {
  const PolicyControlScreen({super.key});

  @override
  State<PolicyControlScreen> createState() => _PolicyControlScreenState();
}

class _PolicyControlScreenState extends State<PolicyControlScreen> {
  late TextEditingController minPriceFloorCtrl;
  late TextEditingController exchangeFloorCtrl;
  late TextEditingController maxSkusCtrl;
  late TextEditingController maxUnitsCtrl;
  late TextEditingController retentionCtrl;
  late String refundMode;

  @override
  void initState() {
    super.initState();
    final db = Get.find<DatabaseService>();
    final pol = db.policy.value;
    minPriceFloorCtrl = TextEditingController(text: pol.minimumPricePercentage.toStringAsFixed(0));
    exchangeFloorCtrl = TextEditingController(text: pol.exchangeFloorPercentage.toStringAsFixed(0));
    maxSkusCtrl = TextEditingController(text: pol.maxDistinctSkusPerSale.toString());
    maxUnitsCtrl = TextEditingController(text: pol.maxTotalUnitsPerSale.toString());
    retentionCtrl = TextEditingController(text: pol.auditRetentionMonths.toString());
    refundMode = pol.refundMode;
  }

  @override
  void dispose() {
    minPriceFloorCtrl.dispose();
    exchangeFloorCtrl.dispose();
    maxSkusCtrl.dispose();
    maxUnitsCtrl.dispose();
    retentionCtrl.dispose();
    super.dispose();
  }

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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro banner
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: AppColors.primary, size: 28.w),
                          12.horizontalSpace,
                          Expanded(
                            child: Text(
                              'Owner Governance Center: Rules configured here are strictly enforced across all manager and staff operations.',
                              style: TextStyle(fontSize: 12.sp, color: theme.textColor, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    20.verticalSpace,

                    // 1. Minimum Selling Price Policy (Spec Section 4.2)
                    _buildSectionCard(
                      theme: theme,
                      icon: Icons.price_check_rounded,
                      title: 'Minimum Selling-Price / Bargain Floor Policy',
                      subtitle: 'Manager and Staff cannot bargain or sell below this floor percentage of base price.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minPriceFloorCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Bargain Floor Percentage',
                                    suffixText: '%',
                                    helperText: 'e.g. 80% on ৳1000 item sets ৳800 floor',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    16.verticalSpace,

                    // 2. Returns & Refunds Policy (Spec Section 8)
                    _buildSectionCard(
                      theme: theme,
                      icon: Icons.replay_circle_filled_rounded,
                      title: 'Return, Refund & Exchange Policy',
                      subtitle: 'Controls whether returns are allowed and sets exchange downgrade floor.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: refundMode,
                            decoration: const InputDecoration(labelText: 'Store Return Mode'),
                            items: const [
                              DropdownMenuItem(value: 'money_refund', child: Text('Money Refund & Exchange Allowed')),
                              DropdownMenuItem(value: 'exchange', child: Text('Exchange Only (No Cash Refund)')),
                              DropdownMenuItem(value: 'no_refund', child: Text('Strict No Return / No Refund')),
                            ],
                            onChanged: (val) => setState(() => refundMode = val ?? refundMode),
                          ),
                          12.verticalSpace,
                          TextField(
                            controller: exchangeFloorCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Exchange Minimum Value Floor %',
                              suffixText: '%',
                              helperText: 'Formula: Exchange Floor = Original Value × Floor % (e.g. 80%)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    16.verticalSpace,

                    // 3. Sales Transaction Hard Limits (Spec Section 7.1)
                    _buildSectionCard(
                      theme: theme,
                      icon: Icons.rule_folder_rounded,
                      title: 'Sales Transaction Hard Limits',
                      subtitle: 'System rejects checkout if single transaction exceeds these thresholds.',
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: maxSkusCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Distinct SKUs',
                                helperText: 'Default: 10 SKUs',
                              ),
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: TextField(
                              controller: maxUnitsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Total Units',
                                helperText: 'Default: 100 units',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    16.verticalSpace,

                    // 4. Audit Log Retention (Spec Section 14.3)
                    _buildSectionCard(
                      theme: theme,
                      icon: Icons.history_edu_rounded,
                      title: 'Audit Log Retention',
                      subtitle: 'Logs older than retention period are automatically expired for efficiency.',
                      child: TextField(
                        controller: retentionCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Retention Duration',
                          suffixText: 'Months',
                          helperText: 'Target: 6 Months retention',
                        ),
                      ),
                    ),
                    24.verticalSpace,

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final minPrice = double.tryParse(minPriceFloorCtrl.text.trim()) ?? 80.0;
                          final exFloor = double.tryParse(exchangeFloorCtrl.text.trim()) ?? 80.0;
                          final skus = int.tryParse(maxSkusCtrl.text.trim()) ?? 10;
                          final units = int.tryParse(maxUnitsCtrl.text.trim()) ?? 100;
                          final ret = int.tryParse(retentionCtrl.text.trim()) ?? 6;

                          final newPolicy = PolicyModel(
                            minimumPricePercentage: minPrice,
                            exchangeFloorPercentage: exFloor,
                            refundMode: refundMode,
                            maxDistinctSkusPerSale: skus,
                            maxTotalUnitsPerSale: units,
                            auditRetentionMonths: ret,
                          );

                          db.updatePolicy(newPolicy);
                          Get.snackbar(
                            'Policy Updated',
                            'Governance rules saved and enforced across app.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.success,
                            colorText: Colors.white,
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: Text('Save & Enforce Policies', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
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
                  'Governance & Policy Control',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  'Owner Exclusive • Price Floors, Returns & Limits',
                  style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeLanguageService theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: theme.inputBorderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.w),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
                    Text(subtitle, style: TextStyle(fontSize: 11.sp, color: theme.subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          14.verticalSpace,
          child,
        ],
      ),
    );
  }
}
