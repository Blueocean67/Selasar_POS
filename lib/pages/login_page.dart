import 'package:flutter/material.dart';
import '../pages/dashboard_page.dart';
import '../pages/signup_page.dart';

// Fungsi main dan App class tetap sama untuk memastikan navigasi jalan
void main() => runApp(const SelasarRuangAuth()); 

class SelasarRuangAuth extends StatelessWidget {
  const SelasarRuangAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PlusJakartaSans',
        // Background Scaffold global diset ke Hijau Gelap
        scaffoldBackgroundColor: const Color(0xFF2D3329),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEnglish = true;

  void toggleLanguage(bool english) {
    setState(() {
      isEnglish = english;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = {
      'title': isEnglish ? "Selasar Ruang Cafe" : "Selasar Ruang Kafe",
      'subtitle': isEnglish ? "Internal Management Access" : "Akses Manajemen Internal",
      'labelUser': isEnglish ? "Email or Username" : "Email atau Username",
      'hintUser': isEnglish ? "Enter your credentials" : "Masukkan kredensial anda",
      'labelPass': isEnglish ? "Password" : "Kata Sandi",
      'forgot': isEnglish ? "Forgot?" : "Lupa?",
      'buttonLogin': isEnglish ? "MASUK" : "MASUK",
      'noAccount': isEnglish ? "Don't have an account? " : "Belum punya akun? ",
      'signup': isEnglish ? "Sign Up" : "Daftar Sekarang",
    };

    return Scaffold(
      // backgroundColor dipastikan Hijau Gelap agar sama dengan Signup
      backgroundColor: const Color(0xFF2D3329),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Icon Box Sage Green
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5D1B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.coffee_maker, color: Color(0xFF4A5D3F), size: 32),
              ),
              const SizedBox(height: 16),
              
              // Judul Estetik (Warna Sage Muda)
              Text(
                lang['title']!, 
                style: const TextStyle(
                  color: Color(0xFFC5D1B5), 
                  fontSize: 26, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5
                )
              ),
              Text(lang['subtitle']!, 
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
              
              const SizedBox(height: 40),

              // KOTAK PUTIH (FORM CONTAINER)
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputField(
                      label: lang['labelUser']!,
                      hint: lang['hintUser']!,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: lang['labelPass']!,
                      hint: "••••••••",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      trailing: Text(lang['forgot']!, 
                        style: const TextStyle(color: Color(0xFF4A5D3F), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 32),
                    
                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5D3F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(lang['buttonLogin']!, 
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Navigasi ke Signup
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const SignupPage()),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: lang['noAccount'],
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: lang['signup'],
                                style: const TextStyle(
                                  color: Color(0xFF5C6E3E), 
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Center(
                      child: Text("Shift Management System v2.4.0", 
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tombol Bahasa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _langButton("English", active: isEnglish, onTap: () => toggleLanguage(true)),
                        const SizedBox(width: 8),
                        _langButton("Indonesia", active: !isEnglish, onTap: () => toggleLanguage(false)),
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Gambar Cafe di bawah kotak
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  "https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=300", 
                  width: 200, height: 100, fit: BoxFit.cover,
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                child: Text(
                  "© 2026 Selasar Ruang Cafe. Crafted for focus and productivity.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Input Field
  Widget _buildInputField({
    required String label, 
    required String hint, 
    required IconData icon, 
    bool isPassword = false,
    Widget? trailing
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5D3F))),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEDF0E9),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.black45, size: 20),
            suffixIcon: isPassword ? const Icon(Icons.visibility_outlined, color: Colors.black45, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  // Helper Tombol Bahasa
  Widget _langButton(String text, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4A5D3F).withOpacity(0.1) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: active ? Border.all(color: const Color(0xFF4A5D3F), width: 1) : null,
        ),
        child: Text(text, 
          style: TextStyle(
            fontSize: 10, 
            color: active ? const Color(0xFF4A5D3F) : Colors.black54,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}