import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../routes/app_routes.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationsController controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
    final AuthService auth = Get.find<AuthService>();

    return CommonBackgroundScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, controller, themeService),
            _buildFilterTabs(controller, themeService),
            Expanded(
              child: Obx(() {
                final items = controller.currentUserNotifications;
                final isStaff = auth.currentUser.value?.isStaff ?? false;

                if (items.isEmpty) {
                  return _buildEmptyState(themeService);
                }

                return RefreshIndicator(
                  onRefresh: () async => controller.refreshAll(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => 10.verticalSpace,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildNotificationCard(
                        context,
                        item,
                        controller,
                        themeService,
                        isStaff: isStaff,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header / App Bar with Settings Gear (Spec Section 5) ---
  Widget _buildAppBar(
    BuildContext context,
    NotificationsController controller,
    ThemeLanguageService themeService,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeService.t.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16.w,
                    color: themeService.textColor,
                  ),
                ),
              ),
              12.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notifications',
                        style: getTextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: themeService.textColor,
                        ),
                      ),
                      8.horizontalSpace,
                      Obx(() {
                        final unread = controller.unreadCount;
                        if (unread == 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$unread new',
                            style: getTextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  2.verticalSpace,
                  Text(
                    'Real-time alerts, stock & activities',
                    style: getTextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: themeService.subtextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Settings Gear Button on inbox header (Spec Section 5)
              GestureDetector(
                onTap: () => context.push(AppRoute.notificationSettingsScreen),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: themeService.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeService.t.border),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 18.w,
                    color: themeService.textColor,
                  ),
                ),
              ),
              8.horizontalSpace,
              // Overflow Menu for inbox actions
              Obx(() {
                final hasUnread = controller.unreadCount > 0;
                return PopupMenuButton<String>(
                  color: themeService.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: themeService.t.border),
                  ),
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: themeService.t.border),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18.w,
                      color: themeService.textColor,
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'mark_read') {
                      controller.markAllAsRead();
                      Get.snackbar(
                        'Notifications',
                        'All notifications marked as read',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else if (val == 'clear_all') {
                      controller.clearAll();
                      Get.snackbar(
                        'Notifications',
                        'All notifications cleared',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else if (val == 'settings') {
                      context.push(AppRoute.notificationSettingsScreen);
                    }
                  },
                  itemBuilder: (context) => [
                    if (hasUnread)
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 16.w,
                              color: AppColors.primary,
                            ),
                            8.horizontalSpace,
                            Text(
                              'Mark all as read',
                              style: getTextStyle(
                                fontSize: 12.sp,
                                color: themeService.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: 16.w,
                            color: AppColors.error,
                          ),
                          8.horizontalSpace,
                          Text(
                            'Clear all',
                            style: getTextStyle(
                              fontSize: 12.sp,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16.w,
                            color: AppColors.primary,
                          ),
                          8.horizontalSpace,
                          Text(
                            'Settings',
                            style: getTextStyle(
                              fontSize: 12.sp,
                              color: themeService.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // --- Filter Tabs ---
  Widget _buildFilterTabs(
    NotificationsController controller,
    ThemeLanguageService themeService,
  ) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'alerts', 'label': 'Alerts'},
      {'key': 'pending', 'label': 'Approvals'},
      {'key': 'activity', 'label': 'Activity'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Obx(() {
        final current = controller.selectedFilter.value;
        return Row(
          children: filters.map((f) {
            final isSelected = current == f['key'];
            return GestureDetector(
              onTap: () => controller.selectedFilter.value = f['key']!,
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : themeService.cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : themeService.t.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f['label']!,
                  style: getTextStyle(
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : themeService.subtextColor,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  // --- Notification Card ---
  Widget _buildNotificationCard(
    BuildContext context,
    AppNotificationItem item,
    NotificationsController controller,
    ThemeLanguageService themeService, {
    required bool isStaff,
  }) {
    final IconData iconData;
    final Color iconColor;
    final Color iconBgColor;

    switch (item.type) {
      case NotificationType.lowStock:
      case NotificationType.stock:
        iconData = Icons.warning_amber_rounded;
        iconColor = AppColors.error;
        iconBgColor = AppColors.error.withValues(alpha: 0.12);
        break;
      case NotificationType.pendingApproval:
      case NotificationType.userSecurity:
        iconData = Icons.person_pin_circle_outlined;
        iconColor = AppColors.warning;
        iconBgColor = AppColors.warning.withValues(alpha: 0.12);
        break;
      case NotificationType.receivableDue:
      case NotificationType.money:
      case NotificationType.moneyLent:
      case NotificationType.investor:
        iconData = Icons.receipt_long_rounded;
        iconColor = Colors.orange;
        iconBgColor = Colors.orange.withValues(alpha: 0.12);
        break;
      case NotificationType.sale:
        iconData = Icons.shopping_bag_outlined;
        iconColor = AppColors.secondary;
        iconBgColor = AppColors.secondary.withValues(alpha: 0.12);
        break;
      case NotificationType.discount:
        iconData = Icons.discount_outlined;
        iconColor = AppColors.purple;
        iconBgColor = AppColors.purple.withValues(alpha: 0.12);
        break;
      case NotificationType.expense:
        iconData = Icons.payments_outlined;
        iconColor = Colors.deepOrangeAccent;
        iconBgColor = Colors.deepOrangeAccent.withValues(alpha: 0.12);
        break;
      case NotificationType.purchase:
        iconData = Icons.local_shipping_outlined;
        iconColor = Colors.teal;
        iconBgColor = Colors.teal.withValues(alpha: 0.12);
        break;
      case NotificationType.refund:
      case NotificationType.exchange:
        iconData = Icons.replay_rounded;
        iconColor = Colors.amber;
        iconBgColor = Colors.amber.withValues(alpha: 0.12);
        break;
      case NotificationType.supplier:
        iconData = Icons.storefront_outlined;
        iconColor = Colors.blueGrey;
        iconBgColor = Colors.blueGrey.withValues(alpha: 0.12);
        break;
      case NotificationType.system:
      case NotificationType.activityLog:
        iconData = Icons.notifications_active_outlined;
        iconColor = AppColors.primary;
        iconBgColor = AppColors.primary.withValues(alpha: 0.12);
        break;
    }

    final timeString = _formatTimeAgo(item.timestamp);

    // Sanitize message for Staff: Staff must never see profit or purchase cost!
    String displayMessage = item.message;
    if (isStaff && displayMessage.toLowerCase().contains('profit')) {
      displayMessage = displayMessage.replaceAll(RegExp(r'\(Profit: [^\)]+\)'), '');
      displayMessage = displayMessage.replaceAll(RegExp(r'Profit: [^\s•,]+'), '');
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.dismissNotification(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismiss',
              style: getTextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            8.horizontalSpace,
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20.w),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          controller.markAsRead(item.id);
          if (item.route != null) {
            context.push(item.route!, extra: item.routeExtra);
          }
        },
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: themeService.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: !item.isRead
                  ? iconColor.withValues(alpha: 0.45)
                  : themeService.t.border,
              width: !item.isRead ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 18.w, color: iconColor),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Code Badge & Title
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  item.code,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                              6.horizontalSpace,
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: getTextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: !item.isRead
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: themeService.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!item.isRead) ...[
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          6.horizontalSpace,
                        ],
                      ],
                    ),
                    4.verticalSpace,
                    Text(
                      displayMessage,
                      style: getTextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: themeService.subtextColor,
                      ),
                    ),
                    8.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeString,
                          style: getTextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: themeService.textMutedColor,
                          ),
                        ),
                        Row(
                          children: [
                            if (!item.isRead)
                              GestureDetector(
                                onTap: () => controller.markAsRead(item.id),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                                  child: Icon(Icons.done_rounded, size: 14.w, color: themeService.subtextColor),
                                ),
                              ),
                            if (item.route != null) ...[
                              GestureDetector(
                                onTap: () {
                                  controller.markAsRead(item.id);
                                  context.push(item.route!, extra: item.routeExtra);
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'View',
                                      style: getTextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    2.horizontalSpace,
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10.w,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState(ThemeLanguageService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48.w,
              color: AppColors.primary,
            ),
          ),
          16.verticalSpace,
          Text(
            'All caught up!',
            style: getTextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: themeService.textColor,
            ),
          ),
          6.verticalSpace,
          Text(
            'No notifications in this filter.',
            style: getTextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: themeService.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
