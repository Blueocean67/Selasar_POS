import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _passController = TextEditingController();
  
  User? _user;
  bool _isUploading = false;
  bool _isLoading = true;

  // State Settings (Source of Truth disinkronisasikan langsung dari Database Supabase)
  String selectedRole = "kasir"; 
  String selectedShift = "Sore (15:00 - 22:00)"; 
  String? avatarUrl;
  String fullName = "Staff Selasar";
  String userEmail = ""; // Menyimpan email hasil sinkronisasi database profiles
  bool isEnglish = false; 

  // Security Helper Getters berdasarkan data riil Database
  bool get isAdmin => selectedRole.trim().toLowerCase() == 'admin';
  bool get isCashier => selectedRole.trim().toLowerCase() == 'kasir';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  // --- SINKRONISASI TOTAL DENGAN DATABASE SUPABASE (FIXED EMAIL BUG) ---
  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _user = user;
        
        // Ambil data dari tabel profiles dengan proteksi timeout 3 detik
        final data = await Supabase.instance.client
            .from('profiles')
            .select('role, avatar_url, full_name, email')
            .eq('id', user.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

        if (data != null && mounted) {
          setState(() {
            // 1. Normalisasi role ke lowercase mutlak
            String dbRole = (data['role'] ?? "kasir").toString().trim().toLowerCase();
            if (dbRole != 'admin' && dbRole != 'kasir') {
              dbRole = 'kasir'; 
            }
            selectedRole = dbRole;
            avatarUrl = data['avatar_url'];
            fullName = data['full_name'] ?? "Staff Selasar";
            
            // FIX: Prioritaskan email dari database, jika null/kosong, paksa pakai email dari Supabase Auth
            if (data['email'] != null && data['email'].toString().isNotEmpty) {
              userEmail = data['email'].toString();
            } else {
              userEmail = user.email ?? "";
            }
            
            _isLoading = false;
          });
          return; 
        }
      }
      
      // Fallback lokal super cepat jika user session kosong atau database offline
      if (mounted) {
        setState(() {
          String metaRole = (_user?.userMetadata?['role'] ?? "kasir").toString().trim().toLowerCase();
          if (metaRole != 'admin' && metaRole != 'kasir') {
            metaRole = 'kasir';
          }
          selectedRole = metaRole;
          avatarUrl = _user?.userMetadata?['avatar_url'];
          fullName = _user?.userMetadata?['full_name'] ?? "Staff Selasar";
          userEmail = _user?.email ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi data profil: $e");
      if (mounted) {
        setState(() {
          userEmail = _user?.email ?? "";
          _isLoading = false;
        });
      }
    }
  }

  String t(String id, String en) => isEnglish ? en : id;

  // --- HARD PROTECTION HELPER FUNCTION ---
  void blockedAccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t("Akses ditolak. Fitur khusus admin.", "Access denied. Admin exclusive feature.")),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- UPDATE PASSWORD ---
  Future<void> _updatePassword() async {
    if (_passController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("Min. 6 Karakter!", "Min. 6 Characters!"))));
      return;
    }
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _passController.text.trim()));
      if (mounted) Navigator.pop(context);
      _passController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("Password Berhasil Diganti!", "Password Updated!")), backgroundColor: const Color(0xFF4A5D3F)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- PDF REPORT (HARD PROTECTED FOR ADMIN ONLY) ---
  Future<void> _downloadReport() async {
    if (!isAdmin) {
      blockedAccess();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF4A5D3F))),
    );

    double totalRevenue = 0;
    int totalTransactions = 0;
    int totalItemsSold = 0;
    String topProduct = "-";
    List<Map<String, dynamic>> transactionList = [];

    try {
      final response = await Supabase.instance.client
          .from('transactions')
          .select('id, created_at, total_price, payment_status, cashier_name, items_count, product_summary')
          .order('created_at', ascending: false)
          .limit(30)
          .timeout(const Duration(seconds: 5));

      if (response != null && response is List) {
        totalTransactions = response.length;
        Map<String, int> productCounts = {};

        for (var tx in response) {
          double price = double.tryParse(tx['total_price'].toString()) ?? 0.0;
          totalRevenue += price;
          
          int items = int.tryParse(tx['items_count'].toString()) ?? 1;
          totalItemsSold += items;

          if (tx['product_summary'] != null) {
            String summary = tx['product_summary'].toString();
            List<String> itemsList = summary.split(',');
            for (var item in itemsList) {
              String name = item.split('(')[0].trim();
              if (name.isNotEmpty) {
                productCounts[name] = (productCounts[name] ?? 0) + items;
              }
            }
          }

          transactionList.add({
            'date': tx['created_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(tx['created_at'])) : '-',
            'cashier': tx['cashier_name'] ?? 'Staff',
            'status': tx['payment_status'] ?? 'SUCCESS',
            'total': price,
          });
        }

        if (productCounts.isNotEmpty) {
          var sortedProducts = productCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          topProduct = sortedProducts.first.key;
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil live data untuk PDF: $e");
    }

    if (mounted) Navigator.pop(context);

    final pdf = pw.Document();
    final dateNow = DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now());
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("SELASAR RUANG", style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
                    pw.Text("Laporan Konsolidasi Bisnis & Aktivitas Staf", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  height: 45, width: 45,
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A5D3F), shape: pw.BoxShape.circle),
                  child: pw.Center(child: pw.Text("SR", style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold))),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF4A5D3F)),
            pw.SizedBox(height: 15),

            pw.Text("INFO OTORISASI & AKUN", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                children: [
                  _pdfRow("Nama Penanggung Jawab (Admin)", fullName),
                  _pdfRow("Email Terdaftar", userEmail.isNotEmpty ? userEmail : (_user?.email ?? "-")),
                  _pdfRow("Status Otorisasi Dokumen", "ADMINISTRATOR (FULL ACCESS)"),
                  _pdfRow("Cakupan Laporan", "Semua Aktivitas Kasir & Admin "),
                  _pdfRow("Shift Pemantauan", selectedShift),
                  _pdfRow("Tanggal Cetak Sistem", dateNow),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("RINGKASAN EKSEKUTIF PENJUALAN", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("TOTAL PENDAPATAN", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(currencyFormatter.format(totalRevenue), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("TOTAL TRANSAKSI", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text("$totalTransactions Transaksi", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("PRODUK TERLARIS", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(topProduct, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("JUMLAH ITEM TERJUAL", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text("$totalItemsSold Unit Produk", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text("LOG HISTORI TRANSAKSI TERBARU", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
            pw.SizedBox(height: 6),
            transactionList.isEmpty
                ? pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Text("Belum ada data transaksi masuk di database.", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500)),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A5D3F)),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Waktu", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Operator (Kasir/Admin)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Status", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Total Billing", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      ...transactionList.take(15).map((tx) => pw.TableRow(
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['date'], style: const pw.TextStyle(fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['cashier'], style: const pw.TextStyle(fontSize: 9))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx['status'], style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green800))),
                              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(currencyFormatter.format(tx['total']), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                            ],
                          )),
                    ],
                  ),
            
            pw.SizedBox(height: 30),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Dokumen ini dihasilkan secara sah & otomatis oleh sistem manajemen Selasar POS.", 
                style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // --- MANUAL SHIFT PICKER ---
  Future<void> _pickManualShift() async {
    final TimeOfDay? start = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      helpText: t("MULAI SHIFT", "START SHIFT"),
    );
    
    if (start != null && mounted) {
      final TimeOfDay? end = await showTimePicker(
        context: context, 
        initialTime: TimeOfDay.now(),
        helpText: t("AKHIR SHIFT", "END SHIFT"),
      );

      if (end != null) {
        String startTime = start.format(context);
        String endTime = end.format(context);
        
        String label = "Shift";
        int hour = start.hour;
        if (hour >= 5 && hour < 11) {
          label = isEnglish ? "Morning" : "Pagi";
        } else if (hour >= 11 && hour < 15) {
          label = isEnglish ? "Afternoon" : "Siang";
        } else if (hour >= 15 && hour < 21) {
          label = isEnglish ? "Evening" : "Sore";
        } else {
          label = isEnglish ? "Night" : "Malam";
        }

        setState(() {
          selectedShift = "$label ($startTime - $endTime)";
        });
      }
    }
  }

  // --- UPDATE JABATAN DI DATABASE (HARD PROTECTED FOR ADMIN ONLY) ---
  Future<void> _updateRoleInDatabase(String newRole) async {
    if (!isAdmin) {
      blockedAccess();
      return;
    }

    final String normalizedRole = newRole.trim().toLowerCase();
    if (normalizedRole != 'admin' && normalizedRole != 'kasir') return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': normalizedRole})
          .eq('id', _user!.id);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'role': normalizedRole}),
      );

      await _loadUserData(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t("Jabatan berhasil diubah ke $normalizedRole!", "Role updated to $normalizedRole!")),
          backgroundColor: const Color(0xFF4A5D3F),
        ));
      }
    } catch (e) {
      debugPrint("Gagal ganti role: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HANDLE PHOTO UPLOAD & SYNC DATABASE ---
  Future<void> _handlePhotoAction(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        final userId = _user!.id;
        final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(pickedFile.path);

        await Supabase.instance.client.storage.from('avatars').upload(fileName, file, fileOptions: const FileOptions(upsert: true));
        
        final String publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
        
        await Supabase.instance.client.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'avatar_url': publicUrl}));
        
        await _loadUserData(); 
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF4A5D3F))));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF4A5D3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t("PROFIL STAF", "STAFF PROFILE"), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Color(0xFF4A5D3F))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildPremiumHeader(),
            const SizedBox(height: 25),
            
            if (isAdmin) ...[
              _buildSectionTitle(t("DOKUMEN & LAPORAN", "DOCUMENTS & REPORTS")),
              _profileTile(Icons.picture_as_pdf_rounded, t("Unduh Laporan Kerja", "Download Work Report"), t("File PDF Branded Selasar", "Selasar Branded PDF"), _downloadReport),
              const SizedBox(height: 25),
            ],
            
            _buildSectionTitle(t("PENGATURAN KERJA", "WORK SETTINGS")),
            
            _profileTile(
              Icons.badge_outlined, 
              t("Jabatan", "Role"), 
              selectedRole == 'admin' ? t("Admin", "Admin") : t("Kasir", "Cashier"), 
              () {
                if (!isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t("Jabatan Anda dikunci oleh Sistem Database!", "Your role is locked by the Database System!")),
                    backgroundColor: Colors.orange.shade800,
                  ));
                } else {
                  _showPicker(t("Jabatan", "Role"), [t("Kasir", "Cashier"), t("Admin", "Admin")], (val) {
                    String targetRole = (val == "Admin" || val == "admin") ? "admin" : "kasir";
                    _updateRoleInDatabase(targetRole);
                  });
                }
              }
            ),
            
            _profileTile(
              Icons.history_toggle_off_rounded, 
              t("Atur Shift Manual", "Manual Shift Set"), 
              selectedShift, 
              _pickManualShift
            ),
            
            const SizedBox(height: 25),
            _buildSectionTitle(t("KEAMANAN ", "SECURITY & LANGUAGE")),
            _profileTile(Icons.lock_person_outlined, t("Ganti Password", "Change Password"), t("Amankan akun", "Secure your account"), _showPasswordDialog),
              
            const SizedBox(height: 40),
            _buildLogoutButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4A5D3F).withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: const Color(0xFFEDF0E9),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null 
                        ? const Icon(Icons.person_rounded, size: 60, color: Colors.grey) 
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: _showPhotoOptions,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF4A5D3F),
                      radius: 20,
                      child: _isUploading 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.edit_square, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3329))),
          const SizedBox(height: 4),
          Text(userEmail.isNotEmpty ? userEmail : (_user?.email ?? ""), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(t("Ganti Password", "Change Password"), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t("Masukkan password baru minimal 6 karakter.", "Enter a new password with at least 6 characters."), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: _passController, 
              decoration: InputDecoration(
                hintText: t("Password Baru", "New Password"),
                filled: true,
                fillColor: const Color(0xFFF1F4EE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ), 
              obscureText: true
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t("Batal", "Cancel"), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: _updatePassword, 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5D3F), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ), 
            child: Text(t("SIMPAN PASSWORD", "SAVE PASSWORD"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _profileTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF1F4EE), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: const Color(0xFF4A5D3F), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3329))),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  void _showPicker(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 20),
            ...options.map((e) => ListTile(
              title: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { onSelect(e); Navigator.pop(context); },
              trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF4A5D3F)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, 
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4A5D3F), letterSpacing: 2))),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton.icon(
        onPressed: () => Supabase.instance.client.auth.signOut().then((_) => Navigator.pushReplacementNamed(context, '/welcome')),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
        label: Text(t("KELUAR DARI SISTEM", "LOGOUT FROM SYSTEM"), 
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
  
  // --- FIXED: MENYEMPURNAKAN BOTTOM SHEET UNTUK PILIHAN FOTO ---
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t("UBAH FOTO PROFIL", "CHANGE PROFILE PHOTO"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF4A5D3F))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF4A5D3F)),
              title: Text(t("Ambil dari Galeri", "Choose from Gallery"), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handlePhotoAction(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4A5D3F)),
              title: Text(t("Gunakan Kamera", "Take a Photo"), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _handlePhotoAction(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}