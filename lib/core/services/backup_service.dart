import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/purchase_model.dart';
import '../models/expense_model.dart';
import 'database_service.dart';

class BackupService extends GetxService {
  static BackupService get to => Get.find<BackupService>();

  final DatabaseService db = Get.find<DatabaseService>();

  Future<String> generateBackupJson() async {
    final payload = {
      'version': '1.0.0',
      'appName': 'StockMate',
      'exportedAt': DateTime.now().toIso8601String(),
      'products': db.products.map((p) => p.toMap()).toList(),
      'sales': db.sales.map((s) => s.toMap()).toList(),
      'purchases': db.purchases.map((p) => p.toMap()).toList(),
      'expenses': db.expenses.map((e) => e.toMap()).toList(),
      'logs': db.activityLogs.map((l) => l.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> exportAndShareBackup() async {
    try {
      final jsonContent = await generateBackupJson();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'stockmate_backup_$dateStr.json';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(jsonContent);

      await Share.shareXFiles([XFile(file.path)], text: 'StockMate Database Backup ($dateStr)');
      db.logActivity('backup', 'Backup Exported', 'Full system backup exported ($filename)');
      Get.snackbar('Success', 'Backup created and ready for download/share', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Error generating backup: $e');
      Get.snackbar('Error', 'Failed to generate backup: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  bool restoreFromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      if (data['appName'] != 'StockMate' && !data.containsKey('products')) {
        Get.snackbar('Invalid File', 'This file is not a valid StockMate backup', snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      if (data['products'] != null) {
        final List<dynamic> pList = data['products'];
        db.products.assignAll(pList.map((m) => Product.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
      }

      if (data['sales'] != null) {
        final List<dynamic> sList = data['sales'];
        db.sales.assignAll(sList.map((m) => Sale.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
      }

      if (data['purchases'] != null) {
        final List<dynamic> pList = data['purchases'];
        db.purchases.assignAll(pList.map((m) => Purchase.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
      }

      if (data['expenses'] != null) {
        final List<dynamic> eList = data['expenses'];
        db.expenses.assignAll(eList.map((m) => Expense.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList());
      }

      db.saveToLocal();
      db.logActivity('backup', 'Backup Restored', 'System restored from backup JSON file.');
      Get.snackbar('Restore Complete', 'All products, sales, and expenses restored successfully', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      Get.snackbar('Error', 'Failed to restore backup: $e', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }
}
