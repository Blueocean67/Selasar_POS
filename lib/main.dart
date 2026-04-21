import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import semua halaman agar dikenal oleh Navigator
import 'pages/login_page.dart'; 
import 'pages/dashboard_page.dart';
import 'pages/setuporder_page.dart'; 
import 'pages/menu_page.dart'; 
import 'pages/summary_page.dart';
import 'pages/payment_success_page.dart'; 
import 'pages/receipt_page.dart';
import 'pages/history_page.dart';
import 'pages/menu_gallery_page.dart';
import 'pages/report_page.dart';
import 'pages/profile_page.dart';
import 'pages/upload_menu_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengatur tampilan status bar agar estetik (transparan)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, 
  ));
  
  runApp(const SelasarRuangApp());
}

class SelasarRuangApp extends StatelessWidget {
  const SelasarRuangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selasar Ruang Cafe',
      debugShowCheckedModeBanner: false,
      
      // KONFIGURASI TEMA GLOBAL (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A5D3F),
          primary: const Color(0xFF4A5D3F),
          secondary: const Color(0xFFA3B18A),
          surface: const Color(0xFFF8F9F2),
        ),

        // FIX MERAH: Properti harus di dalam kurung CardThemeData
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEDF0E9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFFA1A1A1), fontSize: 14),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A5D3F),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
            elevation: 0,
          ),
        ),
      ),
      
      // Halaman Pertama yang Muncul
      initialRoute: '/',
      
      // DAFTAR ALAMAT NAVIGASI (Routes)
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/setup_order': (context) => const SetupOrderPage(),
        '/menu': (context) => const MenuPage(), 
        '/summary': (context) => const OrderSummaryPage(),
        '/payment_success': (context) => const PaymentSuccessPage(),
        '/receipt': (context) => const ReceiptPage(),
        '/history': (context) => const HistoryOrderPage(),
        '/gallery': (context) => const MenuGalleryPage(),
        '/report': (context) => const ReportPage(),
        '/profile': (context) => const ProfilePage(),
        '/upload_menu': (context) => const UploadMenuPage(),
      },
    );
  }
}