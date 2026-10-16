import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/models/supplier_model.dart';
import '../../../core/utils/constants/colors.dart';
import '../../../core/utils/sizer.dart';
import '../../../core/common/styles/global_text_style.dart';
import '../../../core/common/widgets/common_background.dart';

class SupplierManagementScreen extends StatelessWidget {
  const SupplierManagementScreen({super.key});

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
              child: Obx(() {
                final suppliers = db.suppliers;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Suppliers (${suppliers.length})',
                            style: getTextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddSupplierDialog(context, db, theme),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Supplier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                          ),
                        ],
                      ),
                      14.verticalSpace,

                      if (suppliers.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.h),
                            child: Column(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 48, color: theme.subtextColor),
                                12.verticalSpace,
                                Text('No suppliers recorded.', style: TextStyle(color: theme.subtextColor)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: suppliers.length,
                          separatorBuilder: (context, index) => 10.verticalSpace,
                          itemBuilder: (context, index) {
                            final sup = suppliers[index];
                            final supplyCount = db.purchases.where((p) => p.supplier == sup.name).length;
                            return _buildSupplierCard(context, db, theme, sup, supplyCount);
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
                  'Supplier Directory',
                  style: getTextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: theme.textColor),
                ),
                Text(
                  'Manager & Owner • Procurement Vendors & History',
                  style: getTextStyle(fontSize: 11.sp, color: theme.subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    DatabaseService db,
    ThemeLanguageService theme,
    Supplier sup,
    int supplyCount,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.inputBorderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(sup.name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: theme.textColor)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text('$supplyCount Orders', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
          8.verticalSpace,
          if (sup.contactPhone.isNotEmpty)
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: theme.subtextColor),
                6.horizontalSpace,
                Text(sup.contactPhone, style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              ],
            ),
          if (sup.email.isNotEmpty) ...[
            4.verticalSpace,
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: theme.subtextColor),
                6.horizontalSpace,
                Text(sup.email, style: TextStyle(fontSize: 12.sp, color: theme.subtextColor)),
              ],
            ),
          ],
          if (sup.address.isNotEmpty) ...[
            4.verticalSpace,
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: theme.subtextColor),
                6.horizontalSpace,
                Expanded(child: Text(sup.address, style: TextStyle(fontSize: 12.sp, color: theme.subtextColor))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context, DatabaseService db, ThemeLanguageService theme) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Add New Supplier', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Company Name (Required)'),
              ),
              8.verticalSpace,
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone Number'),
              ),
              8.verticalSpace,
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              8.verticalSpace,
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Physical Address / Hub'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              db.addSupplier(Supplier(
                id: const Uuid().v4(),
                name: name,
                contactPhone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              Get.snackbar('Supplier Added', '$name recorded in directory.', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }
}
