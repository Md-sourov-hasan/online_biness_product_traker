import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/custom_text_field.dart';
import '../../../core/common/widgets/customize_filled_button.dart';
import '../../../core/common/widgets/theme_selection_bottom_sheet.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/theme/stockmate_theme.dart';
import '../../../core/utils/constants/app_constants.dart';
import '../../../core/utils/sizer.dart';
import '../controllers/login_controller.dart';
import '../widgets/role_selection_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());
    final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = theme.t;
      final isDark = theme.isDark;

      return Scaffold(
        backgroundColor: t.bg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      t.bg,
                      t.surfaceAlt.withValues(alpha: 0.6),
                      t.bg,
                    ]
                  : [
                      t.bg,
                      t.surfaceAlt,
                      t.bg,
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(context, theme, t, isDark),
                  14.verticalSpace,
                  _buildBrandHeader(t),
                  20.verticalSpace,
                  _buildRoleSelectionCards(controller, t),
                  18.verticalSpace,
                  _buildCustomCredentialsToggle(controller, t),
                  Obx(() {
                    if (!controller.showCustomInput.value) return const SizedBox.shrink();
                    return _buildCustomCredentialsInputs(controller, t);
                  }),
                  20.verticalSpace,
                  _buildActionButton(context, controller, t),
                  14.verticalSpace,
                  _buildSecurityFooter(t),
                  16.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeLanguageService theme,
    ThemeTokens t,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.success,
                ),
              ),
              6.horizontalSpace,
              Text(
                'STOCKMATE ERP',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: t.textSec,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                theme.toggleDarkMode();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: t.border),
                  boxShadow: [
                    BoxShadow(
                      color: t.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDark ? '🌙' : '☀️',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    4.horizontalSpace,
                    Text(
                      isDark ? 'Dark' : 'Light',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            8.horizontalSpace,
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ThemeSelectionBottomSheet.show(context);
              },
              child: Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: t.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: t.accent,
                  size: 18.w,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrandHeader(ThemeTokens t) {
    return Column(
      children: [
        Container(
          width: 68.w,
          height: 68.w,
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: t.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 36.w),
        ),
        14.verticalSpace,
        Text(
          AppConstants.appName,
          style: getTextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: t.text,
          ),
        ),
        4.verticalSpace,
        Text(
          'Select your role to access your dedicated workspace',
          textAlign: TextAlign.center,
          style: getTextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: t.textSec,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelectionCards(LoginController controller, ThemeTokens t) {
    return Obx(() {
      return Column(
        children: controller.roleConfigs.map((config) {
          final isSelected = controller.selectedRole.value == config.role;
          final accent = config.customAccent ?? t.accent;

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: RoleSelectionCard(
              t: t,
              title: config.title,
              badge: config.badge,
              description: config.description,
              icon: config.icon,
              accentColor: accent,
              isSelected: isSelected,
              onTap: () => controller.selectRole(config.role),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCustomCredentialsToggle(LoginController controller, ThemeTokens t) {
    return GestureDetector(
      onTap: controller.toggleCustomInput,
      child: Obx(() {
        final isVisible = controller.showCustomInput.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: t.textMuted,
              size: 18.w,
            ),
            4.horizontalSpace,
            Text(
              isVisible ? 'Hide credentials' : 'Edit session name & email',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: t.textSec,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCustomCredentialsInputs(LoginController controller, ThemeTokens t) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextField(
            hintText: 'Full Name',
            controller: controller.nameController,
          ),
          10.verticalSpace,
          CustomTextField(
            hintText: 'Email Address',
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, LoginController controller, ThemeTokens t) {
    return Obx(() {
      return CustomFilledButton(
        text: 'Enter Dashboard as ${controller.roleDisplayShort}',
        color: t.accent,
        isLoading: controller.isLoading.value,
        onPressed: () => controller.proceedToDashboard(context),
      );
    });
  }

  Widget _buildSecurityFooter(ThemeTokens t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14.w, color: t.textMuted),
        6.horizontalSpace,
        Flexible(
          child: Text(
            'End-to-End Capability Enforced • Role-Based Access Control',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.sp, color: t.textMuted),
          ),
        ),
      ],
    );
  }
}
