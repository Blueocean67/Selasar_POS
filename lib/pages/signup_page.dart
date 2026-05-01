import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isEnglish = true;
  bool isLoading = false;
  bool _isPasswordVisible = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // URL Foto Cafe seragam dengan Login
  final String cafeImageUrl = "https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=2047&auto=format&fit=crop";

  void toggleLanguage(bool english) {
    setState(() => isEnglish = english);
  }

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEnglish ? "Please complete all fields" : "Mohon lengkapi semua data")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? "Registration successful! Please login." : "Akun berhasil dibuat! Silahkan login."),
            backgroundColor: const Color(0xFF4A5D3F),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEnglish ? "Registration Failed" : "Gagal Daftar: Periksa koneksi anda"), backgroundColor: Colors.redAccent),
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
      'subtitle': isEnglish ? "Create Staff Account" : "Buat Akun Staf Baru",
      'labelName': isEnglish ? "Full Name" : "Nama Lengkap",
      'labelEmail': isEnglish ? "Email Address" : "Alamat Email",
      'labelPhone': isEnglish ? "Phone Number" : "Nomor Telepon",
      'labelPass': isEnglish ? "Password" : "Kata Sandi",
      'buttonSignup': isEnglish ? "REGISTER" : "DAFTAR",
      'hasAccount': isEnglish ? "Already a staff? " : "Sudah jadi staf? ",
      'login': isEnglish ? "Login Here" : "Masuk di sini",
    };

    return Scaffold(
      backgroundColor: const Color(0xFF2D3329),
      body: Stack(
        children: [
          // 1. Background Image Full
          Positioned.fill(
            child: Image.network(
              cafeImageUrl,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Overlay Gelap (Sama persis dengan Login agar tulisan JELAS)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2D3329).withOpacity(0.9), // Atas
                    const Color(0xFF2D3329).withOpacity(0.7), // Tengah
                    const Color(0xFF2D3329).withOpacity(0.95), // Bawah (Paling gelap buat kontras footer)
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
                  const SizedBox(height: 30),
                  // --- LOGO SECTION WITH GLOW ---
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
                      child: Image.asset('assets/images/SelasarLogo.png', width: 100, height: 100),
                    ),
                  ),
                  Text(lang['title']!, style: const TextStyle(color: Color(0xFFC5D1B5), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  Text(lang['subtitle']!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, letterSpacing: 1.2)),
                  
                  const SizedBox(height: 25),

                  // --- SIGNUP CARD DENGAN GLASSMORPHISM ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9F2).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              _buildInputField(
                                controller: _nameController,
                                label: lang['labelName']!,
                                hint: "Fadilah Developer",
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 15),
                              _buildInputField(
                                controller: _emailController,
                                label: lang['labelEmail']!,
                                hint: "staff@selasar.com",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 15),
                              _buildInputField(
                                controller: _phoneController,
                                label: lang['labelPhone']!,
                                hint: "08123456789",
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 15),
                              _buildInputField(
                                controller: _passwordController,
                                label: lang['labelPass']!,
                                hint: "••••••••",
                                icon: Icons.lock_open_rounded,
                                isPassword: !_isPasswordVisible,
                                trailing: GestureDetector(
                                  onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  child: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: const Color(0xFF4A5D3F)),
                                ),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A5D3F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF4A5D3F).withOpacity(0.4),
                                  ),
                                  child: isLoading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(lang['buttonSignup']!, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- FOOTER SECTION (Signup Link & Lang) ---
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: lang['hasAccount'],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          children: [
                            TextSpan(text: lang['login'], style: const TextStyle(color: Color(0xFFC5D1B5), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
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

  Widget _buildInputField({required TextEditingController controller, required String label, required String hint, required IconData icon, bool isPassword = false, TextInputType keyboardType = TextInputType.text, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 14),
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