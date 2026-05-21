import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selasar_pos/provider/promo_provider.dart';

class FormPromoPage extends StatefulWidget {
  final PromoModel? promo; 

  const FormPromoPage({super.key, this.promo});

  @override
  State<FormPromoPage> createState() => _FormPromoPageState();
}

class _FormPromoPageState extends State<FormPromoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _descController;
  late TextEditingController _discountController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _minTransactionController;
  
  // Controller baru untuk form tanggal biar gak eror lagi
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  late bool _isActive;
  late String _scope;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;

    _codeController = TextEditingController(text: p?.code ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _discountController = TextEditingController(text: p?.discountPercentage != null ? p!.discountPercentage.toInt().toString() : '');
    _maxDiscountController = TextEditingController(text: p?.maxDiscount.toString() ?? '0');
    _minTransactionController = TextEditingController(text: p?.minTransaction.toString() ?? '0');
    _isActive = p?.isActive ?? true;
    _scope = p?.scope ?? 'global';
    
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 7));

    _startDateController = TextEditingController(text: "${_startDate.day}/${_startDate.month}/${_startDate.year}");
    _endDateController = TextEditingController(text: "${_endDate.day}/${_endDate.month}/${_endDate.year}");
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    _maxDiscountController.dispose();
    _minTransactionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A4D2E)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = "${picked.day}/${picked.month}/${picked.year}";
        } else {
          _endDate = picked;
          _endDateController.text = "${picked.day}/${picked.month}/${picked.year}";
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tanggal selesai tidak boleh mendahului tanggal mulai!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<PromoProvider>();

    bool success;
    if (widget.promo == null) {
      success = await provider.addPromo(
        code: _codeController.text.trim(),
        description: _descController.text.trim(),
        discountPercentage: double.parse(_discountController.text),
        maxDiscount: int.parse(_maxDiscountController.text),
        minTransaction: int.parse(_minTransactionController.text),
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
        scope: _scope,
      );
    } else {
      success = await provider.editPromo(
        id: widget.promo!.id,
        code: _codeController.text.trim(),
        description: _descController.text.trim(),
        discountPercentage: double.parse(_discountController.text),
        maxDiscount: int.parse(_maxDiscountController.text),
        minTransaction: int.parse(_minTransactionController.text),
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
        scope: _scope,
      );
    }

    setState(() => _isSaving = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.promo == null ? "Promo baru berhasil dibuat!" : "Perubahan promo disimpan!"),
          backgroundColor: const Color(0xFF4A4D2E),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Promo?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus kupon ${_codeController.text}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      final success = await context.read<PromoProvider>().deletePromo(widget.promo!.id);
      setState(() => _isSaving = false);

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo telah dihapus dari sistem"), backgroundColor: Colors.black87),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.promo != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFB),
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Kupon Promo" : "Buat Kupon Promo",
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF32341E)),
        ),
        backgroundColor: const Color(0xFFFDFDFB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF32341E)),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 28),
              onPressed: _isSaving ? null : _handleDelete,
            )
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A4D2E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel("Kode Promo"),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF32341E)),
                      decoration: _inputDecoration("Contoh: SELASARMANTAP"),
                      validator: (v) => v!.trim().isEmpty ? "Kode kupon tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFieldLabel("Deskripsi Promo"),
                    TextFormField(
                      controller: _descController,
                      decoration: _inputDecoration("Contoh: Potongan khusus menu kopi mendalam"),
                      validator: (v) => v!.trim().isEmpty ? "Deskripsi wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Diskon (%)"),
                              TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration("10"),
                                validator: (v) {
                                  final numVal = double.tryParse(v ?? '');
                                  if (numVal == null || numVal <= 0 || numVal > 100) return "1 - 100";
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Scope Promo"),
                              DropdownButtonFormField<String>(
                                value: _scope,
                                decoration: _inputDecoration(""),
                                dropdownColor: const Color(0xFFFDFDFB),
                                items: const [
                                  DropdownMenuItem(value: 'global', child: Text("Global")),
                                  DropdownMenuItem(value: 'category', child: Text("Kategori")),
                                  DropdownMenuItem(value: 'product', child: Text("Produk")),
                                ],
                                onChanged: (val) => setState(() => _scope = val ?? 'global'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Min. Belanja (Rp)"),
                              TextFormField(
                                controller: _minTransactionController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration("0"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Maks. Potongan (Rp)"),
                              TextFormField(
                                controller: _maxDiscountController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration("0"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // --- TANGGAL MULAI ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Tanggal Mulai"),
                              TextFormField(
                                controller: _startDateController,
                                readOnly: true,
                                onTap: () => _pickDate(context, true),
                                decoration: _inputDecoration("Pilih Tanggal").copyWith(
                                  suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4A4D2E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // --- TANGGAL SELESAI ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel("Tanggal Selesai"),
                              TextFormField(
                                controller: _endDateController,
                                readOnly: true,
                                onTap: () => _pickDate(context, false),
                                decoration: _inputDecoration("Pilih Tanggal").copyWith(
                                  suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4A4D2E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: const Text("Status Kupon Aktif", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF32341E))),
                      subtitle: const Text("Kupon langsung bisa dipakai di POS jika aktif"),
                      value: _isActive,
                      activeColor: const Color(0xFF4A4D2E),
                      activeTrackColor: const Color(0xFFB1B67C),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4D2E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          isEdit ? "Simpan Perubahan Promo" : "Konfirmasi Buat Promo Baru",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A4D2E), fontSize: 14)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9A9C86), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F0),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFECECE6))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4A4D2E), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }
}