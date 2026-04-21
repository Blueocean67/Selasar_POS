import 'package:flutter/material.dart';

class HistoryOrderPage extends StatelessWidget {
  const HistoryOrderPage({super.key});

  // Warna pendukung khusus history
  final Color successColor = const Color(0xFF4A5D3F);
  final Color processingColor = const Color(0xFFBC8E5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Riwayat Pesanan",
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5, // Contoh ada 5 riwayat
        itemBuilder: (context, index) {
          // Contoh selang-seling status untuk demo UI
          bool isFinished = index % 2 == 0; 
          return _buildHistoryCard(
            context,
            orderId: "SR-9921${index + 1}",
            customer: index == 0 ? "Budi Sudarsono" : "Pelanggan ${index + 1}",
            date: "18 April 2026, 10:${15 + index}",
            total: "Rp ${75000 + (index * 5000)}",
            status: isFinished ? "Selesai" : "Proses",
            statusColor: isFinished ? successColor : processingColor,
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context, {
    required String orderId,
    required String customer,
    required String date,
    required String total,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Bisa diarahkan ke detail pesanan lama atau lihat struk lagi
            Navigator.pushNamed(context, '/receipt');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(height: 1, color: Color(0xFFF1F1F1)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(customer, style: const TextStyle(fontSize: 13, color: Color(0xFF2D3329))),
                      ],
                    ),
                    Text(
                      total,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F), fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}