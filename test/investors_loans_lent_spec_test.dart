import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:online_buiness_product_traker/core/models/investor_model.dart';
import 'package:online_buiness_product_traker/core/models/loan_model.dart';
import 'package:online_buiness_product_traker/core/models/receivable_model.dart';
import 'package:online_buiness_product_traker/core/services/database_service.dart';
import 'package:online_buiness_product_traker/core/services/theme_language_service.dart';
import 'package:online_buiness_product_traker/core/utils/sizer.dart';
import 'package:online_buiness_product_traker/features/owner_controls/screens/investor_management_screen.dart';
import 'package:online_buiness_product_traker/features/owner_controls/screens/loan_management_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Feature A: Investors (Spec Section 3 & 8)', () {
    final karim = Investor(
      id: 'INV-001',
      name: 'Karim Hossain',
      phone: '01711-111222',
      email: 'karim@example.com',
      investAmount: 50000,
      date: DateTime(2026, 1, 15),
      profitShare: 25.0,
      status: 'active',
      note: 'Silent partner',
      withdrawals: [
        InvestorSubRecord(
          id: 'WD-001',
          amount: 5000,
          date: DateTime(2026, 3, 1),
          note: 'Q1 profit payout',
        ),
      ],
      reinvestments: [],
    );

    final nasrin = Investor(
      id: 'INV-002',
      name: 'Nasrin Begum',
      phone: '01811-333444',
      email: '',
      investAmount: 30000,
      date: DateTime(2026, 2, 10),
      profitShare: 15.0,
      status: 'active',
      note: 'Equipment investor',
      withdrawals: [],
      reinvestments: [],
    );

    test('Section 8 Sample Data: Individual Investor Metrics', () {
      const netProfit = 7320.0;

      // Karim Hossain
      expect(karim.totalInvested, 50000.0);
      expect(karim.totalWithdrawn, 5000.0);
      expect(karim.netBalance, 45000.0);
      expect(karim.calculateProfitDue(netProfit), 1830.0);

      // Nasrin Begum
      expect(nasrin.totalInvested, 30000.0);
      expect(nasrin.totalWithdrawn, 0.0);
      expect(nasrin.netBalance, 30000.0);
      expect(nasrin.calculateProfitDue(netProfit), 1098.0);
    });

    test('Section 8 Sample Data: Aggregated Screen & Reports Totals', () {
      final investors = [karim, nasrin];
      const netProfit = 7320.0;

      final totalInvested = investors.fold(0.0, (sum, i) => sum + i.totalInvested);
      final totalWithdrawn = investors.fold(0.0, (sum, i) => sum + i.totalWithdrawn);
      final netActive = totalInvested - totalWithdrawn;
      final totalProfitDistributed = investors.fold(0.0, (sum, i) => sum + i.calculateProfitDue(netProfit));
      final ownerProfit = netProfit - totalProfitDistributed;

      expect(totalInvested, 80000.0);
      expect(totalWithdrawn, 5000.0);
      expect(netActive, 75000.0);
      expect(totalProfitDistributed, 2928.0);
      expect(ownerProfit, 4392.0);
    });

    test('Investor Re-investments update total invested and net balance', () {
      final updatedKarim = karim.copyWith(
        reinvestments: [
          InvestorSubRecord(
            id: 'RE-001',
            amount: 10000,
            date: DateTime(2026, 4, 1),
            note: 'Q2 reinvestment',
          ),
        ],
      );

      expect(updatedKarim.totalReinvested, 10000.0);
      expect(updatedKarim.totalInvested, 60000.0); // 50000 + 10000
      expect(updatedKarim.netBalance, 55000.0); // 60000 - 5000
    });
  });

  group('Feature B: Loans (Spec Section 4 & 8)', () {
    final loan1 = Loan(
      id: 'LN-001',
      lender: 'Dutch-Bangla Bank',
      type: 'bank',
      amount: 100000,
      remaining: 85000,
      interestRate: 12.0,
      startDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2027, 1, 1),
      monthlyPayment: 9000,
      purpose: 'Business expansion',
      status: 'active',
      payments: [
        LoanPaymentEntry(
          id: 'PMT-001',
          amount: 9000,
          date: DateTime(2026, 2, 1),
          note: 'January installment',
        ),
        LoanPaymentEntry(
          id: 'PMT-002',
          amount: 6000,
          date: DateTime(2026, 3, 1),
          note: 'February installment',
        ),
      ],
    );

    final loan2 = Loan(
      id: 'LN-002',
      lender: 'Rahim Mia',
      phone: '01711-999888',
      type: 'person',
      amount: 20000,
      remaining: 20000,
      interestRate: 0.0,
      startDate: DateTime(2026, 3, 15),
      dueDate: DateTime(2026, 9, 15),
      monthlyPayment: 0,
      purpose: 'Emergency stock purchase',
      status: 'active',
      payments: [],
    );

    test('Section 8 Sample Data: Loans Aggregated Metrics', () {
      final loans = [loan1, loan2];

      final totalBorrowed = loans.fold(0.0, (sum, l) => sum + l.amount);
      final stillOwed = loans.fold(0.0, (sum, l) => sum + l.remaining);
      final paidBack = totalBorrowed - stillOwed;

      expect(totalBorrowed, 120000.0);
      expect(stillOwed, 105000.0);
      expect(paidBack, 15000.0);
      expect(loan1.paidPercentage, 15.0); // 15,000 / 100,000 * 100
      expect(loan2.paidPercentage, 0.0);
    });

    test('Add Loan estimated yearly interest hint formula', () {
      // 100,000 at 12% = 12,000 per year
      final yearlyInterest = loan1.amount * loan1.interestRate / 100.0;
      expect(yearlyInterest, 12000.0);
    });

    test('Loan state transitions: Payment, Clear, Reopen', () {
      // Payment reduces remaining
      final payment = LoanPaymentEntry(
        id: 'PMT-003',
        amount: 85000,
        date: DateTime(2026, 4, 1),
      );
      final remainingAfter = (loan1.remaining - payment.amount).clamp(0.0, double.infinity);
      final clearedLoan = loan1.copyWith(
        remaining: remainingAfter,
        status: remainingAfter <= 0 ? 'cleared' : 'active',
      );
      expect(clearedLoan.remaining, 0.0);
      expect(clearedLoan.isCleared, isTrue);

      // Reopen restores full amount
      final reopenedLoan = clearedLoan.copyWith(
        status: 'active',
        remaining: clearedLoan.amount,
      );
      expect(reopenedLoan.remaining, 100000.0);
      expect(reopenedLoan.isCleared, isFalse);
    });
  });

  group('Feature C: Money Lent (Spec Section 5 & 8)', () {
    final lent1 = Receivable(
      id: 'LT-001',
      person: 'Sabbir Ahmed',
      phone: '01611-222333',
      amount: 5000,
      remaining: 3000,
      date: DateTime(2026, 5, 1),
      dueDate: DateTime(2026, 8, 1),
      reason: 'Medical emergency help',
      status: 'partially_returned',
      returns: [
        MoneyLentReturnEntry(
          id: 'RT-001',
          amount: 2000,
          date: DateTime(2026, 6, 1),
          note: 'First return',
        ),
      ],
    );

    final lent2 = Receivable(
      id: 'LT-002',
      person: 'Fatema Khanam',
      phone: '01911-444555',
      amount: 2000,
      remaining: 2000,
      date: DateTime(2026, 7, 10),
      dueDate: DateTime(2026, 9, 10),
      reason: 'Shop rent help',
      status: 'pending',
      returns: [],
    );

    test('Section 8 Sample Data: Money Lent Aggregated Metrics', () {
      final records = [lent1, lent2];

      final totalLent = records.fold(0.0, (sum, r) => sum + r.amount);
      final stillOut = records.fold(0.0, (sum, r) => sum + r.remaining);
      final returned = records.fold(0.0, (sum, r) => sum + r.totalReturned);

      expect(totalLent, 7000.0);
      expect(stillOut, 5000.0);
      expect(returned, 2000.0);
      expect(lent1.returnedPercentage, 40.0); // 2000 / 5000 = 40%
      expect(lent2.returnedPercentage, 0.0);
    });

    test('State transitions: Return payment, Mark returned, Reopen', () {
      // Record Return
      final returnEntry = MoneyLentReturnEntry(
        id: 'RT-002',
        amount: 3000,
        date: DateTime(2026, 8, 1),
      );
      final remainingAfter = (lent1.remaining - returnEntry.amount).clamp(0.0, double.infinity);
      final fullyReturned = lent1.copyWith(
        remaining: remainingAfter,
        status: remainingAfter <= 0 ? 'returned' : 'partially_returned',
        returns: [returnEntry, ...lent1.returns],
      );

      expect(fullyReturned.remaining, 0.0);
      expect(fullyReturned.isReturned, isTrue);
      expect(fullyReturned.totalReturned, 5000.0);
      expect(fullyReturned.returnedPercentage, 100.0);

      // Reopen restores to pending and full original amount
      final reopened = fullyReturned.copyWith(
        status: 'pending',
        remaining: fullyReturned.amount,
      );
      expect(reopened.status, 'pending');
      expect(reopened.remaining, 5000.0);
    });
  });

  group('Modal BottomSheet Tap & Render Tests', () {
    testWidgets('InvestorManagementScreen header + button opens Add Investor sheet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.put(ThemeLanguageService());
      Get.put(DatabaseService());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              Sizer.init(context);
              return const InvestorManagementScreen();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the add icon in the header
      final addIcon = find.byIcon(Icons.add_rounded);
      expect(addIcon, findsOneWidget);

      // Tap + button
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      // Verify "Add Investor" modal bottom sheet is open
      expect(find.text('Add Investor'), findsWidgets);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Investment Amount *'), findsOneWidget);

      // Tap close button on sheet
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Verify sheet closed
      expect(find.text('Full Name *'), findsNothing);
    });

    testWidgets('LoanManagementScreen header + button opens Add Loan sheet', (tester) async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.put(ThemeLanguageService());
      Get.put(DatabaseService());

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              Sizer.init(context);
              return const LoanManagementScreen();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addIcon = find.byIcon(Icons.add_rounded);
      expect(addIcon, findsOneWidget);

      // Tap + button
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      // Verify "🏦 Add Loan" modal bottom sheet is open
      expect(find.text('🏦 Add Loan'), findsWidgets);
      expect(find.text('🏦 Bank'), findsWidgets);
      expect(find.text('👤 Person'), findsWidgets);

      // Tap close button on sheet
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      // Verify sheet closed
      expect(find.text('Loan Type'), findsNothing);
    });
  });
}
