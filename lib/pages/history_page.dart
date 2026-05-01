import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryOrderPage extends StatefulWidget {
  const HistoryOrderPage({super.key});

  @override
  State<HistoryOrderPage> createState() => _HistoryOrderPageState();
}

class _HistoryOrderPageState extends State<HistoryOrderPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);

  String activeFilter = "Semua";
  final List<String> filters = ["Semua", "Proses", "Selesai"];
  DateTime selectedDate = DateTime.now();

  // FUNGSI PICKER KALENDER
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryGreen),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  // STREAM DATA DARI SUPABASE (Beneran Otomatis)
  Stream<List<Map<String, dynamic>>> _getHistoryStream() {
    var query = Supabase.instance.client.from('orders').stream(primaryKey: ['id']);

    // Filter berdasarkan tanggal yang dipilih di kalender
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    return query.map((data) {
      // 1. Filter Tanggal
      var filtered = data.where((item) => item['created_at'].toString().contains(formattedDate)).toList();
      
      // 2. Filter Status (Proses/Selesai)
      if (activeFilter == "Proses") {
        return filtered.where((item) => item['status'] == 'pending' || item['status'] == 'preparing').toList();
      } else if (activeFilter == "Selesai") {
        return filtered.where((item) => item['status'] == 'completed').toList();
      }
      return filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: bgSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: primaryGreen),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Riwayat ${DateFormat('dd MMM').format(selectedDate)}", 
                style: const TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.w900, fontSize: 16)),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined, color: primaryGreen), 
                onPressed: () => _selectDate(context)
              ),
            ],
          ),

          // Header Statistik (Ambil dari Stream untuk Real-time)
          SliverToBoxAdapter(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getHistoryStream(),
              builder: (context, snapshot) {
                final totalOrder = snapshot.data?.length ?? 0;
                final totalOmzet = snapshot.data?.fold(0, (sum, item) => sum + (item['total_price'] as int)) ?? 0;
                return _SummaryHeader(totalOrder: totalOrder, totalOmzet: totalOmzet);
              }
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  bool isSelected = activeFilter == filters[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(filters[index]),
                      selected: isSelected,
                      onSelected: (val) => setState(() => activeFilter = filters[index]),
                      selectedColor: primaryGreen,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : primaryGreen, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

          // List History Dinamis
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text("Tidak ada riwayat untuk filter ini.")));
              }

              final orders = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = orders[index];
                      return _OrderHistoryCard(
                        orderId: "SR-${order['id']}",
                        customer: order['customer_name'] ?? "Guest",
                        dateTime: DateFormat('HH:mm').format(DateTime.parse(order['created_at'])),
                        total: "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(order['total_price'])}",
                        status: order['status'] ?? 'pending',
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int totalOrder, totalOmzet;
  const _SummaryHeader({required this.totalOrder, required this.totalOmzet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5D3F),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: "TOTAL ORDER", value: totalOrder.toString(), icon: Icons.receipt_long),
          _StatItem(label: "OMZET", value: "Rp ${NumberFormat.compact(locale: 'id').format(totalOmzet)}", icon: Icons.payments),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFA3B18A), size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final String orderId, customer, dateTime, total, status;

  const _OrderHistoryCard({
    required this.orderId,
    required this.customer,
    required this.dateTime,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // Penentuan warna berdasarkan status real database
    bool isFinished = status == 'completed';
    final statusColor = isFinished ? const Color(0xFF4A5D3F) : const Color(0xFFBC8E5B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => Navigator.pushNamed(context, '/receipt', arguments: orderId),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isFinished ? Icons.check_circle_outline : Icons.timer_outlined, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orderId, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        Text("Jam $dateTime WIB", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(isFinished ? "SELESAI" : "PROSES", style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 0.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(total, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4A5D3F), fontSize: 16)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}