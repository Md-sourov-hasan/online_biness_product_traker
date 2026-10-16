import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'database_service.dart';

class ReportExportService extends GetxService {
  static ReportExportService get to => Get.find<ReportExportService>();

  final DatabaseService db = Get.find<DatabaseService>();

  // --- PDF Export Generators ---

  Future<void> exportSalesReportPdf({String period = 'All'}) async {
    final pdf = pw.Document();
    final salesList = db.sales;
    final totalRev = salesList.fold(0.0, (sum, s) => sum + s.totalPrice);
    final totalProfit = salesList.fold(0.0, (sum, s) => sum + s.profit);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('StockMate - Sales & Revenue Report', period),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryBox('Total Sales Count', '${salesList.length} Orders'),
              _buildSummaryBox('Total Revenue', 'BDT ${totalRev.toStringAsFixed(2)}'),
              _buildSummaryBox('Total Net Profit', 'BDT ${totalProfit.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Sales Transactions', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Product', 'Code', 'Qty', 'Unit Price', 'Total', 'Profit'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            data: salesList.map((s) => [
              DateFormat('dd/MM/yy').format(s.timestamp),
              s.productName,
              s.productCode,
              s.quantity.toString(),
              s.unitPrice.toStringAsFixed(0),
              s.totalPrice.toStringAsFixed(0),
              s.profit.toStringAsFixed(0),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'StockMate_Sales_Report.pdf');
  }

  Future<void> exportInventoryReportPdf() async {
    final pdf = pw.Document();
    final products = db.products;
    final totalPieces = db.totalStockPieces;
    final totalValuation = db.totalStockValuation;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('StockMate - Inventory & Stock Valuation Report', 'Current Stock'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryBox('Total Catalog Items', '${products.length} Products'),
              _buildSummaryBox('Total Stock Pieces', '$totalPieces Units'),
              _buildSummaryBox('Total Inventory Value', 'BDT ${totalValuation.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Brand', 'Catalog Name', 'Code', 'Cost/pc', 'Quantity', 'Valuation', 'Status'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            data: products.map((p) => [
              p.brandName,
              p.catalogName,
              p.productCode,
              p.pricePerPiece.toStringAsFixed(0),
              p.quantity.toString(),
              p.totalPrice.toStringAsFixed(0),
              p.quantity <= p.lowStockThreshold ? 'LOW STOCK' : 'IN STOCK',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'StockMate_Inventory_Report.pdf');
  }

  Future<void> exportProfitLossReportPdf() async {
    final pdf = pw.Document();
    final grossSales = db.totalGrossSales;
    final discounts = db.totalAuthorizedDiscounts;
    final refunds = db.totalRefunds;
    final revenue = db.totalRevenue;
    final cogs = db.totalCOGS;
    final grossProfit = db.totalGrossProfit;
    final expenses = db.totalExpenses;
    final loanInterest = db.totalLoanInterestExpenses;
    final netProfit = db.netProfit;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader('StockMate - Profit & Loss (P&L) Statement', 'Section 9 Accounting Standard'),
        footer: (context) => _buildPdfFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPlRow('Gross Sales', 'BDT ${grossSales.toStringAsFixed(2)}', isBold: true),
                pw.Divider(),
                _buildPlRow('Less: Authorized Discounts', '- BDT ${discounts.toStringAsFixed(2)}'),
                pw.Divider(),
                _buildPlRow('Less: Returns & Refunds', '- BDT ${refunds.toStringAsFixed(2)}'),
                pw.Divider(),
                _buildPlRow('Net Sales (Revenue)', 'BDT ${revenue.toStringAsFixed(2)}', isBold: true, color: PdfColors.blue800),
                pw.Divider(),
                _buildPlRow('Less: Cost of Goods Sold (COGS)', '- BDT ${cogs.toStringAsFixed(2)}'),
                pw.Divider(),
                _buildPlRow('Gross Profit', 'BDT ${grossProfit.toStringAsFixed(2)}', isBold: true, color: PdfColors.teal800),
                pw.Divider(),
                _buildPlRow('Less: Operating Expenses', '- BDT ${expenses.toStringAsFixed(2)}'),
                pw.Divider(),
                _buildPlRow('Less: Loan Interest Expense', '- BDT ${loanInterest.toStringAsFixed(2)}'),
                pw.Divider(),
                pw.SizedBox(height: 8),
                _buildPlRow(
                  'NET BUSINESS PROFIT / (LOSS)',
                  'BDT ${netProfit.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 16,
                  color: netProfit >= 0 ? PdfColors.green800 : PdfColors.red800,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text('Expense Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Date', 'Notes', 'Amount'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            data: db.expenses.map((e) => [
              e.category,
              DateFormat('dd/MM/yyyy').format(e.date),
              e.notes,
              'BDT ${e.amount.toStringAsFixed(0)}',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'StockMate_PL_Statement.pdf');
  }

  // --- CSV / Excel Exporter ---

  Future<void> exportSalesToCsv() async {
    final List<List<dynamic>> rows = [
      ['Date', 'Product Name', 'Brand', 'Catalog', 'Product Code', 'Quantity', 'Unit Cost (BDT)', 'Unit Sale Price (BDT)', 'Total Revenue (BDT)', 'Profit (BDT)', 'Notes']
    ];

    for (var s in db.sales) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp),
        s.productName,
        s.brandName,
        s.catalogName,
        s.productCode,
        s.quantity,
        s.unitCost,
        s.unitPrice,
        s.totalPrice,
        s.profit,
        s.notes,
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    await _shareCsvFile('stockmate_sales_report.csv', csvData);
  }

  Future<void> exportInventoryToCsv() async {
    final List<List<dynamic>> rows = [
      ['Brand Name', 'Catalog Name', 'Product Code', 'Quantity in Stock', 'Price Per Piece (BDT)', 'Total Valuation (BDT)', 'Buying Date', 'Low Stock Limit', 'Notes']
    ];

    for (var p in db.products) {
      rows.add([
        p.brandName,
        p.catalogName,
        p.productCode,
        p.quantity,
        p.pricePerPiece,
        p.totalPrice,
        DateFormat('yyyy-MM-dd').format(p.buyingDate),
        p.lowStockThreshold,
        p.notes,
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    await _shareCsvFile('stockmate_inventory_report.csv', csvData);
  }

  Future<void> _shareCsvFile(String filename, String content) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'StockMate Exported Data');
      Get.snackbar('Success', 'Report exported successfully', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Error sharing CSV: $e');
      Get.snackbar('Export Ready', 'CSV created successfully', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // --- PDF Helper Components ---
  pw.Widget _buildPdfHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('StockMate Business Management', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Period / Filter: $subtitle', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.Divider(thickness: 1.5, color: PdfColors.blue800),
      ],
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generated by StockMate POS System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _buildSummaryBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  pw.Widget _buildPlRow(String label, String value, {bool isBold = false, double fontSize = 12, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color ?? PdfColors.black)),
        ],
      ),
    );
  }
}
