import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selasar_pos/provider/promo_provider.dart';
import 'package:selasar_pos/pages/form_promo_page.dart'; // <--- Terhubung ke Form Promo

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  @override
  void initState() {
    super.initState();
    // Memastikan data kupon promo selalu ditarik paling segar dari database Supabase saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoProvider>().fetchPromosFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFB),
      appBar: AppBar(
        title: const Text(
          "Manajemen Kupon Promo",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF32341E)),
        ),
        backgroundColor: const Color(0xFFFDFDFB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF32341E)),
      ),
      body: promoProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A4D2E)))
          : promoProvider.promos.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada kupon promo dibuat.",
                    style: TextStyle(color: Color(0xFF7A7C64), fontWeight: FontWeight.w500),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF4A4D2E),
                  onRefresh: () => promoProvider.fetchPromosFromDatabase(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: promoProvider.promos.length,
                    itemBuilder: (context, index) {
                      final promo = promoProvider.promos[index];

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFECECE6), width: 1),
                        ),
                        color: const Color(0xFFFDFDFB),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          // =========================================================
                          // NAVIGASI EDIT: Mengirim data objek promo untuk diedit ke FormPromoPage
                          // =========================================================
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormPromoPage(promo: promo),
                              ),
                            ).then((_) {
                              // Segarkan data secara otomatis ketika kembali dari halaman form edit
                              promoProvider.fetchPromosFromDatabase();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // --- ICON LEADING ---
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB1B67C), // Menggunakan solid color sesuai request
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.confirmation_number_outlined, color: Colors.white), // Menyesuaikan kontras warna agar terbaca
                                ),
                                const SizedBox(width: 14),
                                
                                // --- AREA KONTEN TENAH (DIBUNGKUS EXPANDED UNTUK FIX OVERFLOW) ---
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Baris Judul Kode Promo + Badge Skop
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              promo.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: Color(0xFF32341E),
                                                letterSpacing: 0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Badge penanda cakupan promo (Global / Menu Spesifik)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: promo.scope.toLowerCase() == 'global' 
                                                  ? const Color(0xFFE8F5E9) 
                                                  : const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              promo.scope.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 9, 
                                                fontWeight: FontWeight.bold,
                                                color: promo.scope.toLowerCase() == 'global' 
                                                    ? Colors.green.shade800 
                                                    : Colors.blue.shade800,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Subjudul Deskripsi Potongan Persen
                                      Text(
                                        "${promo.discountPercentage.toInt()}% Potongan • ${promo.description}",
                                        style: const TextStyle(color: Color(0xFF7A7C64), fontSize: 12, height: 1.4),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // --- SWITCH TOGGLE BUTTON ---
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: promo.isActive,
                                    activeColor: const Color(0xFF4A4D2E),
                                    activeTrackColor: const Color(0xFFB1B67C),
                                    inactiveThumbColor: const Color(0xFF9A9C86),
                                    inactiveTrackColor: const Color(0xFFECECE6),
                                    onChanged: (bool newValue) async {
                                      // Aksi switch langsung menyinkronkan status ke database lewat provider
                                      await promoProvider.togglePromoStatus(promo.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Status Promo ${promo.code} berhasil diperbarui!"),
                                            duration: const Duration(seconds: 1),
                                            backgroundColor: const Color(0xFF4A4D2E),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      // =========================================================
      // NAVIGASI BUAT BARU: Mengarah ke FormPromoPage tanpa parameter (Buat Baru)
      // =========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormPromoPage(), // Kosong = Mode Create
            ),
          ).then((_) {
            // Segarkan list data dari database saat form baru selesai disimpan
            promoProvider.fetchPromosFromDatabase();
          });
        },
        backgroundColor: const Color(0xFF4A4D2E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Buat Promo",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}