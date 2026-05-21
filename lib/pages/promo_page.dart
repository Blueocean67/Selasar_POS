import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selasar_pos/provider/promo_provider.dart';
import 'package:selasar_pos/pages/form_promo_page.dart'; // <--- Memastikan file FormPromoPage terhubung

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  @override
  void initState() {
    super.initState();
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
              : ListView.builder(
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        // =========================================================
                        // TEMPAT NAVIGASI EDIT: Mengirim data promo lama ke form
                        // =========================================================
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormPromoPage(promo: promo),
                            ),
                          );
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB1B67C).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF4A4D2E)),
                        ),
                        title: Text(
                          promo.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF32341E),
                            letterSpacing: 0.5,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${promo.discountPercentage.toInt()}% Potongan • ${promo.description}\nCakupan: ${promo.scope.toUpperCase()}",
                            style: const TextStyle(color: Color(0xFF7A7C64), fontSize: 12, height: 1.4),
                          ),
                        ),
                        trailing: Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: promo.isActive,
                            activeColor: const Color(0xFF4A4D2E),
                            activeTrackColor: const Color(0xFFB1B67C),
                            inactiveThumbColor: const Color(0xFF9A9C86),
                            inactiveTrackColor: const Color(0xFFECECE6),
                            onChanged: (bool newValue) async {
                              await promoProvider.togglePromoStatus(promo.id);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      // =========================================================
      // TEMPAT NAVIGASI BUAT BARU: Tombol Melayang Tambah Promo
      // =========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormPromoPage(), // Kosong tanpa parameter = Buat Baru
            ),
          );
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