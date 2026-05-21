import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const primary = Color(0xFF4A5D3F);
  static const accent = Color(0xFFA3B18A);
  static const bg = Color(0xFFF8F9F2);
  static const card = Colors.white;
  static const text = Color(0xFF2D3329);
  static const sub = Color(0xFF7A7A7A);
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool isEnglish = true; // Default mengikuti Login
  bool isLoading = false;
  bool _showPassword = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Helper Translation
  String t(String en, String id) => isEnglish ? en : id;

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack(t("Please fill all fields", "Mohon lengkapi semua data"));
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
          'role': 'KASIR', // Default role untuk staff baru
        },
      );

      if (mounted) {
        _showSnack(t("Registration successful!", "Pendaftaran berhasil!"));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(t("Signup failed", "Pendaftaran gagal"));
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

                /// LOGO CUSTOM (SelasarLogo.png)
                Container(
                  height: 90,
                  width: 90,
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
                        Icons.person_add_rounded,
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
                  t("Create Staff Access Account", "Buat Akun Akses Staf"),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 25),

                /// CARD SIGNUP
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
                      _input(t("Full Name", "Nama Lengkap"), _nameController, Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      _input("Email", _emailController, Icons.alternate_email_rounded),
                      const SizedBox(height: 14),
                      _input(t("Phone", "No. Telepon"), _phoneController, Icons.phone_android_rounded),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 24),

                      /// BUTTON DAFTAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSignup,
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
                                  t("REGISTER", "DAFTAR"),
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

                const SizedBox(height: 20),

                /// IMAGE AESTHETIC (Sama dengan Login)
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    'https://images.pexels.com/photos/11894196/pexels-photo-11894196.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// LANGUAGE SWITCH (Sekarang sama dengan WelcomePage)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _langOption("ID", !isEnglish, () => setState(() => isEnglish = false)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("|", style: TextStyle(color: Colors.black26)),
                    ),
                    _langOption("EN", isEnglish, () => setState(() => isEnglish = true)),
                  ],
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t("Already have an account? Login", "Sudah punya akun? Masuk"),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
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

  /// WIDGET HELPER UTK OPSI BAHASA (Gaya WelcomePage)
  Widget _langOption(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : Colors.black38,
          fontWeight: active ? FontWeight.w900 : FontWeight.normal,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}