import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final SettingsController controller;
  late final DatabaseService db;
  late final ThemeLanguageService themeService;
  final TextEditingController jsonInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    db = Get.find<DatabaseService>();
    themeService = Get.find<ThemeLanguageService>();
  }

  @override
  void dispose() {
    jsonInputController.dispose();
    super.dispose();
  }

  void _restoreData() {
    final text = jsonInputController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Error', 'Please paste the backup JSON string to restore', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeService.cardColor,
        title: Text('confirm_restore'.tr, style: TextStyle(color: themeService.textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr, style: TextStyle(color: themeService.subtextColor))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              final success = controller.restoreBackup(text);
              if (success) {
                jsonInputController.clear();
              }
            },
            child: Text('confirm'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'cloud_backup_restore'.tr,
          style: getTextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: themeService.textColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: themeService.textColor),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cloud Sync Status Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_done_rounded, color: AppColors.secondary, size: 24.w),
                          10.horizontalSpace,
                          Text('Cloud Synchronization', style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r)),
                        child: Text('ACTIVE', style: TextStyle(color: AppColors.secondary, fontSize: 10.sp, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  Obx(() => Text(
                        'Last Sync: ${DateFormat('dd MMM yyyy, hh:mm a').format(db.lastSyncTime.value)}',
                        style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor),
                      )),
                  14.verticalSpace,
                  CustomFilledButton(
                    text: 'sync_now'.tr,
                    onPressed: () async {
                      await db.triggerCloudSync();
                      Get.snackbar('Cloud Synced', 'Database synchronized successfully', snackPosition: SnackPosition.BOTTOM);
                    },
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // 2. Export JSON Backup
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_upload_rounded, color: AppColors.primary, size: 24.w),
                      10.horizontalSpace,
                      Text('Export Database Backup', style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                    ],
                  ),
                  8.verticalSpace,
                  Text(
                    'Export complete database (all products, sales, purchases, expenses, and logs) into a portable JSON backup file.',
                    style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                  ),
                  14.verticalSpace,
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text('export_backup'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => controller.exportBackup(),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // 3. Import JSON Restore
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: themeService.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_backup_restore_rounded, color: AppColors.warning, size: 24.w),
                      10.horizontalSpace,
                      Text('Restore from JSON Backup', style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                    ],
                  ),
                  8.verticalSpace,
                  Text(
                    'Paste your previously exported JSON data to restore your store state.',
                    style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                  ),
                  12.verticalSpace,
                  CustomTextField(
                    label: 'Backup JSON Payload',
                    hintText: 'Paste backup JSON here...',
                    controller: jsonInputController,
                    maxLines: 4,
                  ),
                  16.verticalSpace,
                  CustomFilledButton(
                    text: 'import_backup'.tr,
                    color: AppColors.warning,
                    onPressed: _restoreData,
                  ),
                ],
              ),
            ),
            40.verticalSpace,
          ],
        ),
      ),
    );
  }
}
