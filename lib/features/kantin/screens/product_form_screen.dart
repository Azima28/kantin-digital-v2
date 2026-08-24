import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Professional Merchant Product Form Screen (GoFood / GrabFood Merchant Standard)
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? initialProduct;
  const ProductFormScreen({super.key, this.initialProduct});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  final TextEditingController _optionNameController = TextEditingController();
  final TextEditingController _optionPriceController = TextEditingController();

  late String _selectedCategory;
  List<String> _customizableOptions = [];
  bool _isLoading = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageDeleted = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product?.price != null ? product!.price.toString() : '',
    );
    _selectedCategory = product?.category ?? 'makanan';
    _customizableOptions = product?.customizableOptions != null
        ? List<String>.from(product!.customizableOptions)
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseOption(String opt) {
    String cleanOpt = opt.trim();
    if (cleanOpt.contains(' (+Rp ')) {
      final parts = cleanOpt.split(' (+Rp ');
      final name = parts[0].trim();
      final priceStr = parts[1].replaceAll(')', '').replaceAll('.', '').replaceAll(',', '').trim();
      final price = int.tryParse(priceStr) ?? 0;
      return {'name': name, 'price': price};
    }
    return {'name': cleanOpt, 'price': 0};
  }

  void _addOptionDirect(String name, int price) {
    final String trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final String formattedOpt = price > 0
        ? '$trimmedName (+Rp ${CurrencyFormatter.format(price).replaceAll('Rp ', '')})'
        : trimmedName;

    final bool exists = _customizableOptions.any((opt) {
      final parsed = _parseOption(opt);
      return parsed['name'].toString().toLowerCase() == trimmedName.toLowerCase();
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Varian "$trimmedName" sudah ada dalam daftar'),
          backgroundColor: Nebula.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _customizableOptions.add(formattedOpt);
      _optionNameController.clear();
      _optionPriceController.clear();
    });
  }

  void _addPresetGroup(List<Map<String, dynamic>> presetItems) {
    int addedCount = 0;
    setState(() {
      for (final item in presetItems) {
        final String name = item['name'] as String;
        final int price = (item['price'] as num?)?.toInt() ?? 0;
        final String formattedOpt = price > 0
            ? '$name (+Rp ${CurrencyFormatter.format(price).replaceAll('Rp ', '')})'
            : name;

        final bool exists = _customizableOptions.any((opt) {
          final parsed = _parseOption(opt);
          return parsed['name'].toString().toLowerCase() == name.toLowerCase();
        });

        if (!exists) {
          _customizableOptions.add(formattedOpt);
          addedCount++;
        }
      }
    });

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$addedCount varian berhasil ditambahkan dari preset'),
          backgroundColor: Nebula.teal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditOptionDialog(int index) {
    final String currentOpt = _customizableOptions[index];
    final parsed = _parseOption(currentOpt);
    final editNameController = TextEditingController(text: parsed['name'] as String);
    final editPriceController = TextEditingController(
      text: (parsed['price'] as int) > 0 ? parsed['price'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ctx.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ctx.dividerCol, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah Pilihan Varian',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ctx.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editNameController,
                  style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nama Varian / Topping',
                    hintText: 'Contoh: Ekstra Telur',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: editPriceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Harga Tambahan (Rp)',
                    prefixText: '+Rp ',
                    hintText: '0 (Gratis)',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Batal', style: TextStyle(color: ctx.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Nebula.teal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final String name = editNameController.text.trim();
                        final int price = int.tryParse(editPriceController.text.trim()) ?? 0;
                        if (name.isNotEmpty) {
                          final String newOpt = price > 0
                              ? '$name (+Rp ${CurrencyFormatter.format(price).replaceAll('Rp ', '')})'
                              : name;
                          setState(() {
                            _customizableOptions[index] = newOpt;
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _imageDeleted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.labelFailedPickImage), backgroundColor: Nebula.rose),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authState = ref.read(authNotifierProvider);
    final String? operatorId = authState.profile?['id'];

    if (operatorId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi kasir tidak valid'), backgroundColor: Nebula.rose),
      );
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final bool isEdit = widget.initialProduct != null;
      String? uploadedImageUrl;

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final ext = _imageFile!.name.split('.').last;
        final filename = 'product_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
        final uploadRes = await apiClient.uploadImage('/upload/product-image', bytes, filename);
        if (uploadRes.success && uploadRes.data != null) {
          uploadedImageUrl = uploadRes.data!['url']?.toString();
        }
      }

      String? finalImageUrl;
      if (uploadedImageUrl != null) {
        finalImageUrl = uploadedImageUrl;
      } else if (_imageDeleted) {
        finalImageUrl = null;
      } else if (isEdit) {
        finalImageUrl = widget.initialProduct!.imageUrl;
      }

      final payload = {
        'operator_id': operatorId,
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'is_available': widget.initialProduct?.isAvailable ?? true,
        'image_url': finalImageUrl,
        'customizable_options': _customizableOptions,
      };

      final response = isEdit
          ? await apiClient.put('/pos/products/${widget.initialProduct!.id}', body: payload)
          : await apiClient.post('/pos/products', body: payload);

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal menyimpan produk');
      }

      ref.invalidate(posProductsProvider);
      ref.invalidate(publicMenuProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan',
          message: isEdit ? AppStrings.successProductUpdated : AppStrings.successProductSaved,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailedSaveProduct}: $e'),
            backgroundColor: Nebula.rose,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initialProduct != null;
    final bool hasExistingImage = isEdit &&
        widget.initialProduct!.imageUrl != null &&
        widget.initialProduct!.imageUrl!.isNotEmpty;
    final bool showExistingImage = hasExistingImage && !_imageDeleted;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Jajanan' : '${AppStrings.buttonAdd} Jajanan',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Nebula.teal),
          onPressed: () => context.pop(),
        ),
        shape: Border(
          bottom: BorderSide(color: context.borderLight, width: 0.5),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name Field
                    Text(
                      AppStrings.labelProductName,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Bakso Mercon Spesial',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama jajanan wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // Price Field
                    Text(
                      AppStrings.labelProductPrice,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 15),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '15000',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Harga jajanan wajib diisi';
                        final num? parsed = num.tryParse(val);
                        if (parsed == null || parsed <= 0) return 'Masukkan nominal harga yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category Selector
                    Text(
                      AppStrings.labelProductCategory,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSegmentedControl<String>(
                        groupValue: _selectedCategory,
                        selectedColor: Nebula.teal,
                        unselectedColor: context.surfaceBg,
                        borderColor: context.borderLight,
                        children: const <String, Widget>{
                          'makanan': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(AppStrings.categoryFood, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          'minuman': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(AppStrings.categoryDrink, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          'camilan': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Camilan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        },
                        onValueChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Product Image Picker
                    Text(
                      AppStrings.labelPhotoOptional,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (_imageFile != null || showExistingImage) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _imageFile != null
                                ? (kIsWeb
                                    ? Image.network(_imageFile!.path, height: 160, width: double.infinity, fit: BoxFit.cover)
                                    : Image.file(File(_imageFile!.path), height: 160, width: double.infinity, fit: BoxFit.cover))
                                : CachedNetworkImage(
                                    imageUrl: widget.initialProduct!.imageUrl!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
                              child: IconButton(
                                icon: const Icon(CupertinoIcons.trash, size: 16, color: Colors.white),
                                onPressed: () => setState(() {
                                  _imageFile = null;
                                  _imageDeleted = true;
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.surfaceBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.dividerCol, width: 0.8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.camera_fill, color: Nebula.teal, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                'Unggah Foto Menu',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Nebula.teal),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Section Divider
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════════════
                    // GOFOOD / GRABFOOD STYLE VARIANT & MODIFIERS MANAGEMENT
                    // ══════════════════════════════════════════════════════════
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, size: 20, color: Nebula.teal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilihan Variasi & Topping',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                              ),
                              Text(
                                'Atur varian rasa, kepedasan, level es, atau topping tambahan yang bisa dipilih pembeli.',
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Preset Template Buttons
                    Text(
                      'Template Preset Populer',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetActionChip(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Level Pedas (0 - 3)',
                          onTap: () => _addPresetGroup([
                            {'name': 'Level 0 (Tidak Pedas)', 'price': 0},
                            {'name': 'Level 1 (Sedang)', 'price': 0},
                            {'name': 'Level 2 (Pedas)', 'price': 0},
                            {'name': 'Level 3 (Ekstra Pedas)', 'price': 1000},
                          ]),
                        ),
                        _buildPresetActionChip(
                          icon: Icons.ac_unit_rounded,
                          label: 'Tingkat Es & Gula',
                          onTap: () => _addPresetGroup([
                            {'name': 'Es Normal (100%)', 'price': 0},
                            {'name': 'Sedikit Es (Less Ice)', 'price': 0},
                            {'name': 'Tanpa Es (No Ice)', 'price': 0},
                            {'name': 'Sedikit Manis (Less Sugar)', 'price': 0},
                          ]),
                        ),
                        _buildPresetActionChip(
                          icon: Icons.straighten_rounded,
                          label: 'Ukuran Porsi',
                          onTap: () => _addPresetGroup([
                            {'name': 'Porsi Reguler', 'price': 0},
                            {'name': 'Porsi Jumbo', 'price': 4000},
                          ]),
                        ),
                        _buildPresetActionChip(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Topping Populer',
                          onTap: () => _addPresetGroup([
                            {'name': 'Ekstra Telur Dadar', 'price': 3000},
                            {'name': 'Ekstra Keju Parut', 'price': 2500},
                            {'name': 'Ekstra Sosis', 'price': 2000},
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Manual Option Input Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.dividerCol, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Varian / Topping Manual',
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _optionNameController,
                                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Nama varian (misal: Telur Dadar)',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _optionPriceController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary),
                                  decoration: const InputDecoration(
                                    prefixText: '+Rp ',
                                    hintText: '0',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Nebula.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final name = _optionNameController.text.trim();
                                  final price = int.tryParse(_optionPriceController.text.trim()) ?? 0;
                                  if (name.isNotEmpty) {
                                    _addOptionDirect(name, price);
                                  }
                                },
                                child: const Text('+ Tambah', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Configured Options List
                    if (_customizableOptions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: context.surfaceBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.dividerCol.withValues(alpha: 0.5), width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada variasi atau topping yang ditambahkan.\nGunakan preset di atas atau ketik manual.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daftar Pilihan (${_customizableOptions.length})',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _customizableOptions.clear()),
                            style: TextButton.styleFrom(foregroundColor: Nebula.rose, padding: EdgeInsets.zero),
                            child: const Text('Hapus Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customizableOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final opt = _customizableOptions[index];
                          final parsed = _parseOption(opt);
                          final String name = parsed['name'] as String;
                          final int price = parsed['price'] as int;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderLight, width: 0.8),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Nebula.teal.withValues(alpha: 0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Nebula.teal),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: price > 0 ? Nebula.teal.withValues(alpha: 0.12) : context.surfaceBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    price > 0 ? '+${CurrencyFormatter.format(price)}' : 'Gratis',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: price > 0 ? Nebula.teal : context.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                                  color: context.textSecondary,
                                  onPressed: () => _showEditOptionDialog(index),
                                ),
                                IconButton(
                                  icon: const Icon(CupertinoIcons.trash, size: 16),
                                  color: Nebula.rose,
                                  onPressed: () => setState(() => _customizableOptions.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Primary Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _handleSave,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : Text(
                                isEdit ? AppStrings.buttonSave : '${AppStrings.buttonAdd} Jajanan',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderLight, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Nebula.teal),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
