import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/database_service.dart';

class DashboardController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();

  // 5-second rotation state
  final RxInt salesRotationIndex = 0.obs; // 0: Today, 1: Week, 2: Month
  final RxInt profitRotationIndex = 0.obs; // 0: Today, 1: Week, 2: Month

  Timer? _rotationTimer;

  final List<String> periods = ['today', 'week', 'month'];
  final List<String> periodLabels = ['sales_today', 'sales_this_week', 'sales_this_month'];
  final List<String> profitLabels = ['profit_today', 'profit_this_week', 'profit_this_month'];

  @override
  void onInit() {
    super.onInit();
    _start5SecondRotation();
  }

  void _start5SecondRotation() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      salesRotationIndex.value = (salesRotationIndex.value + 1) % 3;
      profitRotationIndex.value = (profitRotationIndex.value + 1) % 3;
    });
  }

  void cycleSalesRotation() {
    salesRotationIndex.value = (salesRotationIndex.value + 1) % 3;
  }

  void cycleProfitRotation() {
    profitRotationIndex.value = (profitRotationIndex.value + 1) % 3;
  }

  String get currentSalesPeriod => periods[salesRotationIndex.value];
  String get currentSalesLabelKey => periodLabels[salesRotationIndex.value];
  double get currentPeriodSales => db.getSalesForPeriod(currentSalesPeriod);

  String get currentProfitPeriod => periods[profitRotationIndex.value];
  String get currentProfitLabelKey => profitLabels[profitRotationIndex.value];
  double get currentPeriodProfit => db.getProfitForPeriod(currentProfitPeriod);

  @override
  void onClose() {
    _rotationTimer?.cancel();
    super.onClose();
  }
}
