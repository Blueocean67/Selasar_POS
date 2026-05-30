import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:selasar_pos/main.dart'; 
import 'dart:convert';

class HistoryOrderPage extends StatefulWidget {
  const HistoryOrderPage({super.key});

  @override
  State<HistoryOrderPage> createState() => _HistoryOrderPageState();
}

class _HistoryOrderPageState extends State<HistoryOrderPage> {
  static const Color olive = Color(0xFF4A5D3F);
  static const Color bg = Color(0xFFF8F9F2);
  static const Color lightGrey = Color(0xFFEFEFEA);

  String activeFilter = "All Orders";
  final List<String> filters = ["All Orders", "Selesai", "Proses"];

  DateTime selectedDate = DateTime.now();
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  String? _profileImageUrl;
  int? _lastOrderCount; 

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

        if (mounted) {
          setState(() {
            _profileImageUrl = data?['avatar_url'] ?? user.userMetadata?['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi foto profil: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2027),
    );

    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';

    return DateFormat('dd MMMM yyyy', 'id').format(date);
  }

  List<dynamic> _buildGroupedList(List<Map<String, dynamic>> allOrders) {
    final formattedSelectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final filtered = allOrders.where((item) {
      final createdAt = item['created_at']?.toString() ?? '';
      
      String localDateStr = '';
      try {
        final parsedDt = DateTime.parse(createdAt).toLocal();
        localDateStr = DateFormat('yyyy-MM-dd').format(parsedDt);
      } catch (_) {
        localDateStr = createdAt.split('T')[0];
      }

      final matchDate = localDateStr == formattedSelectedDate;

      bool matchSearch = true;
      if (searchQuery.isNotEmpty) {
        final orderId = (item['id'] ?? item['transaction_id'] ?? '').toString().toLowerCase();
        final custName = (item['customer_name'] ?? item['customer'] ?? item['pelanggan'] ?? item['nama_pelanggan'] ?? '').toString().toLowerCase();
        
        matchSearch = orderId.contains(searchQuery.toLowerCase()) || custName.contains(searchQuery.toLowerCase());
      }

      String status = (item['status'] ?? 'PENDING').toString().toUpperCase();

      bool matchStatus = true;
      if (activeFilter == 'Proses') {
        matchStatus = status == 'PROSES' || status == 'DIPROSES' || (status != 'COMPLETED' && status != 'SELESAI' && status != 'SUCCESS' && status != 'PAID');
      } else if (activeFilter == 'Selesai') {
        matchStatus = status == 'COMPLETED' || status == 'SELESAI' || status == 'SUCCESS' || status == 'PAID';
      }

      return matchDate && matchSearch && matchStatus;
    }).toList();

    final Map<String, List<Map<String, dynamic>>> groupedMap = {};

    for (final order in filtered) {
      final rawDate = order['created_at']?.toString() ?? '';
      String dateKey = '';
      try {
        final dt = DateTime.parse(rawDate).toLocal();
        dateKey = DateFormat('yyyy-MM-dd').format(dt);
      } catch (_) {
        dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
      groupedMap.putIfAbsent(dateKey, () => []).add(order);
    }

    final sortedKeys = groupedMap.keys.toList()..sort((a, b) => b.compareTo(a));
    final List<dynamic> result = [];

    for (final key in sortedKeys) {
      DateTime dt;
      try {
        dt = DateTime.parse(key);
      } catch (_) {
        dt = DateTime.now();
      }
      result.add(_dateGroupLabel(dt));
      result.addAll(groupedMap[key]!);
    }

    return result;
  }

  void _triggerIncomingNotification(Map<String, dynamic> newestOrder) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final String id = (newestOrder['id'] ?? newestOrder['transaction_id'] ?? '').toString();
      final String displayId = id.length > 6 ? id.substring(0, 6).toUpperCase() : id;
      final String name = (newestOrder['customer_name'] ?? newestOrder['customer'] ?? newestOrder['pelanggan'] ?? newestOrder['nama_pelanggan'] ?? 'Pelanggan').toString();
      final String table = (newestOrder['table_number'] ?? newestOrder['table'] ?? newestOrder['meja'] ?? newestOrder['no_meja'] ?? '--').toString();

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shopping_bag, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pesanan Masuk! #SR-$displayId • Meja $table an. $name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: olive,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('transactions')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            List<Map<String, dynamic>> localOrders = [];
            try {
              final historyManager = context.watch<OrderHistoryManager>();
              localOrders = historyManager.allOrders.cast<Map<String, dynamic>>();
            } catch (_) {}

            final realtimeOrders = snapshot.data ?? [];

            // FIX: Menggunakan post frame callback secara aman untuk mencegah crash tree element
            if (snapshot.hasData && _lastOrderCount != null && realtimeOrders.length > _lastOrderCount!) {
              final newestOrder = realtimeOrders.first;
              _triggerIncomingNotification(newestOrder);
            }
            if (snapshot.hasData) {
              _lastOrderCount = realtimeOrders.length;
            }

            final Map<String, Map<String, dynamic>> mergedMap = {};
            
            for (var order in localOrders) {
              final String id = (order['id'] ?? order['transaction_id'] ?? '').toString();
              if (id.isNotEmpty) mergedMap[id] = order;
            }
            
            for (var order in realtimeOrders) {
              final String id = (order['id'] ?? order['transaction_id'] ?? '').toString();
              if (id.isNotEmpty) mergedMap[id] = order;
            }

            final mergedOrders = mergedMap.values.toList();
            
            mergedOrders.sort((a, b) {
              final dateA = (a['created_at'] ?? '').toString();
              final dateB = (b['created_at'] ?? '').toString();
              return dateB.compareTo(dateA);
            });

            final groupedList = _buildGroupedList(mergedOrders);

            if (snapshot.connectionState == ConnectionState.waiting && groupedList.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: olive));
            }

            return CustomScrollView(
              slivers: [
                // --- HEADER SECTION ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEFEFEA),
                          backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                              ? NetworkImage(_profileImageUrl!)
                              : const AssetImage('assets/images/avatar.png') as ImageProvider,
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selasar Ruang',
                              style: TextStyle(color: olive, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Riwayat Manajemen Transaksi',
                              style: TextStyle(color: olive.withOpacity(0.6), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // --- SEARCH & DATE PICKER ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => searchQuery = val),
                              decoration: const InputDecoration(
                                hintText: 'Cari ID / Nama...',
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: olive, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  DateFormat('dd MMM').format(selectedDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: olive),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- FILTER CHIPS ---
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filters.length,
                      itemBuilder: (context, index) {
                        final f = filters[index];
                        final isSel = activeFilter == f;
                        return GestureDetector(
                          onTap: () => setState(() => activeFilter = f),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? olive : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSel ? olive : lightGrey),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // --- LIST TRANSAKSI ---
                groupedList.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40.0),
                            child: Text(
                              'Tidak ada riwayat transaksi',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) {
                            final item = groupedList[index];
                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 4),
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: olive, letterSpacing: 0.5),
                                ),
                              );
                            }
                            final order = item as Map<String, dynamic>;
                            return _OrderCard(order: order);
                          },
                          childCount: groupedList.length,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    // 1. Nomor Order
    final String id = (order['id'] ?? order['transaction_id'] ?? order['tx_id'] ?? 'SR-MANUAL').toString();
    final String shortId = id.length > 6 ? id.substring(0, 6).toUpperCase() : id;

    // 2. Tanggal dan Jam Transaksi
    final String date = (order['created_at'] ?? DateTime.now().toIso8601String()).toString();
    final DateTime dt = DateTime.tryParse(date) ?? DateTime.now();
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());

    // 3. Nama Pemesan & 6. Nomor Meja
    final String customerName = (order['customer_name'] ?? order['customer'] ?? order['pelanggan'] ?? order['name'] ?? order['nama_pelanggan'] ?? 'Pelanggan').toString();
    final String tableNumber = (order['table_number'] ?? order['table'] ?? order['no_meja'] ?? order['meja'] ?? '--').toString();
    
    // 4. Nama Kasir & 13. Metode Pembayaran
    final String paymentMethod = (order['payment_method'] ?? order['payment_type'] ?? order['metode_pembayaran'] ?? 'Tunai').toString();
    final String cashierName = (order['cashier_name'] ?? order['operator_name'] ?? order['cashier'] ?? order['nama_kasir'] ?? 'Kasir').toString();
    
    // 7. Daftar Produk Lengkap (Sinkronisasi struktur parser dengan data Receipt)
    List<Map<String, dynamic>> itemsList = [];
    double calculatedSubtotal = 0.0;
    List<dynamic> rawItems = [];

    if (order['menu_items'] != null) {
      if (order['menu_items'] is List) {
        rawItems = order['menu_items'];
      } else if (order['menu_items'] is String) {
        try { rawItems = jsonDecode(order['menu_items']); } catch (_) {}
      }
    } else if (order['items'] != null) {
      if (order['items'] is List) {
        rawItems = order['items'];
      } else if (order['items'] is String) {
        try { rawItems = jsonDecode(order['items']); } catch (_) {}
      }
    }

    if (rawItems.isNotEmpty) {
      for (var item in rawItems) {
        if (item is Map) {
          final double itemPrice = double.tryParse((item['price'] ?? item['harga'] ?? 0).toString()) ?? 0.0;
          final int itemQty = int.tryParse((item['quantity'] ?? item['qty'] ?? item['jumlah'] ?? 1).toString()) ?? 1;
          calculatedSubtotal += itemPrice * itemQty;

          itemsList.add({
            'name': (item['name'] ?? item['nama_menu'] ?? item['nama'] ?? item['product_name'] ?? 'Menu').toString(),
            'qty': itemQty,
            'price': itemPrice,
            'note': item['note']?.toString()
          });
        }
      }
    }

    // 8. Subtotal, 9. Diskon, 10. Pajak, 11. Service, 12. Total Pembayaran
    double discount = double.tryParse((order['discount_amount'] ?? order['discount'] ?? 0).toString()) ?? 0.0;
    double tax = double.tryParse((order['tax_amount'] ?? order['tax'] ?? order['pajak'] ?? 0).toString()) ?? 0.0;
    double serviceCharge = double.tryParse((order['service_charge'] ?? order['service'] ?? 0).toString()) ?? 0.0;
    
    double subtotal = double.tryParse((order['subtotal'] ?? 0).toString()) ?? calculatedSubtotal;
    if (subtotal == 0.0) {
      subtotal = double.tryParse((order['total_price'] ?? order['total'] ?? 0).toString()) ?? 0.0;
    }

    double total = double.tryParse((order['total_price'] ?? order['total'] ?? order['grand_total'] ?? 0).toString()) ?? 0.0;
    if (total == 0.0 && subtotal > 0) {
      total = (subtotal - discount + tax + serviceCharge).clamp(0, double.infinity);
    }
    
    // 14. Nominal Bayar & 15. Kembalian
    double payAmount = double.tryParse((order['pay_amount'] ?? order['nominal_bayar'] ?? order['amount_paid'] ?? total).toString()) ?? total;
    double change = double.tryParse((order['change'] ?? order['kembalian'] ?? 0).toString()) ?? (payAmount - total).clamp(0, double.infinity);

    // 16. Status Pesanan
    String status = (order['status'] ?? 'PENDING').toString().toUpperCase();
    final bool isDone = status == 'COMPLETED' || status == 'SELESAI' || status == 'SUCCESS' || status == 'PAID';

    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // MENGIRIMKAN SELURUH DATA SNAPSHOT IDENTIK KE STRUKTUR RECEIPT
            Navigator.pushNamed(
              context,
              '/receipt',
              arguments: {
                ...order,
                'id': id,
                'transaction_id': id,
                'customer_name': customerName,
                'table_number': tableNumber,
                'cashier_name': cashierName,
                'payment_method': paymentMethod,
                'items': itemsList,
                'menu_items': itemsList,
                'subtotal': subtotal,
                'discount_amount': discount,
                'tax_amount': tax,
                'service_charge': serviceCharge,
                'total_price': total,
                'total': total,
                'pay_amount': payAmount,
                'change': change,
                'status': isDone ? 'completed' : 'pending',
                'created_at': date,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '#SR-$shortId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDone ? 'SELESAI' : 'DIPROSES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.green : Colors.orange,
                        ),
                      ),
                    )
                  ],
                ),
                const Divider(height: 20, thickness: 0.5),
                Text(
                  customerName.toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kasir: $cashierName',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D3F), fontWeight: FontWeight.w600),
                ),
                
                if (itemsList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: itemsList.map((m) {
                      final name = m['name'].toString();
                      final qty = m['qty'];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF0F4EC), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '$name x$qty',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4A5D3F)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tableNumber.trim() == '--' || tableNumber.isEmpty ? 'Take Away' : 'Meja $tableNumber',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      currency.format(total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A5D3F)),
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