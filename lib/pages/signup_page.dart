import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isEnglish = true;

  void toggleLanguage(bool english) {
    setState(() {
      isEnglish = english;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dictionary untuk Multi-bahasa
    final lang = {
      'title': isEnglish ? "Daftar Akun" : "Daftar Akun",
      'subtitle': isEnglish ? "Create your workspace access" : "Buat akses manajemen anda",
      'labelName': isEnglish ? "Full Name" : "Nama Lengkap",
      'labelEmail': isEnglish ? "Email Address" : "Alamat Email",
      'labelPhone': isEnglish ? "Phone Number" : "Nomor Telepon",
      'labelPass': isEnglish ? "Password" : "Kata Sandi",
      'buttonSignup': isEnglish ? "DAFTAR" : "DAFTAR",
      'googleSignup': isEnglish ? "Sign Up with Google" : "Daftar dengan Google",
      'hasAccount': isEnglish ? "Already have an account? " : "Sudah punya akun? ",
      'login': isEnglish ? "Login" : "Masuk",
    };

    return Scaffold(
      backgroundColor: const Color(0xFF2D3329),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Icon Coffee Maker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5D1B5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.coffee_maker, color: Color(0xFF4A5D3F), size: 32),
              ),
              const SizedBox(height: 16),
              
              // Judul
              Text(
                lang['title']!, 
                style: const TextStyle(
                  color: Color(0xFFC5D1B5), 
                  fontSize: 26, 
                  fontWeight: FontWeight.bold
                )
              ),
              Text(lang['subtitle']!, 
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
              
              const SizedBox(height: 40),

              // Form Container
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(28), // Disamakan dengan padding Login
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(lang['labelName']!),
                    const CustomInput(hint: "John Doe", icon: Icons.person_outline),
                    const SizedBox(height: 15),
                    
                    _buildLabel(lang['labelEmail']!),
                    const CustomInput(hint: "example@mail.com", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),

                    _buildLabel(lang['labelPhone']!),
                    const CustomInput(hint: "0812xxxx", icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 15),

                    _buildLabel(lang['labelPass']!),
                    const CustomInput(hint: "••••••••", icon: Icons.lock_outline, isPassword: true),
                    
                    const SizedBox(height: 32),
                    
                    // Button Daftar
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: lang['buttonSignup']!,
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Google Signup
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55), // Tinggi disamakan tombol utama
                        side: const BorderSide(color: Color(0xFF4A5D3F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, size: 30, color: Color(0xFF4A5D3F)),
                      label: Text(lang['googleSignup']!, style: const TextStyle(color: Color(0xFF4A5D3F), fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 20),

                    // Switch ke Login
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: lang['hasAccount'],
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: lang['login'],
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
                    
                    // Language Buttons
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
              
              // Image Cafe
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5D3F))),
    );
  }

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