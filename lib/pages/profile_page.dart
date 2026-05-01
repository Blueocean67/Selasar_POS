import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // State Settings
  String selectedRole = "Kasir Utama";
  String selectedShift = "Sore (15:00 - 22:00)"; 
  bool isEnglish = false; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  String t(String id, String en) => isEnglish ? en : id;

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

  // --- PDF REPORT (ANTI-RED FIX) ---
  Future<void> _downloadReport() async {
    final pdf = pw.Document();
    final String fullName = _user?.userMetadata?['full_name'] ?? "Staff Selasar";
    final dateNow = DateFormat('dd MMMM yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER BRANDED
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("SELASAR RUANG", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF4A5D3F))),
                      pw.Text("Laporan Personal Staf", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                    ],
                  ),
                  pw.Container(
                    height: 40, width: 40,
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A5D3F), shape: pw.BoxShape.circle),
                    child: pw.Center(child: pw.Text("SR", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFF4A5D3F)),
              pw.SizedBox(height: 25),

              // DATA PERSONAL
              pw.Text("RINGKASAN PROFIL KERJA", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  children: [
                    _pdfRow("Nama Lengkap", fullName),
                    _pdfRow("Email Terdaftar", _user?.email ?? "-"),
                    _pdfRow("Jabatan", selectedRole),
                    _pdfRow("Shift Aktif", selectedShift),
                    _pdfRow("Tgl Cetak", dateNow),
                  ],
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.Text(
                "Dokumen ini dihasilkan secara sah oleh sistem manajemen Selasar POS.", 
                style: pw.TextStyle(
                  fontSize: 8, 
                  fontStyle: pw.FontStyle.italic, 
                  color: PdfColors.grey600, // GANTI KE color: AGAR ANTI-MERAH
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
          label = "Pagi";
        } else if (hour >= 11 && hour < 15) label = "Siang";
        else if (hour >= 15 && hour < 21) label = "Sore";
        else label = "Malam";

        setState(() {
          selectedShift = "$label ($startTime - $endTime)";
        });
      }
    }
  }

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
        
        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'avatar_url': publicUrl}));
        _loadUserData(); 
      } catch (e) {
        debugPrint("Upload Error: $e");
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
            
            _buildSectionTitle(t("DOKUMEN & LAPORAN", "DOCUMENTS & REPORTS")),
            _profileTile(Icons.picture_as_pdf_rounded, t("Unduh Laporan Kerja", "Download Work Report"), t("File PDF Branded Selasar", "Selasar Branded PDF"), _downloadReport),
            
            const SizedBox(height: 25),
            _buildSectionTitle(t("PENGATURAN KERJA", "WORK SETTINGS")),
            _profileTile(Icons.badge_outlined, t("Jabatan", "Role"), selectedRole, () => _showPicker(t("Jabatan", "Role"), ["Kasir Utama", "Admin", "Staff"], (val) => setState(() => selectedRole = val))),
            
            _profileTile(
              Icons.history_toggle_off_rounded, 
              t("Atur Shift Manual", "Manual Shift Set"), 
              selectedShift, 
              _pickManualShift
            ),
            
            const SizedBox(height: 25),
            _buildSectionTitle(t("KEAMANAN & BAHASA", "SECURITY & LANGUAGE")),
            _profileTile(Icons.lock_person_outlined, t("Ganti Password", "Change Password"), t("Amankan akun", "Secure your account"), _showPasswordDialog),
            _profileTile(Icons.language_rounded, t("Bahasa", "Language"), isEnglish ? "English" : "Indonesia", () => setState(() => isEnglish = !isEnglish)),
            
            const SizedBox(height: 40),
            _buildLogoutButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    String? avatarUrl = _user?.userMetadata?['avatar_url'];
    String fullName = _user?.userMetadata?['full_name'] ?? "Staff Selasar";

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
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
          Text(_user?.email ?? "", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
            const Text("Masukkan password baru minimal 6 karakter.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            child: const Text("SIMPAN PASSWORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
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
              trailing: const Icon(Icons.check_circle_outline, color: Color(0xFFA3B18A)),
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
  
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t("Kelola Foto Profil", "Manage Profile Photo"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 25),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F4EE), child: Icon(Icons.camera_alt, color: Color(0xFF4A5D3F))),
              title: Text(t("Ambil Foto", "Take Photo")),
              onTap: () { Navigator.pop(context); _handlePhotoAction(ImageSource.camera); },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF1F4EE), child: Icon(Icons.photo_library, color: Color(0xFF4A5D3F))),
              title: Text(t("Pilih dari Galeri", "Choose from Gallery")),
              onTap: () { Navigator.pop(context); _handlePhotoAction(ImageSource.gallery); },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}