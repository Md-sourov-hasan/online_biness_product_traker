import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'user_management'.tr,
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
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Header Banner
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, color: AppColors.primary, size: 24.w),
                  12.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Secondary devices require Super Admin approval before gaining system access.',
                      style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: themeService.textColor),
                    ),
                  ),
                ],
              ),
            ),
            20.verticalSpace,

            Text(
              'Registered Devices & Staff Accounts',
              style: getTextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
            ),
            12.verticalSpace,

            Obx(() {
              final users = controller.db.users;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (c, i) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isPending = user.approvalStatus == 'pending';
                  final isApproved = user.approvalStatus == 'approved';

                  return Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isPending ? AppColors.warning : themeService.inputBorderColor,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
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
                                CircleAvatar(
                                  radius: 18.w,
                                  backgroundColor: (isApproved ? AppColors.secondary : AppColors.warning).withValues(alpha: 0.1),
                                  child: Icon(
                                    isApproved ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                                    color: isApproved ? AppColors.secondary : AppColors.warning,
                                    size: 18.w,
                                  ),
                                ),
                                10.horizontalSpace,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name, style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor)),
                                    2.verticalSpace,
                                    Text(user.email, style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: (isApproved ? AppColors.secondary : AppColors.warning).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                user.approvalStatus.toUpperCase(),
                                style: getTextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isApproved ? AppColors.secondary : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        8.verticalSpace,
                        Text('Device: ${user.deviceName}', style: getTextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor)),
                        8.verticalSpace,
                        Divider(color: themeService.inputBorderColor),
                        8.verticalSpace,
                        // Role & Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Role: ', style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: themeService.subtextColor)),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: user.role,
                                    dropdownColor: themeService.cardColor,
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.sp),
                                    items: AppConstants.userRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        controller.updateUserRole(user.id, val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (isPending)
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => controller.rejectUser(user.id),
                                    child: Text('reject'.tr, style: TextStyle(color: AppColors.error, fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                  ),
                                  6.horizontalSpace,
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                    ),
                                    onPressed: () => controller.approveUser(user.id),
                                    child: Text('approve'.tr, style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
