import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/dashboard_page.dart';

class AppColors {
  static const primary = Color(0xFF4A5D3F);
  static const accent = Color(0xFFA3B18A);
  static const bg = Color(0xFFF8F9F2);
  static const card = Colors.white;
  static const text = Color(0xFF2D3329);
  static const sub = Color(0xFF7A7A7A);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isEnglish = true;
  bool isLoading = false;
  bool _showPassword = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Fungsi Helper untuk Translatasi teks secara instan
  String t(String en, String id) => isEnglish ? en : id;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack(t("Please fill all fields", "Mohon isi semua kolom"));
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
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (_) {
      _showSnack(t("Login failed. Please check your credentials", "Login gagal. Periksa kembali akun Anda"));
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                /// LOGO CUSTOM (Menggunakan SelasarLogo.png)
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/SelasarLogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.coffee_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  t("Selasar Ruang", "Selasar Ruang"),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),

                Text(
                  t("Premium Coffee & POS System", "Sistem POS & Kopi Premium"),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 30),

                /// CARD LOGIN
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _input("Email", _emailController, Icons.alternate_email_rounded),

                      const SizedBox(height: 16),

                      _input(
                        t("Password", "Kata Sandi"),
                        _passwordController,
                        Icons.lock_person_outlined,
                        obscure: !_showPassword,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.sub,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _showPassword = !_showPassword;
                          }),
                        ),
                      ),

                      const SizedBox(height: 26),

                      /// BUTTON LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  t("LOGIN", "MASUK"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// IMAGE AESTHETIC
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    'https://images.pexels.com/photos/11894196/pexels-photo-11894196.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                /// BAHASA SELECTOR (Sekarang sama persis stylenya dengan Welcome Page)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _langOption("ID", !isEnglish, () => setState(() => isEnglish = false)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("|", style: TextStyle(color: AppColors.sub)),
                    ),
                    _langOption("EN", isEnglish, () => setState(() => isEnglish = true)),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(String hint, TextEditingController c, IconData icon,
      {bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF1F4EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// WIDGET HELPER UNTUK OPSI BAHASA (Gaya minimalis Welcome Page)
  Widget _langOption(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : AppColors.sub.withOpacity(0.5),
          fontWeight: active ? FontWeight.w900 : FontWeight.normal,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}