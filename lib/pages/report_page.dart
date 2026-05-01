import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

// Palette Selasar Ruang
class AppColors {
  static const primary = Color(0xFF4A5D3F);
  static const secondary = Color(0xFFA3B18A);
  static const background = Color(0xFFF8F9F2);
  static const textPrimary = Color(0xFF2D3329);
  static const textSecondary = Color(0xFF7A7A7A);
  static const accentGold = Color(0xFFBC8E5B);
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final String dateNow = DateFormat('dd MMMM yyyy').format(DateTime.now());
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Data Dummy untuk Laporan
  final List<List<dynamic>> reportData = [
    ['Coffee', 'Kopi Gula Aren, Amerikano', 7200000],
    ['Non-Coffee', 'Matcha Latte, Es Teh Manis', 3100000],
    ['Food & Snack', 'Nasi Goreng, Roti Bakar', 2150000],
  ];

  // ==========================================
  // 1. EXCEL: PROFESIONAL STYLING (FIXED LOGIC)
  // ==========================================
  Future<void> _exportToExcel(BuildContext context) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan_Selasar'];
      excel.delete('Sheet1');

      sheetObject.cell(CellIndex.indexByString("A1")).value = TextCellValue("LAPORAN PENJUALAN SELASAR RUANG");
      sheetObject.cell(CellIndex.indexByString("A2")).value = TextCellValue("Dicetak pada: $dateNow");

      CellStyle headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#4A5D3F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      List<String> headers = ['KATEGORI', 'ITEM TERJUAL', 'SUBTOTAL (IDR)'];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
        sheetObject.setColumnWidth(i, 30);
      }

      double totalOmzet = 0;
      for (var i = 0; i < reportData.length; i++) {
        final nominal = int.tryParse(reportData[i][2].toString()) ?? 0;
        totalOmzet += nominal;
        
        sheetObject.appendRow([
          TextCellValue(reportData[i][0]?.toString() ?? ''),
          TextCellValue(reportData[i][1]?.toString() ?? ''),
          IntCellValue(nominal),
        ]);
      }

      var totalRowIndex = 5 + reportData.length;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIndex)).value = TextCellValue("TOTAL OMZET");
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIndex)).value = IntCellValue(totalOmzet.toInt());

      final fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Laporan_Selasar_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);

      await file.writeAsBytes(fileBytes!);
      if (context.mounted) _showSuccessSheet(context, "Excel", filePath);
    } catch (e) {
      if (context.mounted) _showError(context, "Gagal ekspor Excel: $e");
    }
  }

  // ==========================================
  // 2. PDF: BRANDED & FORMAL (FIXED COLOR PROPERTY)
  // ==========================================
  Future<void> _exportToPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("SELASAR RUANG", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
                    pw.Text("Premium Coffee & POS System Report", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Container(
                  height: 50, width: 50,
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A5D3F), shape: pw.BoxShape.circle),
                  child: pw.Center(child: pw.Text("SR", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            pw.Text("LAPORAN ANALISIS BISNIS", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text("Periode: $dateNow", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 25),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A5D3F)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("KATEGORI", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("DETAIL MENU", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("SUBTOTAL", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ],
                ),
                ...reportData.map((row) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(row[0].toString(), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(row[1].toString(), style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(row[2]), style: const pw.TextStyle(fontSize: 9))),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 30),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("TOTAL PENDAPATAN", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.Text(currencyFormat.format(12450000), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
                ],
              ),
            ),
            
            pw.SizedBox(height: 50),
            pw.Text("Dokumen ini dihasilkan secara otomatis oleh Selasar POS System.", style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/Laporan_Selasar_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) _showSuccessSheet(context, "PDF", filePath);
    } catch (e) {
      if (context.mounted) _showError(context, "Gagal ekspor PDF: $e");
    }
  }

  void _showSuccessSheet(BuildContext context, String type, String path) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text("$type Selasar Berhasil Dibuat!")),
          ],
        ),
        action: SnackBarAction(
          label: "BUKA",
          textColor: AppColors.secondary,
          onPressed: () => OpenFilex.open(path),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("INSIGHT BISNIS",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.primary),
            onPressed: () => _showExportMenu(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateNow, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            const _IncomeHeaderCard(),
            const SizedBox(height: 32),
            _sectionHeader("Komposisi Penjualan", "Berdasarkan Kategori"),
            const SizedBox(height: 16),
            const _CategoryChartCard(),
            const SizedBox(height: 32),
            _sectionHeader("Metode Pembayaran", "Paling Sering Digunakan"),
            const SizedBox(height: 16),
            const _PaymentMethodCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
        Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text("Unduh Dokumen Resmi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Laporan Branded Selasar Ruang Cafe.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 32),
            _ExportButton(
              icon: Icons.picture_as_pdf_rounded,
              label: "Laporan PDF Selasar",
              sub: "Format Branded & Formal",
              color: Colors.redAccent,
              onTap: () { Navigator.pop(context); _exportToPdf(context); },
            ),
            const SizedBox(height: 16),
            _ExportButton(
              icon: Icons.table_view_rounded,
              label: "Spreadsheet Excel (XLSX)",
              sub: "Format Tabel & Data Mentah",
              color: Colors.green,
              onTap: () { Navigator.pop(context); _exportToExcel(context); },
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeHeaderCard extends StatelessWidget {
  const _IncomeHeaderCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF5B714D)]),
        borderRadius: BorderRadius.circular(35),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ESTIMASI OMZET", style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Rp 12.450.000", style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CategoryChartCard extends StatelessWidget {
  const _CategoryChartCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          SizedBox(height: 110, width: 110, child: CustomPaint(painter: DonutChartPainter())),
          const SizedBox(width: 30),
          const Expanded(
            child: Column(
              children: [
                _LegendTile(AppColors.primary, "Coffee", "60%"),
                _LegendTile(AppColors.secondary, "Non-Coffee", "25%"),
                _LegendTile(Color(0xFFE5E9E0), "Food", "15%"),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: const Column(
        children: [
          _PaymentProgressRow(Icons.qr_code_scanner_rounded, "QRIS Payment", "Rp 8.1M", 0.65),
          SizedBox(height: 24),
          _PaymentProgressRow(Icons.wallet_rounded, "Tunai/Cash", "Rp 3.1M", 0.25),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _ExportButton({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label, percent;
  const _LegendTile(this.color, this.label, this.percent);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(percent, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _PaymentProgressRow extends StatelessWidget {
  final IconData icon;
  final String label, amount;
  final double progress;
  const _PaymentProgressRow(this.icon, this.label, this.amount, this.progress);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.background, color: AppColors.secondary),
        )
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 18..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    paint.color = AppColors.primary;
    canvas.drawArc(rect, -1.5, 3.8, false, paint);
    
    paint.color = AppColors.secondary;
    canvas.drawArc(rect, 2.4, 1.5, false, paint);
    
    paint.color = const Color(0xFFE5E9E0);
    canvas.drawArc(rect, 4.0, 0.7, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}