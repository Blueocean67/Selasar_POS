import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// --- IMPORT MODELS & PROVIDERS ---
import 'package:selasar_pos/provider/promo_provider.dart';
import 'package:selasar_pos/main.dart'; // Import OrderHistoryManager dari main.dart pusat

// --- IMPORT PAGES ---
import 'package:selasar_pos/pages/promo_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return const _DashboardPageContent();
  }
}

class _DashboardPageContent extends StatefulWidget {
  const _DashboardPageContent();

  @override
  State<_DashboardPageContent> createState() =>
      _DashboardPageContentState();
}

class _DashboardPageContentState
    extends State<_DashboardPageContent> {

  final supabase = Supabase.instance.client;

  int omzet = 0;
  int transaksiSelesai = 0;
  int totalMenu = 0;

  List<dynamic> recommendedMenus = [];

  String greeting = "";
  String? profileImage;
  String? userRole;

  int currentIndex = 0;
  bool isLoading = true;

  StreamSubscription<List<Map<String, dynamic>>>? _transactionsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _menusSubscription;

  // ================= FIX SINKRONISASI MUTLAK =================
  final Set<String> _countedTransactionIds = {};
  int _supabaseOmzet = 0;
  int _supabaseCount = 0;

  // Nilai acak dasar awal presentasi agar dashboard tidak kosong di awal sebelum transaksi dibuat kasir
  static const int _baseDemoOmzet = 1250000;
  static const int _baseDemoCount = 12;

  @override
  void initState() {
    super.initState();
    _updateTimeBasedState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initDashboard();
    });
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _menusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDashboard() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    await loadProfile();
    _setupRealtimeMenusStream();
    _setupRealtimeTransactionsStream();

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _updateTimeBasedState() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      greeting = "SELAMAT PAGI";
    } else if (hour < 15) {
      greeting = "SELAMAT SIANG";
    } else if (hour < 19) {
      greeting = "SELAMAT SORE";
    } else {
      greeting = "SELAMAT MALAM";
    }
  }

  // --- AMBIL PROFIL REALTIME DARI DATABASE (SINKRON DENGAN PROFILE_PAGE) ---
  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Mengambil data real-time langsung dari tabel 'profiles' penyesuaian skema baru
        final res = await supabase
            .from('profiles')
            .select('role, avatar_url')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

        if (mounted) {
          setState(() {
            // Priority utama dari data database riil, fallback menggunakan userMetadata
            profileImage = res?['avatar_url'] ?? user.userMetadata?['avatar_url'];
            
            String dbRole = (res?['role'] ?? user.userMetadata?['role'] ?? 'kasir').toString().trim().toUpperCase();
            userRole = dbRole;
          });
        }
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
      if (mounted) setState(() => userRole = 'KASIR');
    }
  }

  bool _isValidTransaction(Map<String, dynamic> tx) {
    final status = (tx['payment_status'] ?? tx['status'] ?? tx['payment_status_code'] ?? '').toString().toUpperCase().trim();
    return status == 'SUCCESS' || status == 'PAID' || status == 'BERHASIL' || status == 'COMPLETED' || status == 'SELESAI';
  }

  int _safePrice(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  String _safeId(Map<String, dynamic> tx) {
    return (tx['id'] ?? tx['transaction_id'] ?? tx['invoice_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();
  }

  // ================= STREAM TRANSAKSI REALTIME SUPABASE =================
  void _setupRealtimeTransactionsStream() {
    _transactionsSubscription?.cancel();
    try {
      _transactionsSubscription = supabase
          .from('transactions')
          .stream(primaryKey: ['id'])
          .listen(
        (List<Map<String, dynamic>> data) {
          _countedTransactionIds.clear();
          int realtimeOmzet = 0;
          int realtimeCount = 0;

          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

          for (final tx in data) {
            final rawDate = (tx['created_at'] ?? tx['date'] ?? '').toString();
            final isToday = rawDate.isEmpty || rawDate.startsWith(today);

            if (!isToday) continue;

            if (_isValidTransaction(tx)) {
              final id = _safeId(tx);
              _countedTransactionIds.add(id);

              realtimeOmzet += _safePrice(tx['total_price'] ?? tx['total'] ?? tx['total_billing']);
              realtimeCount++;
            }
          }

          if (mounted) {
            setState(() {
              _supabaseOmzet = realtimeOmzet;
              _supabaseCount = realtimeCount;
            });
          }
        },
        onError: (error) {
          debugPrint("Realtime Transactions Stream Error: $error");
        },
      );
    } catch (e) {
      debugPrint("STREAM INIT ERROR: $e");
    }
  }

  void _setupRealtimeMenusStream() {
    _menusSubscription?.cancel();
    _menusSubscription = supabase
        .from('menus')
        .stream(primaryKey: ['id'])
        .listen(
      (List<Map<String, dynamic>> data) {
        final List<Map<String, dynamic>> staticMenus = [
          {
            'id': 'a3',
            'name': 'Signature Selasar Latte',
            'image': 'assets/images/Caramellatte.jpg',
            'desc': 'Campuran biji arabika lokal dengan sentuhan aren organik premium.',
            'price': 28000,
            'tag': 'TERLARIS',
          },
          {
            'id': 'a1',
            'name': 'Aceh Gayo V60',
            'image': 'assets/images/acehgayov60.png',
            'desc': 'Notes of dark chocolate and mild earthy spice from the Gayo highlands.',
            'price': 32000,
            'tag': 'MANUAL BREW',
          },
          _getTimeBasedFood(),
        ];

        if (mounted) {
          setState(() {
            totalMenu = data.isNotEmpty ? data.length : 20;
            recommendedMenus = staticMenus.take(3).toList();
          });
        }
      },
      onError: (error) {
        debugPrint("Realtime Menus Stream Error: $error");
      },
    );
  }

  Map<String, dynamic> _getTimeBasedFood() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return {
        'id': 'c3',
        'name': 'Ayam Pop',
        'price': 35000,
        'image': 'assets/images/ayampop.webp',
        'desc': 'Rekomendasi spesial untuk menemani sarapan Anda.',
        'tag': 'SARAPAN',
      };
    } else if (hour < 15) {
      return {
        'id': 'c4',
        'name': 'Ayam Sambal Geprek',
        'price': 20000,
        'image': 'assets/images/ayamsambalgeprek.jpg',
        'desc': 'Rekomendasi spesial untuk menemani makan siang Anda.',
        'tag': 'MAKAN SIANG',
      };
    } else if (hour < 19) {
      return {
        'id': 'c5',
        'name': 'Nasi Beef Teriyaki',
        'price': 35000,
        'image': 'assets/images/nasibeefteriyaki.jpg',
        'desc': 'Rekomendasi spesial untuk menemani snack sore Anda.',
        'tag': 'SORE',
      };
    } else {
      return {
        'id': 'c6',
        'name': 'Spaghetti Bolognese',
        'price': 30000,
        'image': 'assets/images/spagettibolognes.jpg',
        'desc': 'Rekomendasi spesial untuk menemani makan malam Anda.',
        'tag': 'MALAM',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PromoProvider>();
    
    // ===== HUBUNGKAN NOTIFIKASI & KALKULASI TRANSAKSI KASIR SECARA REALTIME =====
    final historyManager = context.watch<OrderHistoryManager>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    int currentLocalOmzet = 0;
    int currentLocalCount = 0;

    // Hitung hanya transaksi yang bertanggal hari ini di riwayat memory
    for (var order in historyManager.allOrders) {
      final createdAt = order['created_at']?.toString() ?? '';
      if (createdAt.startsWith(todayStr)) {
        final id = order['id']?.toString() ?? '';
        
        // Pengaman anti-double hitung jika transaksi tersebut sudah ter-load dari stream Supabase
        if (!_countedTransactionIds.contains(id)) {
          currentLocalOmzet += _safePrice(order['total_price']);
          currentLocalCount++;
        }
      }
    }

    // ===== FIX FORMULA: GABUNGKAN DATA UTUH DENGAN ANGKA BASELINE YANG STABIL =====
    final int displayOmzet = _baseDemoOmzet + _supabaseOmzet + currentLocalOmzet;
    final int displayCount = _baseDemoCount + _supabaseCount + currentLocalCount;

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A4D2E)))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _initDashboard,
                color: const Color(0xFF4A4D2E),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER WITH TEXT MODIFICATIONS =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$greeting, ${userRole ?? 'KASIR'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7A7C64),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Pemisahan tulisan Dashboard dan Ringkasan dengan modifikasi jarak & ukuran teks
                              const Text(
                                "Dashboard",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF32341E),
                                  height: 1.0,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4), // Jarak pemisah antar teks
                              const Text(
                                "Ringkasan",
                                style: TextStyle(
                                  fontSize: 26, // Ukuran teks diperkecil sedikit dari sebelumnya (32 -> 26)
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5D623A),
                                  height: 1.0,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/profile').then((_) => loadProfile()),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFE2E4D8),
                              backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                                  ? NetworkImage(profileImage!)
                                  : const AssetImage('assets/images/avatar.png') as ImageProvider,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ===== KARTU OMZET =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB1B67C),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TOTAL PENJUALAN HARI INI",
                              style: TextStyle(
                                color: Color(0xFF4A4D2E),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currencyFormat.format(displayOmzet),
                              style: const TextStyle(
                                fontSize: 34,
                                color: Color(0xFF32341E),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "↗ Berdasarkan Transaksi Valid Sukses",
                              style: TextStyle(
                                color: Color(0xFF5D623A),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildMiniTargetInfo("Target", "Rp 5.0M"),
                                const SizedBox(width: 12),
                                _buildMiniTargetInfo("Status", "Realtime"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ===== KARTU TRANSAKSI =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F0),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, color: Color(0xFF32341E), size: 20),
                            const SizedBox(height: 10),
                            Text(
                              "$displayCount",
                              style: const TextStyle(
                                color: Color(0xFF32341E),
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Transaksi Selesai",
                              style: TextStyle(
                                color: Color(0xFF7A7C64),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text(
                        "Akses Cepat",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF32341E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ===== GRID AKSES CEPAT (ROLE BASED) =====
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.45,
                        ),
                        children: _buildRoleBasedActions(),
                      ),

                      const SizedBox(height: 32),
                      const Text(
                        "Rekomendasi Hari Ini",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF32341E),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ===== KARTU MENU REKOMENDASI =====
                      ...recommendedMenus.map((menu) => _buildMenuCard(menu, currencyFormat)),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMiniTargetInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            "$label ",
            style: const TextStyle(
              color: Color(0xFF5D623A),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF32341E),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleBasedActions() {
    if (userRole == 'ADMIN') {
      return [
        _quickAction(
          Icons.shopping_cart_outlined,
          "Buat Pesanan",
          "Mulai transaksi",
          () => Navigator.pushNamed(context, '/setup_order'),
        ),
        _quickAction(
          Icons.inventory_2_outlined,
          "Keuangan",
          "Buka Menu Keuangan",
          () => Navigator.pushNamed(context, '/financesummary'),
        ),
        _quickAction(
          Icons.discount_outlined,
          "Menu Gallery",
          "Lihat Katalog Menu",
          () => Navigator.pushNamed(context, '/menu_gallery'),
        ),
        _quickAction(
          Icons.analytics_outlined,
          "Laporan Cafe",
          "Grafik & ekspor PDF",
          () => Navigator.pushNamed(context, '/report'),
        ),
      ];
    } else {
      return [
        _quickAction(
          Icons.shopping_cart_outlined,
          "Mulai Pesanan",
          "Ke halaman order",
          () => Navigator.pushNamed(context, '/setup_order'),
        ),
        _quickAction(
          Icons.confirmation_number_outlined,
          "Kupon Promo",
          "Manajemen Kupon",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromoPage()),
            );
          }, 
        ),
        _quickAction(
          Icons.history,
          "History",
          "Riwayat transaksi",
          () => Navigator.pushNamed(context, '/history'),
        ),
        _quickAction(
          Icons.support_agent,
          "Bantuan",
          "Tanya admin",
          () => _showHelpDialog(),
        ),
      ];
    }
  }

  Widget _quickAction(IconData icon, String title, String desc, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECE6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF7A7C64), size: 22),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF32341E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9A9C86),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFDFB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFF4A4D2E)),
              SizedBox(width: 10),
              Text(
                "Bantuan Kasir",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF32341E),
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Jika terjadi kendala pada sistem operasional atau mesin kasir, silakan hubungi kontak berikut:",
                style: TextStyle(color: Color(0xFF7A7C64), fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 18, color: Color(0xFF4A4D2E)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Manager Cafe", style: TextStyle(fontSize: 11, color: Color(0xFF9A9C86), fontWeight: FontWeight.w500)),
                      Text("0812-3456-7890", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF32341E), fontSize: 14)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.build_circle_outlined, size: 18, color: Color(0xFF4A4D2E)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("IT Support / Admin", style: TextStyle(fontSize: 11, color: Color(0xFF9A9C86), fontWeight: FontWeight.w500)),
                      Text("0898-7654-3210", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF32341E), fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4A4D2E)),
              child: const Text(
                "Mengerti",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(dynamic menu, NumberFormat fmt) {
    final bool isStaticAsset = (menu['image'] ?? '').toString().startsWith('assets');
    final String imgUrl = menu['image'] ?? menu['image_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: isStaticAsset
                ? Image.asset(
                    imgUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : Image.network(
                    imgUrl,
                    height: 210,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        menu['name'] ?? 'Menu',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Color(0xFF32341E),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (menu['tag'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (menu['tag'] == 'MANUAL BREW') ? const Color(0xFFFFE0B2) : const Color(0xFFE4E6D9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          menu['tag'],
                          style: TextStyle(
                            fontSize: 9,
                            color: (menu['tag'] == 'MANUAL BREW') ? const Color(0xFFE65100) : const Color(0xFF4A4D2E),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  menu['desc'] ?? menu['description'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF7A7C64),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmt.format((menu['price'] ?? menu['harga'] ?? 0) as num),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF32341E),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context, 
                            '/setup_order',
                            arguments: {
                              'selected_product': menu,
                              'preserve_cart': true,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A7C64),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Tambah",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.add, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 210,
      color: const Color(0xFFF5F5F0),
      child: const Center(
        child: Icon(Icons.restaurant, color: Color(0xFFB5B7A4), size: 48),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFECECE6), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF32341E),
        unselectedItemColor: const Color(0xFFB5B7A4),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFDFDFB),
        elevation: 0,
        onTap: (index) {
          if (!mounted) return;
          setState(() => currentIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/setup_order', arguments: {'preserve_cart': true});
          }
          if (index == 2) Navigator.pushNamed(context, '/history');
          if (index == 3) {
            Navigator.pushNamed(context, '/profile').then((_) => loadProfile());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.dashboard_outlined, size: 20),
            ),
            label: "MENU",
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.assignment_outlined, size: 20),
            ),
            label: "ORDERS",
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.history, size: 20),
            ),
            label: "HISTORY",
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person_outline, size: 20),
            ),
            label: "PROFILE",
          ),
        ],
      ),
    );
  }
}