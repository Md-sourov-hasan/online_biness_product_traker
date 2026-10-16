import 'package:get/get.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/report_export_service.dart';

class ReportsController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();
  final ReportExportService exportService = Get.find<ReportExportService>();

  final RxString selectedReportType = 'sales'.obs; // 'sales', 'inventory', 'expenses', 'pl'
  final RxString selectedPeriod = 'all'.obs; // 'all', 'today', 'week', 'month'

  Future<void> exportPdf() async {
    if (selectedReportType.value == 'sales') {
      await exportService.exportSalesReportPdf(period: selectedPeriod.value);
    } else if (selectedReportType.value == 'inventory') {
      await exportService.exportInventoryReportPdf();
    } else {
      await exportService.exportProfitLossReportPdf();
    }
  }

  Future<void> exportCsv() async {
    if (selectedReportType.value == 'inventory') {
      await exportService.exportInventoryToCsv();
    } else {
      await exportService.exportSalesToCsv();
    }
  }
}
