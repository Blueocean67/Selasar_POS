import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 

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
            .maybeSingle();

        if (data != null && data['avatar_url'] != null && mounted) {
          setState(() {
            _profileImageUrl = data['avatar_url'].toString();
          });
        }
      }
    } catch (_) {}
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
      final matchDate = createdAt.startsWith(formattedSelectedDate);

      bool matchSearch = true;
      if (searchQuery.isNotEmpty) {
        final orderId = item['id']?.toString() ?? '';
        final custName = (item['customer_name'] ?? '').toString().toLowerCase();
        matchSearch = orderId.contains(searchQuery) || custName.contains(searchQuery.toLowerCase());
      }

      bool matchStatus = true;
      final status = item['status']?.toString() ?? 'pending';
      if (activeFilter == 'Proses') {
        matchStatus = status != 'completed';
      } else if (activeFilter == 'Selesai') {
        matchStatus = status == 'completed';
      }

      return matchDate && matchSearch && matchStatus;
    }).toList();

    final Map<String, List<Map<String, dynamic>>> groupedMap = {};
    for (final order in filtered) {
      final rawDate = order['created_at']?.toString() ?? '';
      String dateKey = '';
      try {
        final dt = DateTime.parse(rawDate);
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

  @override
  Widget build(BuildContext context) {
    final historyManager = context.watch<OrderHistoryManager>();
    final groupedList = _buildGroupedList(historyManager.allOrders);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---- HEADER ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selasar Ruang',
                          style: TextStyle(
                              color: olive,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Riwayat Manajemen Transaksi',
                          style: TextStyle(
                              color: olive.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- SEARCH + DATE PICKER ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
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

            // ---- STATUS FILTER CHIPS ----
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

            // ---- GROUPED ORDER LIST ----
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: olive,
                                letterSpacing: 0.5,
                              ),
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
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  // Kamus daftar harga aset menu_page.dart untuk sinkronisasi harga item dummy agar tidak Rp 0
  static const Map<String, int> _menuPriceMap = {
    "Aceh Gayo V60": 32000,
    "Amerikano": 20000,
    "Signature Selasar Latte": 28000,
    "Kopi Gula Aren": 25000,
    "Matcha Latte": 28000,
    "Lemon Tea": 18000,
    "Jus Strawberry": 22000,
    "Almonds Chocolate": 20000,
    "Milk Shake": 18000,
    "Mie Bangladesh": 25000,
    "Nasi Goreng": 30000,
    "Ayam Pop": 35000,
    "Ayam Sambal Geprek": 20000,
    "Nasi Beef Teriyaki": 35000,
    "Spaghetti Bologness": 30000,
    "Roti Bakar": 20000,
    "Donat": 15000,
    "Cheesecake": 27000,
    "Cookies": 15000,
    "Burger": 25000
  };

  @override
  Widget build(BuildContext context) {
    final String id = order['id']?.toString() ?? '-';
    final String customerName = order['customer_name']?.toString() ?? 'Pelanggan';
    final String date = order['created_at']?.toString() ?? DateTime.now().toIso8601String();
    final dynamic price = order['total_price'] ?? order['total'] ?? 0;
    final String status = order['status']?.toString() ?? 'pending';
    final int itemsCount = (order['items_count'] ?? 1) as int;
    final String? nextStatusAt = order['next_status_at']?.toString();
    final String paymentMethod = order['payment_method']?.toString() ?? 'Tunai';
    
    // Sinkronisasi Fallback Meja: Jika acak dummy tidak ada meja, set nomor meja berurutan logis
    final String tableNumber = order['table_number']?.toString() ?? 
        (int.tryParse(id) != null ? ((int.parse(id) % 8) + 1).toString() : "03");
    
    final List<dynamic>? menuItems = order['menu_items'] as List<dynamic>?;

    final bool isDone = status == 'completed';
    final DateTime dt = DateTime.tryParse(date) ?? DateTime.now();
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);

    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String statusTimeline = formattedDate;
    Color statusColor = Colors.grey;

    if (!isDone) {
      statusColor = const Color(0xFF4A5D3F);
      if (nextStatusAt != null) {
        final finish = DateTime.tryParse(nextStatusAt);
        if (finish != null) {
          final diff = finish.difference(DateTime.now());
          final secondsLeft = diff.inSeconds;
          
          String stateLabel = 'PROSES';
          if (status == 'pending') stateLabel = 'DIPROSES';
          if (status == 'sedang_dibuat') stateLabel = 'SEDANG DIBUAT';
          if (status == 'siap') stateLabel = 'SIAP';

          statusTimeline = secondsLeft > 0
              ? '$stateLabel (±$secondsLeft dtk)'
              : 'Memproses tahap berikutnya...';
        }
      }
    }

    final num displayPrice = price is num ? price : (num.tryParse(price.toString()) ?? 0);

    // KONTROL HARGA MATEMATIS SINKRON KE STRUK (Mencegah total harga Rp 0)
    double calculatedSubtotal = (order['subtotal'] as num?)?.toDouble() ?? displayPrice.toDouble();
    double calculatedDiscount = (order['discount'] as num?)?.toDouble() ?? 0.0;
    double calculatedTax = (order['tax'] as num?)?.toDouble() ?? 0.0;
    double calculatedTotal = (order['total'] as num?)?.toDouble() ?? (calculatedSubtotal - calculatedDiscount + calculatedTax);

    Color badgeBg;
    Color badgeText;
    String badgeLabel = 'DIPROSES';

    switch (status) {
      case 'completed':
        badgeBg = const Color(0xFFE8F5E9);
        badgeText = Colors.green.shade700;
        badgeLabel = 'SELESAI';
        break;
      case 'siap':
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = Colors.blue.shade700;
        badgeLabel = 'SIAP';
        break;
      case 'sedang_dibuat':
        badgeBg = const Color(0xFFFFF8E1);
        badgeText = Colors.amber.shade800;
        badgeLabel = 'SEDANG DIBUAT';
        break;
      default:
        badgeBg = const Color(0xFFFFF3E0);
        badgeText = Colors.orange.shade800;
        badgeLabel = 'DIPROSES';
    }

    // =========================================================================
    // FIX INTEGRASI TOTAL: Memetakan rincian produk SINKRON 100% dengan MenuPage
    // =========================================================================
    List<Map<String, dynamic>> receiptStructuredItems = [];
    if (menuItems != null) {
      receiptStructuredItems = menuItems.map((m) {
        final mapItem = m as Map<dynamic, dynamic>;
        final String rawName = (mapItem['name'] ?? mapItem['menu_name'] ?? 'Menu Pilihan').toString();
        
        // Normalisasi nama produk agar cocok dengan map harga
        String normalizedName = rawName;
        if (rawName.toLowerCase().contains("v60")) normalizedName = "Aceh Gayo V60";
        if (rawName.toLowerCase().contains("latte")) normalizedName = "Signature Selasar Latte";
        if (rawName.toLowerCase().contains("bangla")) normalizedName = "Mie Bangladesh";
        if (rawName.toLowerCase().contains("bologn")) normalizedName = "Spaghetti Bologness";
        if (rawName.toLowerCase().contains("geprek")) normalizedName = "Ayam Sambal Geprek";
        if (rawName.toLowerCase().contains("cheese")) normalizedName = "Cheesecake";

        int itemQty = (mapItem['qty'] ?? mapItem['quantity'] ?? 1) as int;
        
        // Ambil harga asli menu dari MenuPage, jika data tidak terdaftar hitung rata-rata subtotal
        int menuSinglePrice = _menuPriceMap[normalizedName] ?? 
            (mapItem['price'] != null ? (mapItem['price'] as num).toInt() : (calculatedSubtotal ~/ (itemsCount > 0 ? itemsCount : 1)));

        return {
          'id': mapItem['id']?.toString() ?? 'a1',
          'name': rawName,
          'qty': itemQty,
          'quantity': itemQty,
          'price': menuSinglePrice, 
          'image': mapItem['image'] ?? mapItem['image_url'] ?? '',
          'note': mapItem['note'] ?? '',
        };
      }).toList();
      
      // Jika data berasal dari dummy lama, kalkulasi ulang subtotal & total dari akumulasi harga menu asli agar sinkron mutlak
      if (order['subtotal'] == null) {
        double accumulatedSubtotal = 0;
        for (var item in receiptStructuredItems) {
          accumulatedSubtotal += (item['price'] as int) * (item['qty'] as int);
        }
        calculatedSubtotal = accumulatedSubtotal;
        calculatedTotal = calculatedSubtotal - calculatedDiscount + calculatedTax;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // ===== AKSI KLIK KARTU MASUK KE STRUK DIGITAL DENGAN ARGUMENTS SINKRON OTOMATIS =====
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/receipt',
              arguments: {
                'transaction_id': id,
                'customer_name': customerName,
                'table_number': tableNumber, 
                'subtotal': calculatedSubtotal, 
                'discount': calculatedDiscount,
                'tax': calculatedTax,
                'total': calculatedTotal, 
                'payment_method': paymentMethod,
                'cash_amount': (order['cash_amount'] as num?)?.toDouble() ?? calculatedTotal,
                'change': (order['change'] as num?)?.toDouble() ?? 0.0,
                'bank_name': order['bank_name'] ?? '',
                'reference_number': order['reference_number'] ?? '',
                'applied_promo_code': order['applied_promo_code'] ?? '',
                'items': receiptStructuredItems, 
              }
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
                    Text(
                      '#SR-$id',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                      ),
                    )
                  ],
                ),
                const Divider(height: 20, thickness: 0.5),
                Text(
                  customerName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: isDone ? Colors.grey : const Color(0xFF4A5D3F)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isDone ? formattedDate : statusTimeline,
                        style: TextStyle(fontSize: 13, color: statusColor, fontWeight: isDone ? FontWeight.normal : FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (menuItems != null && menuItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: menuItems.take(3).map((m) {
                      final mapItem = m as Map<dynamic, dynamic>;
                      final name = mapItem['name']?.toString() ?? '';
                      final qty = mapItem['qty'] ?? 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4EC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$name x$qty',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF4A5D3F)),
                        ),
                      );
                    }).toList()
                      ..addAll(
                        menuItems.length > 3
                            ? [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4EC),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+${menuItems.length - 3} lainnya',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                )
                              ]
                            : [],
                      ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$itemsCount Items',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      currency.format(calculatedTotal), // Menampilkan total harga asli yang sudah disinkronisasi
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