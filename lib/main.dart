import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
// TAMBAHAN IMPORT UNTUK NOTIFIKASI
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- IMPORT PAGES ---
import 'pages/welcome_page.dart';
import 'pages/login_page.dart'; 
import 'pages/dashboard_page.dart';
import 'pages/signup_page.dart';
import 'pages/profile_page.dart';
import 'pages/menu_gallery_page.dart';
import 'pages/menu_page.dart'; 
import 'pages/setuporder_page.dart';
import 'pages/report_page.dart';
import 'pages/history_page.dart';
import 'pages/upload_menu_page.dart';
import 'pages/stock_management_page.dart';
import 'pages/summary_page.dart'; 
import 'pages/payment_success_page.dart'; 
import 'pages/receipt_page.dart'; 

// INSTANCE GLOBAL UNTUK NOTIFIKASI
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ==========================================
// 1. DATABASE HELPER (SQLITE LOCAL)
// ==========================================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('selasar_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        images_url TEXT,
        stock INTEGER DEFAULT 1
      )
    ''');
  }
}

// ==========================================
// 2. MAIN FUNCTION (INITIALIZATION)
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI NOTIFIKASI ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Kunci orientasi ke Portrait biar UI nggak berantakan di HP
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // 1. Inisialisasi Firebase
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAX-YbhW0BHr25LSLe02Yp6FVuHlX3Z21M",
          authDomain: "selasar-pos.firebaseapp.com",
          projectId: "selasar-pos",
          storageBucket: "selasar-pos.firebasestorage.app",
          messagingSenderId: "1005640530574",
          appId: "1:1005640530574:web:3f858cad9e177d9bb9a7df",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // 2. Inisialisasi Supabase (Dengan Real-time Enabled)
    await Supabase.initialize(
      url: 'https://qvryhvpamkoykngfhcgn.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF2cnlodnBhbWtveWtuZ2ZoY2duIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NTYxMjgsImV4cCI6MjA5MjQzMjEyOH0.e0RRMehqwRpfg6r7icBAJYXxMfB0Moqkc4OIvw4WKhI',
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 10),
    );
    
    // 3. Init SQLite Local
    await DatabaseHelper.instance.database;

    debugPrint("Selasar System: Inisialisasi Berhasil");
  } catch (e) {
    debugPrint("Selasar System Error: $e");
  }

  runApp(const SelasarRuangApp());
}

// ==========================================
// 3. APP STRUCTURE & ROUTES
// ==========================================
class SelasarRuangApp extends StatelessWidget {
  const SelasarRuangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selasar Ruang POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A5D3F),
          primary: const Color(0xFF4A5D3F),
          surface: const Color(0xFFF8F9F2),
        ),
        // Global Styling buat Button biar konsisten
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      // Splash Check dulu sebelum masuk ke Login/Dashboard
      initialRoute: '/auth_check', 
      routes: {
        '/auth_check': (context) => const AuthStateCheck(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardScreen(),
        
        // Alur Order (Otomatis & Hidup)
        '/setup_order': (context) => const SetupOrderPage(),
        '/menu': (context) => const MenuPage(),
        '/summary': (context) => const OrderSummaryPage(),
        '/payment_success': (context) => const PaymentSuccessPage(),
        '/receipt': (context) => const ReceiptPage(),

        // Manajemen & Riwayat
        '/profile': (context) => const ProfilePage(),
        '/gallery': (context) => const MenuGalleryPage(),
        '/report': (context) => const ReportPage(),
        '/history': (context) => const HistoryOrderPage(),
        '/upload_menu': (context) => const UploadMenuPage(),
        '/stock_manage': (context) => const StockManagementPage(),
      },
    );
  }
}

// ==========================================
// 4. AUTH STATE CHECK (ANIMATED SPLASH)
// ==========================================
class AuthStateCheck extends StatefulWidget {
  const AuthStateCheck({super.key});

  @override
  State<AuthStateCheck> createState() => _AuthStateCheckState();
}

class _AuthStateCheckState extends State<AuthStateCheck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
    );
    _controller.forward();
    
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    // Tunggu 3 detik biar logo Selasar kelihatan estetik
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Cek Session Supabase (Otomatis Login jika sudah pernah masuk)
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A5D3F), 
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/SelasarLogo.png', 
                width: 180,
                // Fallback kalau gambar lupa ditaruh di assets
                errorBuilder: (c, e, s) => const Icon(Icons.coffee_rounded, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Color(0xFFA3B18A),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}