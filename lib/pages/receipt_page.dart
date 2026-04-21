import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF4A5D3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Struk Digital", 
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Logo & Nama Cafe
                  const Text("SELASAR RUANG", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF4A5D3F))),
                  const Text("Jl. Merdeka No. 123, Indonesia", 
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Divider(indent: 20, endIndent: 20),
                  
                  // Info Transaksi
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _receiptRow("ID Transaksi", "#SR-99210"),
                        _receiptRow("Tanggal", "18 April 2026"),
                        _receiptRow("Kasir", "Kelompok 4"),
                        _receiptRow("Metode", "QRIS"),
                      ],
                    ),
                  ),
                  
                  // Daftar Item (Mirip Gambar)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("PESANAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _itemRow("Signature Americano", "1", "28.000"),
                  _itemRow("Kopi Gula Aren", "2", "50.000"),
                  _itemRow("Croissant Almond", "1", "22.000"),
                  
                  const SizedBox(height: 20),
                  const Divider(indent: 20, endIndent: 20),
                  
                  // Total
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _totalRow("Subtotal", "100.000"),
                        _totalRow("Pajak (10%)", "10.000"),
                        const SizedBox(height: 10),
                        _totalRow("TOTAL", "110.000", isBold: true),
                      ],
                    ),
                  ),
                  
                  // Footer Struk
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text("Terima kasih atas kunjungan Anda!", 
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                        SizedBox(height: 5),
                        Text("--- SELASAR CAFE ---", 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Tombol Simpan/Share
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text("Simpan Sebagai Gambar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5D3F),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _itemRow(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Text("${qty}x", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F))),
          const SizedBox(width: 15),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text("Rp $price", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text("Rp $value", style: TextStyle(fontSize: isBold ? 18 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}