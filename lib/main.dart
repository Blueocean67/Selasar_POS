import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// --- IMPORT MODELS & PROVIDERS ---
import 'package:selasar_pos/provider/promo_provider.dart';

// --- IMPORT ALL PAGES ---
import 'package:selasar_pos/pages/welcome_page.dart';
import 'package:selasar_pos/pages/login_page.dart';
import 'package:selasar_pos/pages/signup_page.dart';
import 'package:selasar_pos/pages/dashboard_page.dart';
import 'package:selasar_pos/pages/menu_page.dart';
import 'package:selasar_pos/pages/menu_gallery_page.dart';
import 'package:selasar_pos/pages/setuporder_page.dart';
import 'package:selasar_pos/pages/summary_page.dart';
import 'package:selasar_pos/pages/stock_management_page.dart';
import 'package:selasar_pos/pages/upload_menu_page.dart';
import 'package:selasar_pos/pages/report_page.dart';
import 'package:selasar_pos/pages/history_page.dart';
import 'package:selasar_pos/pages/payment_success_page.dart';
import 'package:selasar_pos/pages/receipt_page.dart';
import 'package:selasar_pos/pages/profile_page.dart';
import 'package:selasar_pos/pages/promo_page.dart'; 
import 'package:selasar_pos/pages/form_promo_page.dart'; 

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Perantara global agar OrderHistoryManager bisa berkomunikasi langsung dengan PromoProvider pendata stok
late BuildContext globalAppContext;

// ============================================================
//  MAIN INTI ENTRY POINT
// ============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Notifikasi Lokal
  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initAndroid),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Supabase.initialize(
      url: 'https://qvryhvpamkoykngfhcgn.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2cnlodnBhbWtveWtuZ2ZoY2duIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NTYxMjgsImV4cCI6MjA5MjQzMjEyOH0.e0RRMehqwRpfg6r7icBAJYXxMfB0Moqkc4OIvw4WKhI',
      realtimeClientOptions:
          const RealtimeClientOptions(eventsPerSecond: 10),
    );
    
    await DatabaseHelper.instance.database;
    debugPrint('Selasar System: Ready ✓');
  } catch (e) {
    debugPrint('Selasar System Initialization Bypassed (Running Sandbox Mode): $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => OrderHistoryManager()), 
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(
          create: (_) => PromoProvider()
            ..fetchPromosFromDatabase()
            ..listenToStockChanges(),
        ),
      ],
      child: const SelasarRuangApp(),
    ),
  );
}

// ============================================================
//  ROOT APP & DYNAMIC ROUTING CONFIGURATION
// ============================================================
class SelasarRuangApp extends StatelessWidget {
  const SelasarRuangApp({super.key});

  @override
  Widget build(BuildContext context) {
    globalAppContext = context; // Kunci context global di root widget

    return MaterialApp(
      title: 'Selasar Ruang POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          surface: AppTheme.background,
        ),
      ),
      initialRoute: '/auth_check',
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            switch (settings.name) {
              case '/auth_check': return const AuthStateCheck();
              case '/welcome': return const WelcomePage();
              case '/login': return const LoginScreen();
              case '/signup': return const SignupPage();
              case '/dashboard': return const DashboardPage();
              case '/order_summary': return const OrderSummaryPage();
              case '/promo': return const PromoPage();
              case '/form_promo': return const FormPromoPage();
              case '/setup_order': return const SetupOrderPage();
              case '/payment_success': return const PaymentSuccessPage();
              case '/receipt': return const ReceiptPage();
              case '/menu': return const MenuPage();
              case '/menu_gallery': return const MenuGalleryPage();
              case '/upload_menu': return const UploadMenuPage();
              case '/stock_manage': return const StockManagementPage();
              case '/report': return const ReportPage();
              case '/history': return const HistoryOrderPage();
              case '/profile': return const ProfilePage();
              default: return const DashboardPage();
            }
          },
        );
      },
    );
  }
}

// ============================================================
//  ORDER STATUS ALUR CONSTANTS
// ============================================================
class OrderStatus {
  static const String pending = 'pending';
  static const String sedangDibuat = 'sedang_dibuat';
  static const String siap = 'siap';
  static const String completed = 'completed';

  static const List<String> activeStatuses = [pending, sedangDibuat, siap];

  static String label(String status) {
    switch (status) {
      case pending: return 'DIPROSES';
      case sedangDibuat: return 'SEDANG DIBUAT';
      case siap: return 'SIAP';
      case completed: return 'SELESAI';
      default: return 'PROSES';
    }
  }

  static String? next(String current) {
    switch (current) {
      case pending: return sedangDibuat;
      case sedangDibuat: return siap;
      case siap: return completed;
      default: return null;
    }
  }

  static bool isDone(String status) => status == completed;

  static int durationSeconds(String status) {
    switch (status) {
      case pending: return 10;
      case sedangDibuat: return 15;
      case siap: return 8;
      default: return 0;
    }
  }
}

// ============================================================
//  ORDER HISTORY MANAGER (AUTOMATIC SINKRONISASI POTONG STOK LOKAL)
// ============================================================
class OrderHistoryManager with ChangeNotifier {
  final List<Map<String, dynamic>> _allOrders = [];
  Timer? _simulationTimer;
  Timer? _autoOrderTimer;
  int _idCounter = 98400;
  final Random _random = Random();

  List<Map<String, dynamic>> get allOrders => List.unmodifiable(_allOrders);
  List<Map<String, dynamic>> get localOrders => _allOrders;

  int get todaySalesOmzet {
    int sum = 0;
    for (var order in _allOrders) {
      sum += (order['total_price'] ?? 0) as int;
    }
    return sum;
  }

  static const List<String> _menuPool = [
    'Nasi Goreng', 'Mie Banglades', 'Ayam Pop',
    'Aceh Gayo V60', 'Signature Selasar Latte', 'Jus Strawberry', 'Almonds Chocolate',
    'Cheesecake', 'Nasi Beef Teriyaki', 'Matcha Latte', 'Donat',
    'Burger', 'Ayam Sambal Geprek', 'Cookies', 'Kopi Gula Aren',
  ];

  OrderHistoryManager() {
    _generatePastCalendarDummyData();
    _startLiveSimulationEngine();
    _startAutoOrderSimulation();
  }

  void _generatePastCalendarDummyData() {
    final now = DateTime.now();

    final dateConfigs = [
      {'date': now, 'label': 'Hari ini'},
      {'date': now.subtract(const Duration(days: 1)), 'label': 'Kemarin'},
      {'date': now.subtract(const Duration(days: 2)), 'label': '2 hari lalu'},
    ];

    final dummyEntries = [
      _buildDummyEntry(name: 'Rian Baskoro',   hour: 18, minute: 45, price: 210000, items: 5, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Amalia Putri',   hour: 16, minute: 10, price: 120000, items: 4, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Budi Santoso',   hour: 14, minute: 20, price: 145000, items: 3, status: OrderStatus.sedangDibuat, activeMinutesAgo: 2),
      _buildDummyEntry(name: 'Siti Rahma',     hour: 9,  minute: 15, price: 82500,  items: 2, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Wahyu Saputra',  hour: 20, minute: 5,  price: 175000, items: 4, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Lina Marlinda',  hour: 17, minute: 30, price: 95000,  items: 3, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Doni Firmansyah',hour: 13, minute: 0,  price: 250000, items: 6, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Rini Wulandari', hour: 10, minute: 45, price: 62000,  items: 2, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Teguh Santoso',  hour: 19, minute: 20, price: 185000, items: 5, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Mega Ratnasari', hour: 15, minute: 55, price: 105000, items: 3, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Eko Prasetyo',   hour: 12, minute: 10, price: 78000,  items: 2, status: OrderStatus.completed),
      _buildDummyEntry(name: 'Fitri Handayani',hour: 8,  minute: 30, price: 135000, items: 4, status: OrderStatus.completed),
    ];

    final dateList = dateConfigs.map((d) => d['date'] as DateTime).toList();
    for (int i = 0; i < dummyEntries.length; i++) {
      final dateIndex = i ~/ 4; 
      final dateBase = dateList[dateIndex < dateList.length ? dateIndex : dateList.length - 1];
      final entry = dummyEntries[i];

      final int h = entry['_hour'] as int;
      final int m = entry['_minute'] as int;
      final DateTime createdAt = DateTime(dateBase.year, dateBase.month, dateBase.day, h, m);

      final cleanEntry = Map<String, dynamic>.from(entry)
        ..remove('_hour')
        ..remove('_minute');

      cleanEntry['created_at'] = createdAt.toIso8601String();
      cleanEntry['id'] = (_idCounter++).toString();
      cleanEntry['payment_method'] = 'QRIS';
      cleanEntry['menu_items'] ??= _randomMenuItems(entry['items_count'] as int);

      _allOrders.add(cleanEntry);
    }
  }

  Map<String, dynamic> _buildDummyEntry({
    required String name,
    required int hour,
    required int minute,
    required int price,
    required int items,
    required String status,
    int activeMinutesAgo = 0,
  }) {
    final now = DateTime.now();
    DateTime? nextStatusAt;

    if (!OrderStatus.isDone(status) && activeMinutesAgo > 0) {
      nextStatusAt = now.add(Duration(seconds: OrderStatus.durationSeconds(status)));
    }

    return {
      '_hour': hour,
      '_minute': minute,
      'customer_name': name,
      'total_price': price,
      'items_count': items,
      'status': status,
      'next_status_at': nextStatusAt?.toIso8601String(),
      'menu_items': null,
    };
  }

  List<Map<String, dynamic>> _randomMenuItems(int count) {
    final shuffled = List<String>.from(_menuPool)..shuffle();
    final selected = shuffled.take(count.clamp(1, _menuPool.length)).toList();
    return selected.map((name) {
      final qty = 1 + (_random.nextInt(2));
      return {'name': name, 'qty': qty};
    }).toList();
  }

  Future<void> _triggerPushNotification(String title, String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'selasar_pos_channel', 'Selasar POS Transactions',
      channelDescription: 'Notifikasi Order Realtime Selasar Ruang Cafe',
      importance: Importance.max, priority: Priority.high,
    );
    await flutterLocalNotificationsPlugin.show(
      _random.nextInt(100000), title, message,
      const NotificationDetails(android: androidDetails),
    );
  }

  // AUTOMATIC REALTIME ENGINE PENGURANGAN STOK VIA PEMBELIAN KASIR & SIMULASI MASUK
  void _executeAutomaticStockReduction(List<Map<String, dynamic>> items) {
    try {
      final promoProvider = globalAppContext.read<PromoProvider>();
      
      for (var item in items) {
        final String name = (item['name'] ?? item['menu_name'] ?? '').toString().trim();
        final int qty = ((item['qty'] ?? item['quantity'] ?? 1) as num).toInt();

        if (name.isNotEmpty) {
          final match = promoProvider.allMenusWithStock.firstWhere(
            (element) => element['name'].toString().trim().toLowerCase() == name.toLowerCase(),
            orElse: () => {},
          );

          if (match.isNotEmpty) {
            final String menuId = match['id'].toString();
            int currentStock = ((match['stock'] ?? 20) as num).toInt();
            if (currentStock == 9999 || currentStock < 0) currentStock = 20;

            int finalUpdatedStock = (currentStock - qty).clamp(0, 99999);
            
            // Pengurangan stok dieksekusi secara instan dan global ke state pusat
            promoProvider.updateStock(menuId, finalUpdatedStock);
          }
        }
      }
    } catch (e) {
      debugPrint("Realtime Automatic Stock Engine Exception: $e");
    }
  }

  void _startLiveSimulationEngine() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool hasChanges = false;
      final now = DateTime.now();

      for (int i = 0; i < _allOrders.length; i++) {
        final order = _allOrders[i];
        final String currentStatus = order['status']?.toString() ?? OrderStatus.completed;

        if (OrderStatus.isDone(currentStatus)) continue;

        final String? nextStatusAt = order['next_status_at']?.toString();
        if (nextStatusAt == null) continue;

        DateTime? nextTime = DateTime.tryParse(nextStatusAt);
        if (nextTime != null && now.isAfter(nextTime)) {
          final String? nextStatus = OrderStatus.next(currentStatus);
          if (nextStatus != null) {
            final updatedOrder = Map<String, dynamic>.from(order);
            updatedOrder['status'] = nextStatus;

            if (!OrderStatus.isDone(nextStatus)) {
              updatedOrder['next_status_at'] = now
                  .add(Duration(seconds: OrderStatus.durationSeconds(nextStatus)))
                  .toIso8601String();
            } else {
              updatedOrder['next_status_at'] = null;
            }

            _allOrders[i] = updatedOrder;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) notifyListeners();
    });
  }

  void _startAutoOrderSimulation() {
    _scheduleNextAutoOrder();
  }

  void _scheduleNextAutoOrder() {
    final delaySeconds = 30 + (_random.nextInt(16)); 
    _autoOrderTimer = Timer(Duration(seconds: delaySeconds), () {
      _injectSimulatedOrder();
      _scheduleNextAutoOrder(); 
    });
  }

  void _injectSimulatedOrder() {
    final names = [
      'Fajar Nugroho', 'Indah Permata', 'Rizky Pratama', 'Dewi Sartika',
      'Hendra Kusuma', 'Nadia Rahayu', 'Agus Setiawan', 'Yuni Astuti',
    ];
    final name = names[_random.nextInt(names.length)];
    final itemsCount = 1 + _random.nextInt(3);
    final totalPrice = itemsCount * 23000;

    addLiveOrderFromCashier(
      customerName: name,
      totalPrice: totalPrice,
      itemsCount: itemsCount,
    );
    
    _triggerPushNotification("Order pesanan diterima", "Pesanan baru dari $name berhasil ditambahkan!");
  }

  void addLiveOrderFromCashier({
    required String customerName,
    required int totalPrice,
    required int itemsCount,
  }) {
    final String newId = (_idCounter++).toString();
    final DateTime now = DateTime.now();
    final randomItems = _randomMenuItems(itemsCount);

    final newOrder = _buildOrder(
      id: newId,
      customerName: customerName,
      createdAt: now,
      totalPrice: totalPrice,
      itemsCount: itemsCount,
      status: OrderStatus.pending,
      menuItems: randomItems,
    );

    // Otomatis kurangi stok saat pesanan simulasi masuk
    _executeAutomaticStockReduction(randomItems);

    _allOrders.insert(0, newOrder);
    notifyListeners();
  }

  Future<void> addOrder(Map<String, dynamic> orderData) async {
    final now = DateTime.now();
    final int itemsCount = orderData['items_count'] ?? 1;
    final int total = (orderData['total_price'] ?? orderData['total'] ?? 0).toInt();

    final List<Map<String, dynamic>> menuItemsList = orderData['items'] is List 
        ? List<Map<String, dynamic>>.from(orderData['items']) 
        : _randomMenuItems(itemsCount);

    final cleanPayload = _buildOrder(
      id: (_idCounter++).toString(),
      customerName: orderData['customer_name'] ?? 'Pelanggan Walk-in',
      createdAt: now,
      totalPrice: total,
      itemsCount: itemsCount,
      status: OrderStatus.pending,
      menuItems: menuItemsList,
    );

    cleanPayload['payment_method'] = orderData['payment_method'] ?? 'Tunai';

    // Otomatis potong stok saat kasir memproses checkout pembayaran berhasil
    _executeAutomaticStockReduction(menuItemsList);

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('transactions').insert({
        'total_price': cleanPayload['total_price'],
        'payment_status': 'SUCCESS',
        'cashier_name': 'Kasir Selasar',
        'items_count': cleanPayload['items_count'],
        'product_summary': (cleanPayload['menu_items'] as List).map((e) => "${e['name']} (${e['qty']})").join(", ")
      });
    } catch (e) {
      debugPrint("Koneksi Supabase dilewati, mode offline aman: $e");
    }

    _allOrders.insert(0, cleanPayload);
    notifyListeners();

    _triggerPushNotification("Transaksi Berhasil", "Pembayaran POS Berhasil. Silakan Cetak Struk.");
  }

  Map<String, dynamic> _buildOrder({
    required String id,
    required String customerName,
    required DateTime createdAt,
    required int totalPrice,
    required int itemsCount,
    required String status,
    required List<Map<String, dynamic>> menuItems,
  }) {
    final DateTime nextTime = createdAt.add(Duration(seconds: OrderStatus.durationSeconds(status)));

    return {
      'id': id,
      'customer_name': customerName,
      'created_at': createdAt.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'items_count': itemsCount,
      'menu_items': menuItems, 
      'next_status_at': OrderStatus.isDone(status) ? null : nextTime.toIso8601String(),
    };
  }

  void setOrders(List<Map<String, dynamic>> orders) {
    if (orders.isNotEmpty) {
      _allOrders.clear();
      _allOrders.addAll(orders);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _autoOrderTimer?.cancel();
    super.dispose();
  }
}

// ============================================================
//  LOCALIZATION PROVIDER
// ============================================================
class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'greeting_morning': {'id': 'SELAMAT DATANG', 'en': 'GOOD MORNING'},
    'dashboard_title':  {'id': 'Dashboard\nRingkasan', 'en': 'Dashboard\nSummary'},
    'app_version':      {'id': 'Selasar POS Sistem v2.4.0', 'en': 'Selasar POS System v2.4.0'},
  };

  static String get(String key, bool isEnglish) {
    final entry = _strings[key];
    if (entry == null) return key; 
    return isEnglish ? (entry['en'] ?? key) : (entry['id'] ?? key);
  }
}

class LocalizationProvider with ChangeNotifier {
  bool _isEnglish = false; 
  bool get isEnglish => _isEnglish;
  void toggleLanguage() { _isEnglish = !_isEnglish; notifyListeners(); }
  String t(String key) => AppStrings.get(key, _isEnglish);
}

// ============================================================
//  FALLBACK STATE PROVIDER INTEGRATION
// ============================================================
class CartProvider with ChangeNotifier {
  final Map<String, int> _items = {};
  Map<String, int> get items => _items;
  void clear() { _items.clear(); notifyListeners(); }
}
class StockProvider with ChangeNotifier { void refresh() { notifyListeners(); } }
class ReportProvider with ChangeNotifier { void refresh() { notifyListeners(); } }
class DashboardProvider with ChangeNotifier { void refresh() { notifyListeners(); } }
class MenuProvider with ChangeNotifier { void refresh() { notifyListeners(); } }

// ============================================================
//  APP THEME & DATABASE HELPER
// ============================================================
class AppTheme {
  static const Color primary    = Color(0xFF4A5D3F);
  static const Color accent     = Color(0xFFA3B18A);
  static const Color background = Color(0xFFF8F9F2);
  static const Color textPrimary = Color(0xFF2D3329);
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('selasar_pos.db'); return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE menus (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, price INTEGER NOT NULL, images_url TEXT, stock INTEGER DEFAULT 1)');
    });
  }
}

// ============================================================
//  SPLASH SCREEN PREMIUM (ANIMASI LOGO & BRANDING)
// ============================================================
class AuthStateCheck extends StatefulWidget {
  const AuthStateCheck({super.key});

  @override
  State<AuthStateCheck> createState() => _AuthStateCheckState();
}

class _AuthStateCheckState extends State<AuthStateCheck> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    _startNavigationTimer();
  }

  void _startNavigationTimer() async {
    // Memberi jeda waktu 2.5 detik untuk memperlihatkan keindahan logo cafe
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Ornamen Background Estetik ala Selasar Cafe
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.06),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wadah Logo Berbentuk Lingkaran Premium dengan Bayangan Halus
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.12),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/SelasarLogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.coffee_rounded,
                              size: 65,
                              color: AppTheme.primary,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Judul Utama Sistem Manajemen POS
                  const Text(
                    "SELASAR RUANG",
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Slogan Penunjang agar Terlihat Profesional saat Demo
                  Text(
                    "Selasar Cafe Management System for Specialty Coffee",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary.withOpacity(0.45),
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Indikator Loading Kecil dan Bersih di Bagian Bawah Layar
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withOpacity(0.6)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}