import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/orders_controller.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';
import '../../../core/common/widgets/stockmate_components.dart';
import '../../../core/services/theme_language_service.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrdersController controller = Get.put(OrdersController());
    final ThemeLanguageService theme = Get.find<ThemeLanguageService>();

    return Obx(() {
      final t = theme.t;

      return CommonBackgroundScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Orders',
            style: getTextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
        ),
        body: controller.orders.isEmpty
            ? StockMateEmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No orders yet',
                description: 'Orders placed will appear here with full delivery tracking.',
                t: t,
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                itemCount: controller.orders.length,
                separatorBuilder: (context, index) => 12.verticalSpace,
                itemBuilder: (context, index) {
                  final order = controller.orders[index];
                  final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);
                  final isDelivered = order.status.toLowerCase() == 'delivered';
                  final badgeColor = isDelivered ? t.success : t.warning;

                  return Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: t.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: t.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${order.id.length > 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                              style: getTextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: t.accent,
                              ),
                            ),
                            StockMateBadge(
                              label: order.status.toUpperCase(),
                              color: badgeColor,
                              isSmall: true,
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        Text(
                          order.customerName,
                          style: getTextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                        4.verticalSpace,
                        Text(
                          '${order.items.length} items • $dateStr',
                          style: getTextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: t.textSec,
                          ),
                        ),
                        12.verticalSpace,
                        Divider(color: t.border, height: 1),
                        10.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: getTextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: t.textSec,
                              ),
                            ),
                            Text(
                              '৳${order.totalAmount.toStringAsFixed(2)}',
                              style: getTextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    });
  }
}
