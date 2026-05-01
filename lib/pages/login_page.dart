import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/dashboard_page.dart';
import '../pages/signup_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEnglish = true;
  bool isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String cafeImageUrl = "https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=2047&auto=format&fit=crop";

  void toggleLanguage(bool english) {
    setState(() => isEnglish = english);
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEnglish ? "Please enter email and password" : "Mohon masukkan email dan kata sandi")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEnglish ? "Login Failed: Check your connection" : "Login Gagal: Periksa koneksi anda")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = {
      'title': "Selasar Ruang",
      'subtitle': isEnglish ? "Internal Management Access" : "Akses Manajemen Internal",
      'labelUser': isEnglish ? "Email Address" : "Alamat Email",
      'hintUser': "staff@selasar.com",
      'labelPass': isEnglish ? "Password" : "Kata Sandi",
      'forgot': isEnglish ? "Forgot Password?" : "Lupa Sandi?",
      'buttonLogin': isEnglish ? "LOGIN" : "MASUK",
      'noAccount': isEnglish ? "New staff? " : "Staf baru? ",
      'signup': isEnglish ? "Create Account" : "Buat Akun",
    };

    return Scaffold(
      backgroundColor: const Color(0xFF2D3329),
      body: Stack(
        children: [
          // 1. Background Image (Full Screen agar lebih menyatu)
          Positioned.fill(
            child: Image.network(
              cafeImageUrl,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Overlay Gelap (Biar tulisan atas dan bawah JELAS)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D3329).withOpacity(0.9), // Gelap di atas (Logo)
                    const Color(0xFF2D3329).withOpacity(0.7), // Agak transparan di tengah
                    const Color(0xFF2D3329).withOpacity(0.95), // Sangat gelap di bawah (Signup)
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // --- LOGO SECTION (Dikasih Glow Halus) ---
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC5D1B5).withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Image.asset('assets/images/SelasarLogo.png', width: 120, height: 120),
                    ),
                  ),
                  Text(lang['title']!, style: const TextStyle(color: Color(0xFFC5D1B5), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text(lang['subtitle']!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, letterSpacing: 1.2)),
                  
                  const SizedBox(height: 40),

                  // --- LOGIN CARD ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9F2).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                controller: _emailController,
                                label: lang['labelUser']!,
                                hint: lang['hintUser']!,
                                icon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildInputField(
                                controller: _passwordController,
                                label: lang['labelPass']!,
                                hint: "••••••••",
                                icon: Icons.lock_person_outlined,
                                isPassword: !_isPasswordVisible,
                                trailing: GestureDetector(
                                  onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  child: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: const Color(0xFF4A5D3F)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(lang['forgot']!, style: const TextStyle(color: Color(0xFF4A5D3F), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A5D3F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF4A5D3F).withOpacity(0.4),
                                  ),
                                  child: isLoading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(lang['buttonLogin']!, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  
                  // --- SIGNUP (Sekarang Pasti Kelihatan karena ada Gradient Gelap di belakang) ---
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3), // Background tipis buat tulisan
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: lang['noAccount'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          children: [
                            TextSpan(text: lang['signup'], style: const TextStyle(color: Color(0xFFC5D1B5), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _langButton("EN", active: isEnglish, onTap: () => toggleLanguage(true)),
                      const SizedBox(width: 15),
                      _langButton("ID", active: !isEnglish, onTap: () => toggleLanguage(false)),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isPassword = false, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
            prefixIcon: Icon(icon, color: const Color(0xFF4A5D3F), size: 20),
            suffixIcon: trailing,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _langButton(String text, {required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC5D1B5) : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC5D1B5), width: 1.5),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: active ? const Color(0xFF4A5D3F) : Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}