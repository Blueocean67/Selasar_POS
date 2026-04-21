import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Prefix 'pw' biar gak bentrok ama Flutter
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../theme/app_colors.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  // --- FUNGSI EKSPOR EXCEL (FIXED ANTI-ERROR) ---
  Future<void> _exportToExcel(BuildContext context) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Laporan Penjualan'];

    // Header pakai TextCellValue agar sinkron dengan library Excel terbaru
    sheetObject.appendRow([
      TextCellValue('Kategori'), 
      TextCellValue('Total Penjualan'),
    ]);

    // Data Penjualan
    sheetObject.appendRow([TextCellValue('Coffee'), TextCellValue('7.200.000')]);
    sheetObject.appendRow([TextCellValue('Non-Coffee'), TextCellValue('3.100.000')]);
    sheetObject.appendRow([TextCellValue('Food & Snack'), TextCellValue('2.150.000')]);

    var fileBytes = excel.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Laporan_Selasar.xlsx');
    
    await file.writeAsBytes(fileBytes!);
    _showSuccessSheet(context, "Excel", file.path);
  }

  // --- FUNGSI EKSPOR PDF (FIXED DENGAN PREFIX PW) ---
  Future<void> _exportToPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("SELASAR RUANG CAFE", 
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text("Laporan Ringkasan Bisnis", style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text("Total Pendapatan: Rp 12.450.000", 
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 30),
                pw.Text("Rincian Metode Pembayaran:"),
                pw.Bullet(text: "QRIS: Rp 8.100.000 (65%)"),
                pw.Bullet(text: "Tunai: Rp 3.120.000 (25%)"),
                pw.Bullet(text: "Debit: Rp 1.230.000 (10%)"),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Laporan_Selasar.pdf');
    await file.writeAsBytes(await pdf.save());

    _showSuccessSheet(context, "PDF", file.path);
  }

  void _showSuccessSheet(BuildContext context, String type, String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text("$type berhasil disimpan!", style: const TextStyle(color: Colors.white)),
        action: SnackBarAction(
          label: "BUKA", 
          textColor: AppColors.secondary,
          onPressed: () => OpenFilex.open(path)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Analisis Bisnis",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.primary),
            onPressed: () => _showExportMenu(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            const Text("Analisis Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildChartSection(),
            const SizedBox(height: 24),
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),
            const Text("Detail Performa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildCategoryStats("Coffee", "Rp 7.200.000", 0.6),
            _buildCategoryStats("Non-Coffee", "Rp 3.100.000", 0.25),
            _buildCategoryStats("Food & Snack", "Rp 2.150.000", 0.15),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ESTIMASI PENDAPATAN", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2)),
          const Text("Rp 12.450.000", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text("12.5% dibanding bulan lalu", style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          SizedBox(height: 100, width: 100, child: CustomPaint(painter: PieChartPainter())),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              children: [
                _legendItem(AppColors.primary, "Coffee", "60%"),
                _legendItem(AppColors.secondary, "Non-Coffee", "25%"),
                _legendItem(const Color(0xFFDDE5D7), "Food", "15%"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(percent, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _paymentRow(Icons.qr_code_2_rounded, "QRIS", "Rp 8.100.000", 0.65),
          const SizedBox(height: 15),
          _paymentRow(Icons.payments_rounded, "Tunai/Cash", "Rp 3.120.000", 0.25),
          const SizedBox(height: 15),
          _paymentRow(Icons.credit_card_rounded, "Debit Card", "Rp 1.230.000", 0.10),
        ],
      ),
    );
  }

  Widget _paymentRow(IconData icon, String label, String amount, double percent) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        )
      ],
    );
  }

  Widget _buildCategoryStats(String label, String value, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text("${(percentage * 100).toInt()}% Kontribusi", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
        ],
      ),
    );
  }

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Simpan Laporan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _exportOption(context, Icons.picture_as_pdf, "Format PDF", Colors.red, () => _exportToPdf(context)),
            _exportOption(context, Icons.table_chart, "Format Excel", Colors.green, () => _exportToExcel(context)),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () { Navigator.pop(context); onTap(); },
    );
  }
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppColors.primary;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5, 3.8, true, paint);
    paint.color = AppColors.secondary;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.3, 1.5, true, paint);
    paint.color = const Color(0xFFDDE5D7);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 3.8, 1.0, true, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}