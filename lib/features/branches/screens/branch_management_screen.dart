import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/utils/sizer.dart';
import '../../../routes/app_routes.dart';

class BranchManagementScreen extends StatelessWidget {
  const BranchManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final t = themeService.t;

    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.w,
            color: t.text,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch Management',
              style: getTextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: t.text,
              ),
            ),
            Text(
              'Enterprise Multi-Outlet Governance',
              style: getTextStyle(
                fontSize: 11.sp,
                color: t.textSec,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            20.verticalSpace,

            // Central Animated/Glow Icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.accent.withValues(alpha: 0.12),
                    ),
                  ),
                  Container(
                    width: 96.w,
                    height: 96.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          t.accent,
                          t.accentLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.domain_add_rounded,
                        size: 46.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            24.verticalSpace,

            // COMING SOON Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.warning,
                    t.warning.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: t.warning.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 14.w,
                  ),
                  6.horizontalSpace,
                  Text(
                    'COMING SOON',
                    style: getTextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            16.verticalSpace,

            // Main Title
            Text(
              'Branch Management Module',
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: t.text,
              ),
            ),
            8.verticalSpace,

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                'We are building an advanced management suite to give you full control over store branches, manager assignments, operational hours, and warehouse policies.',
                textAlign: TextAlign.center,
                style: getTextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: t.textSec,
                  lineHeight: 18.sp,
                ),
              ),
            ),
            32.verticalSpace,

            // Planned Features Preview Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: t.border),
                boxShadow: [
                  BoxShadow(
                    color: t.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        color: t.accent,
                        size: 18.w,
                      ),
                      8.horizontalSpace,
                      Text(
                        'Planned Features in Next Release',
                        style: getTextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  _buildFeatureBullet(
                    icon: Icons.add_business_rounded,
                    title: 'Create & Onboard Outlets',
                    description: 'Add new outlets with custom address, contact & color codes.',
                    color: t.accent,
                    t: t,
                  ),
                  12.verticalSpace,
                  _buildFeatureBullet(
                    icon: Icons.person_pin_rounded,
                    title: 'Assign Branch Managers',
                    description: 'Delegate operational control to specific branch managers.',
                    color: t.purple,
                    t: t,
                  ),
                  12.verticalSpace,
                  _buildFeatureBullet(
                    icon: Icons.rule_folder_rounded,
                    title: 'Branch-Specific Price Floors',
                    description: 'Custom discount rules & sales quotas for each location.',
                    color: t.warning,
                    t: t,
                  ),
                  12.verticalSpace,
                  _buildFeatureBullet(
                    icon: Icons.sync_alt_rounded,
                    title: 'Automated Stock Transfers',
                    description: 'AI-assisted rebalancing between low and high demand branches.',
                    color: t.success,
                    t: t,
                  ),
                ],
              ),
            ),
            32.verticalSpace,

            // View Active Outlets Button
            CustomFilledButton(
              text: 'View Active Store Branches',
              color: t.accent,
              onPressed: () => context.push(AppRoute.branchesScreen),
            ),
            12.verticalSpace,

            // Back Action Button
            CustomFilledButton(
              text: 'Back to More Options',
              onPressed: () => context.pop(),
            ),
            16.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required ThemeTokens t,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 18.w),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: getTextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              2.verticalSpace,
              Text(
                description,
                style: getTextStyle(
                  fontSize: 11.sp,
                  color: t.textSec,
                  lineHeight: 15.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
