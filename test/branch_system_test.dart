import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_buiness_product_traker/core/models/branch_model.dart';
import 'package:online_buiness_product_traker/core/models/product_model.dart';
import 'package:online_buiness_product_traker/core/services/database_service.dart';
import 'package:online_buiness_product_traker/core/services/theme_language_service.dart';
import 'package:online_buiness_product_traker/core/utils/sizer.dart';
import 'package:online_buiness_product_traker/features/branches/screens/branch_management_screen.dart';
import 'package:online_buiness_product_traker/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Branch Model & Serialization Tests', () {
    test('Branch model initializes correctly and serializes to/from map', () {
      final branch = Branch(
        id: 'branch_bonani',
        name: 'Bonani',
        banglaName: 'বনানী',
        address: 'Road 11, Banani, Dhaka',
        managerName: 'Tanvir Ahmed',
        managerPhone: '+880 1711-234501',
        email: 'bonani@stockmate.com',
        colorValue: 0xFF2563EB,
      );

      expect(branch.name, equals('Bonani'));
      expect(branch.banglaName, equals('বনানী'));
      expect(branch.isActive, isTrue);

      final map = branch.toMap();
      expect(map['name'], equals('Bonani'));
      expect(map['address'], equals('Road 11, Banani, Dhaka'));

      final fromMap = Branch.fromMap(map, 'branch_bonani');
      expect(fromMap.name, equals('Bonani'));
      expect(fromMap.banglaName, equals('বনানী'));
      expect(fromMap.colorValue, equals(0xFF2563EB));
    });

    test('Product model supports branchName field with default fallback', () {
      final p1 = Product(
        id: 'p1',
        brandName: 'Samsung',
        catalogName: 'Galaxy Buds Pro',
        productCode: 'SM-8091',
        quantity: 20,
        pricePerPiece: 8500,
        branchName: 'Gulshan',
      );

      expect(p1.branchName, equals('Gulshan'));
      expect(p1.branch, equals('Gulshan'));

      final map = p1.toMap();
      expect(map['branchName'], equals('Gulshan'));

      final fromMap = Product.fromMap(map, 'p1');
      expect(fromMap.branchName, equals('Gulshan'));

      // CopyWith test
      final copied = p1.copyWith(branchName: 'Savar', quantity: 15);
      expect(copied.branchName, equals('Savar'));
      expect(copied.quantity, equals(15));
    });
  });

  group('Multi-Branch Database & Transfer Tests', () {
    late DatabaseService db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      db = DatabaseService();
      Get.put(db);
      await db.loadFromLocal();
    });

    test('Initializes with the 5 required branches: Bonani, Gulshan, Nikunjo, Jamgora, Savar', () {
      final branchNames = db.branches.map((b) => b.name.toLowerCase()).toList();
      expect(branchNames, contains('bonani'));
      expect(branchNames, contains('gulshan'));
      expect(branchNames, contains('nikunjo'));
      expect(branchNames, contains('jamgora'));
      expect(branchNames, contains('savar'));
      expect(db.branches.length, greaterThanOrEqualTo(5));
    });

    test('Each of the 5 branches has products and computes accurate metrics', () {
      for (final bName in ['Bonani', 'Gulshan', 'Nikunjo', 'Jamgora', 'Savar']) {
        final units = db.getBranchUnitStocks(bName);
        final valuation = db.getBranchValuation(bName);
        final skus = db.getBranchSkus(bName);
        final products = db.getBranchProducts(bName);

        expect(units, greaterThan(0), reason: '$bName should have stock units');
        expect(valuation, greaterThan(0), reason: '$bName should have asset valuation');
        expect(skus, greaterThan(0), reason: '$bName should have SKUs');
        expect(products.isNotEmpty, isTrue);
      }
    });

    test('Stock transfer between branches correctly adjusts quantities', () {
      // Find a product in Bonani
      final bonaniProducts = db.getBranchProducts('Bonani');
      expect(bonaniProducts.isNotEmpty, isTrue);
      final productToTransfer = bonaniProducts.first;
      final initialBonaniQty = productToTransfer.quantity;
      final initialGulshanUnits = db.getBranchUnitStocks('Gulshan');

      const transferQty = 5;
      expect(initialBonaniQty, greaterThanOrEqualTo(transferQty));

      final success = db.transferStock(
        productId: productToTransfer.id,
        targetBranch: 'Gulshan',
        transferQty: transferQty,
      );

      expect(success, isTrue);

      // Verify Bonani quantity reduced
      final updatedBonaniProduct = db.products.firstWhere((p) => p.id == productToTransfer.id);
      expect(updatedBonaniProduct.quantity, equals(initialBonaniQty - transferQty));

      // Verify Gulshan units increased
      final updatedGulshanUnits = db.getBranchUnitStocks('Gulshan');
      expect(updatedGulshanUnits, equals(initialGulshanUnits + transferQty));

      // Verify activity log recorded
      expect(db.activityLogs.first.type, equals('transfer'));
      expect(db.activityLogs.first.description, contains('Bonani'));
      expect(db.activityLogs.first.description, contains('Gulshan'));
    });
  });

  group('Branch Management Screen Tests', () {
    testWidgets('BranchManagementScreen renders Coming Soon banner and planned features', (tester) async {
      SharedPreferences.setMockInitialValues({});
      if (!Get.isRegistered<ThemeLanguageService>()) {
        Get.put(ThemeLanguageService());
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              Sizer.init(context);
              return const BranchManagementScreen();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Branch Management'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Branch Management Module'), findsOneWidget);
      expect(find.text('Planned Features in Next Release'), findsOneWidget);
      expect(find.text('Back to More Options'), findsOneWidget);
    });

    test('AppRoute defines branchManagementScreen route constant', () {
      expect(AppRoute.branchManagementScreen, equals('/branch-management'));
    });
  });
}
