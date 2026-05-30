import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FinanceSummaryPage extends StatefulWidget {
  const FinanceSummaryPage({super.key});

  @override
  State<FinanceSummaryPage> createState() => _FinanceSummaryPageState();
}

class _FinanceSummaryPageState extends State<FinanceSummaryPage> {
  // Warna tema Selasar Ruang
  final Color primaryColor = const Color(0xFF4C6935);
  final Color backgroundColor = const Color(0xFFF8F9F3);
  final Color cardColor = Colors.white;
  
  // Warna baru khusus untuk kotak Net Profit & FAB sesuai permintaan
  final Color netProfitBoxColor = const Color(0xFFB1B67C);

  double totalMasuk = 5000000;
  double totalKeluar = 500000;
  
  // Menambahkan controller untuk edit Net Profit manual
  final TextEditingController _netProfitController = TextEditingController();

  List<Map<String, dynamic>> transaksi = [
    {'nama': 'Penjualan Kopi', 'nominal': 50000.0, 'tipe': 'masuk'},
    {'nama': 'Beli Susu', 'nominal': 120000.0, 'tipe': 'keluar'},
  ];

  @override
  void initState() {
    super.initState();
    _updateNetProfitText();
  }

  // Fungsi pembantu untuk memperbarui teks Net Profit di controller
  void _updateNetProfitText() {
    _netProfitController.text = (totalMasuk - totalKeluar).toStringAsFixed(0);
  }

  // MENAMBAHKAN TOTAL MASUK & KELUAR DI PDF SESUAI PERMINTAAN - WARNA DIRAPIHKAN BIAR GA JELEK
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Laporan Keuangan Selasar", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 15),
            // Ringkasan Total Masuk & Keluar di PDF - Dibuat clean hitam/abu-abu agar profesional saat dicetak
            pw.Text("Total Pemasukan: Rp ${totalMasuk.toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.Text("Total Pengeluaran: Rp ${totalKeluar.toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text("Net Profit: Rp ${(totalMasuk - totalKeluar).toStringAsFixed(0)}", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            pw.SizedBox(height: 15),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.black),
              cellStyle: const pw.TextStyle(color: PdfColors.black),
              headers: ['Nama Transaksi', 'Tipe', 'Nominal'], 
              data: transaksi.map((t) => [
                t['nama'], 
                t['tipe'].toUpperCase(), 
                "Rp ${t['nominal'].toStringAsFixed(0)}"
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _tambahTransaksi(String nama, double nominal, String tipe) {
    setState(() {
      if (tipe == 'masuk') {
        totalMasuk += nominal;
      } else {
        totalKeluar += nominal;
      }
      // Memasukkan data baru ke indeks paling atas tanpa merusak data lama
      transaksi.insert(0, {'nama': nama, 'nominal': nominal, 'tipe': tipe});
      _updateNetProfitText();
    });
  }

  // Fungsi baru untuk menghapus transaksi
  void _hapusTransaksi(int index) {
    setState(() {
      final item = transaksi[index];
      if (item['tipe'] == 'masuk') {
        totalMasuk -= item['nominal'];
      } else {
        totalKeluar -= item['nominal'];
      }
      transaksi.removeAt(index);
      _updateNetProfitText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // Menghindari masalah layout bergeser/rebuild saat keyboard muncul
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        title: const Text("Keuangan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(onPressed: _generatePdf, icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF4C6935))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDashboardCard(),
            const SizedBox(height: 25),
            const Align(alignment: Alignment.centerLeft, child: Text("Riwayat Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 10),
            Expanded(child: _buildRecentTransactions()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: netProfitBoxColor, // Mengubah warna tombol tambah menjadi 0xFFB1B67C
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: netProfitBoxColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text("Net Profit Hari Ini", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          TextField(
            controller: _netProfitController,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: InputBorder.none, prefixText: "Rp "),
            onChanged: (val) {
              // Jika user edit manual, system tetap sinkron tanpa error angka kosong
              setState(() {
                double net = double.tryParse(val) ?? 0;
                totalMasuk = net + totalKeluar;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sinkronisasi warna teks masuk & keluar agar kontrasnya tidak menabrak warna netProfitBoxColor
              _statItem("Masuk", "Rp ${totalMasuk.toStringAsFixed(0)}", Colors.white),
              _statItem("Keluar", "Rp ${totalKeluar.toStringAsFixed(0)}", const Color(0xFFE57373)),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ],
  );

  Widget _buildRecentTransactions() {
    return ListView.builder(
      itemCount: transaksi.length,
      itemBuilder: (context, index) {
        final item = transaksi[index];
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            // Menampilkan nominal transaksi
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "${item['tipe'] == 'masuk' ? '+' : '-'} Rp ${item['nominal'].toStringAsFixed(0)}",
                style: TextStyle(
                  color: item['tipe'] == 'masuk' ? const Color(0xFF4C6935) : Colors.red, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            // Tombol hapus diletakkan di bagian trailing (kanan)
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _hapusTransaksi(index),
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController nominalCtrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Transaksi"),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Transaksi")),
            TextField(controller: nominalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Nominal (Rp)")),
          ]
        ),
        actions: [
          TextButton(
            onPressed: () {
              final double inputNominal = double.tryParse(nominalCtrl.text) ?? 0;
              if (nameCtrl.text.isNotEmpty && inputNominal > 0) {
                _tambahTransaksi(nameCtrl.text, inputNominal, 'masuk');
              }
              Navigator.pop(ctx);
            }, 
            child: const Text("Masuk", style: TextStyle(color: Color(0xFF4C6935), fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () {
              final double inputNominal = double.tryParse(nominalCtrl.text) ?? 0;
              if (nameCtrl.text.isNotEmpty && inputNominal > 0) {
                _tambahTransaksi(nameCtrl.text, inputNominal, 'keluar');
              }
              Navigator.pop(ctx);
            }, 
            child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }
}