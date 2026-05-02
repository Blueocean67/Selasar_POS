import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; 

class AppColors {
  static const primaryGreen = Color(0xFF4A5D3F);
  static const secondaryGreen = Color(0xFFC5D1B5);
  static const background = Color(0xFFF8F9F2);
  static const textPrimary = Color(0xFF2D3329);
  static const textSecondary = Color(0xFF7A7A7A);
  static const accentGold = Color(0xFFBC8E5B);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String greeting = "";
  List<Map<String, dynamic>> timeBasedMenus = [];
  String? avatarUrl;
  String staffName = "Fadilah";
  String userRole = "staff"; // Tambahan variabel role
  StreamSubscription? _stockSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _updateTimeBasedRecommendation();
    _listenToLowStock();
  }

  @override
  void dispose() {
    _stockSubscription?.cancel();
    super.dispose();
  }

  void _listenToLowStock() {
    _stockSubscription = Supabase.instance.client
        .from('menus')
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
      for (var menu in data) {
        int stock = (menu['stock'] ?? 0) as int;
        if (stock < 5 && stock > 0) {
          _sendSystemNotification(menu['name'], stock);
        }
      }
    });
  }

  Future<void> _sendSystemNotification(String name, int stock) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'selasar_stok_alert', 'Stok Selasar',
      importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher',
    );
    await flutterLocalNotificationsPlugin.show(
      name.hashCode, 'Stok Mau Habis! ⚠️', 'Menu $name sisa $stock porsi lagi nih, Fad.',
      const NotificationDetails(android: androidDetails),
    );
  }

  Stream<int> _getTodayRevenue() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((order) => order['created_at'].toString().contains(today))
            .fold(0, (sum, item) => sum + ((item['total_price'] ?? 0) as int)));
  }

  Stream<int> _getOccupiedTables() {
    return Supabase.instance.client
        .from('tables')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((t) => t['status'] == 'occupied').length);
  }

  Stream<List<Map<String, dynamic>>> _getLowStockAlerts() {
    return Supabase.instance.client
        .from('menus')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((m) => ((m['stock'] ?? 0) as int) < 5 && ((m['stock'] ?? 0) as int) > 0).toList());
  }

  // UPDATE: Fungsi load profile sekarang ambil role dari tabel profiles
  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role, full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          avatarUrl = user.userMetadata?['avatar_url'];
          staffName = data['full_name'] ?? user.userMetadata?['full_name'] ?? "Fadilah";
          userRole = data['role'] ?? "staff";
        });
      } catch (e) {
        // Fallback jika data profile belum ada
        setState(() {
          avatarUrl = user.userMetadata?['avatar_url'];
          staffName = user.userMetadata?['full_name'] ?? "Fadilah";
        });
      }
    }
  }

  void _updateTimeBasedRecommendation() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 5 && hour < 11) {
        greeting = "Selamat Pagi, $staffName!";
        timeBasedMenus = [
          {"title": "Kopi Gula Aren", "price": "Rp 25.000", "tag": "MORNING BOOST", "img": "assets/images/kopigulaaren.webp"},
          {"title": "Roti Bakar", "price": "Rp 15.000", "tag": "LIGHT BREAKFAST", "img": "assets/images/RotiBakar.jpg"},
        ];
      } else if (hour >= 11 && hour < 17) {
        greeting = "Selamat Siang, $staffName!";
        timeBasedMenus = [
          {"title": "Nasi Goreng", "price": "Rp 30.000", "tag": "LUNCH SPECIAL", "img": "assets/images/nasigoreng.jpg"},
          {"title": "Es Teh Manis", "price": "Rp 10.000", "tag": "FRESH DRINK", "img": "assets/images/lemontea.jpg"},
        ];
      } else {
        greeting = "Selamat Malam, $staffName!";
        timeBasedMenus = [
          {"title": "Mie Bangladesh", "price": "Rp 25.000", "tag": "NIGHT TREAT", "img": "assets/images/Miebangladesh.jpg"},
          {"title": "Hot Chocolate", "price": "Rp 25.000", "tag": "WARM NIGHT", "img": "assets/images/AlmondsChocolate.jpg"},
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  // UPDATE: Cuma Admin yang liat kartu Omzet
                  if (userRole == 'admin') _buildMainStatsCard(),
                  const SizedBox(height: 30),
                  const Text("Akses Manajemen", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 15),
                  _buildStatusGrid(),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Rekomendasi Waktu", Icons.access_time_filled),
                  const SizedBox(height: 15),
                  ...timeBasedMenus.map((menu) => MenuCard(data: menu)),
                  const SizedBox(height: 30),
                  
                  const Text("Trend Selasar", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 15),
                  _buildMenuAnalysisGrid(),

                  const SizedBox(height: 30),
                  _buildDynamicMenuSections(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDialFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildMenuAnalysisGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9, 
      children: [
        _analysisCard("TERLARIS", "Amerikano", "assets/images/Amerikano.jpg", Colors.orange),
        _analysisCard("TERPOPULER", "Matcha Latte", "assets/images/matchalatte.webp", Colors.green),
        _analysisCard("DISUKAI", "Gula Aren", "assets/images/kopigulaaren.webp", Colors.brown),
        _analysisCard("STOK LIMIT", "Aceh Gayo", "assets/images/acehgayov60.png", Colors.red),
      ],
    );
  }

  Widget _analysisCard(String label, String menu, String img, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/menu'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(img, fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(menu, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
      actions: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getLowStockAlerts(),
          builder: (context, snapshot) {
            final alerts = snapshot.data ?? [];
            return IconButton(
              onPressed: () => _showNotificationCenter(alerts), 
              icon: Icon(Icons.notifications_active_outlined, color: alerts.isNotEmpty ? Colors.red : AppColors.primaryGreen)
            );
          }
        ),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 8),
      child: CircleAvatar(
        radius: 18, backgroundColor: AppColors.primaryGreen,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
      ),
    );
  }

  Widget _buildMainStatsCard() {
    return StreamBuilder<int>(
      stream: _getTodayRevenue(),
      builder: (context, snapshot) {
        final revenue = snapshot.data ?? 0;
        return Container(
          width: double.infinity, padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryGreen, Color(0xFF5B714D)]),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ESTIMASI OMZET HARI INI", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Text("Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(revenue)}", 
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _buildTableStatusInfo(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTableStatusInfo() {
    return StreamBuilder<int>(
      stream: _getOccupiedTables(),
      builder: (context, snapshot) {
        final occupied = snapshot.data ?? 0;
        return Row(
          children: [
            const Icon(Icons.chair_alt_rounded, color: AppColors.secondaryGreen, size: 16),
            const SizedBox(width: 8),
            Text("$occupied Meja Terisi (Total 20)", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        );
      }
    );
  }

  Widget _buildDynamicMenuSections() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('menus').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final allMenus = snapshot.data!;
        final lowStockMenus = allMenus.where((m) => ((m['stock'] ?? 0) as int) < 10 && ((m['stock'] ?? 0) as int) > 0).take(2).toList();

        return Column(
          children: [
            if (lowStockMenus.isNotEmpty) ...[
              _buildSectionHeader("Hampir Habis", Icons.warning_amber_rounded),
              const SizedBox(height: 10),
              ...lowStockMenus.map((m) => MenuCard(data: {
                "title": m['name'],
                "price": "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(m['price'])}",
                "tag": "STOK TERBATAS",
                "img": m['images_url'] ?? "assets/images/kopigulaaren.webp",
                "stock": m['stock']
              })),
            ],
          ],
        );
      }
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
        Icon(icon, color: AppColors.accentGold, size: 20),
      ],
    );
  }

  // UPDATE: Grid sekarang disesuaikan dengan role
  Widget _buildStatusGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (userRole == 'admin') _statusItem("Laporan", Icons.analytics_rounded, '/report'),
        _statusItem("History", Icons.history_edu_rounded, '/history'),
        if (userRole == 'admin') _statusItem("Stok", Icons.inventory_rounded, '/stock_manage'),
        _statusItem("Menu", Icons.restaurant_menu_rounded, '/menu'),
      ],
    );
  }

  Widget _statusItem(String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: Icon(icon, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSpeedDialFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primaryGreen,
      onPressed: () => Navigator.pushNamed(context, '/menu'),
      child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
    );
  }

  void _showNotificationCenter(List<Map<String, dynamic>> alerts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("NOTIFIKASI STOK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            if (alerts.isEmpty) const Text("Semua stok aman, Fad!"),
            ...alerts.map((a) => ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text("${a['name']} Hampir Habis!"),
              subtitle: Text("Sisa Stok: ${a['stock']}"),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.grid_view_rounded, color: AppColors.primaryGreen)),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/history'), icon: const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary)),
          const SizedBox(width: 40), 
          // Tombol report di bottom nav juga disembunyikan untuk non-admin
          if (userRole == 'admin') IconButton(onPressed: () => Navigator.pushNamed(context, '/report'), icon: const Icon(Icons.analytics_outlined, color: AppColors.textSecondary)),
          IconButton(onPressed: () => Navigator.pushNamed(context, '/profile'), icon: const Icon(Icons.person_pin_rounded, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const MenuCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/menu'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20), 
              child: Image.asset(data['img']!, width: 70, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['tag']!, style: const TextStyle(color: AppColors.accentGold, fontSize: 9, fontWeight: FontWeight.w900)),
                  Text(data['title']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(data['price']!, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryGreen)),
                ],
              ),
            ),
            const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primaryGreen, size: 22),
          ],
        ),
      ),
    );
  }
}