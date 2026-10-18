import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final DatabaseService db = Get.find<DatabaseService>();
  final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
  final RxString selectedTypeFilter = 'all'.obs;
  final TextEditingController searchController = TextEditingController();
  final RxString searchFilter = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonBackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'activity_logs'.tr,
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
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (v) => searchFilter.value = v,
                  style: TextStyle(color: themeService.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search activity logs...',
                    hintStyle: TextStyle(color: themeService.subtextColor),
                    prefixIcon: Icon(Icons.search, color: themeService.subtextColor),
                    filled: true,
                    fillColor: themeService.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: themeService.inputBorderColor)),
                    isDense: true,
                  ),
                ),
                8.verticalSpace,
                // Type Filter Chips
                SizedBox(
                  height: 32.h,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildTypePill('All', 'all'),
                      _buildTypePill('Sales', 'sale'),
                      _buildTypePill('Purchases', 'purchase'),
                      _buildTypePill('Expenses', 'expense'),
                      _buildTypePill('Products', 'product'),
                      _buildTypePill('Backup & Sync', 'backup'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          10.verticalSpace,

          // Logs List
          Expanded(
            child: Obx(() {
              final logs = db.activityLogs.where((l) {
                final matchesType = selectedTypeFilter.value == 'all' || l.type.contains(selectedTypeFilter.value);
                final matchesSearch = searchFilter.value.isEmpty ||
                    l.title.toLowerCase().contains(searchFilter.value.toLowerCase()) ||
                    l.description.toLowerCase().contains(searchFilter.value.toLowerCase());
                return matchesType && matchesSearch;
              }).toList();

              if (logs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 48.w, color: themeService.subtextColor),
                        12.verticalSpace,
                        Text('No activity logs found.', style: TextStyle(color: themeService.subtextColor, fontSize: 14.sp)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: logs.length,
                separatorBuilder: (c, i) => 10.verticalSpace,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  IconData icon;
                  Color iconColor;

                  switch (log.type) {
                    case 'sale':
                      icon = Icons.shopping_bag_rounded;
                      iconColor = AppColors.secondary;
                      break;
                    case 'purchase':
                      icon = Icons.add_business_rounded;
                      iconColor = AppColors.primary;
                      break;
                    case 'expense':
                      icon = Icons.receipt_rounded;
                      iconColor = AppColors.error;
                      break;
                    case 'backup':
                      icon = Icons.cloud_sync_rounded;
                      iconColor = AppColors.info;
                      break;
                    default:
                      icon = Icons.inventory_2_rounded;
                      iconColor = AppColors.warning;
                  }

                  final dateStr = DateFormat('dd MMM yyyy • hh:mm:ss a').format(log.timestamp);

                  return Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: themeService.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(icon, color: iconColor, size: 20.w),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: getTextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: themeService.textColor),
                                    ),
                                  ),
                                  8.horizontalSpace,
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      log.type.toUpperCase(),
                                      style: TextStyle(color: iconColor, fontSize: 9.sp, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              4.verticalSpace,
                              Text(
                                log.description,
                                style: getTextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: themeService.textColor),
                              ),
                              6.verticalSpace,
                              Text(
                                dateStr,
                                style: getTextStyle(fontSize: 10.sp, fontWeight: FontWeight.w400, color: themeService.subtextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTypePill(String title, String value) {
    return Obx(() {
      final isSelected = selectedTypeFilter.value == value;
      return GestureDetector(
        onTap: () => selectedTypeFilter.value = value,
        child: Container(
          margin: EdgeInsets.only(right: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : themeService.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isSelected ? AppColors.primary : themeService.inputBorderColor),
          ),
          child: Center(
            child: Text(
              title,
              style: getTextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : themeService.textColor,
              ),
            ),
          ),
        ),
      );
    });
  }
}
