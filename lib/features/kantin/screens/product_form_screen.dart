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
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/utils/currency_formatter.dart';

/// Data models for GoFood / GrabFood Merchant-style Modifier Groups
class ModifierItem {
  String name;
  int price;

  ModifierItem({required this.name, this.price = 0});

  String toFormattedString(String groupTitle) {
    final cleanName = name.trim();
    final cleanGroup = groupTitle.trim();
    final pricePart = price > 0 ? ' (+Rp ${CurrencyFormatter.format(price).replaceAll('Rp ', '')})' : '';
    if (cleanGroup.isNotEmpty) {
      return '$cleanGroup: $cleanName$pricePart';
    }
    return '$cleanName$pricePart';
  }
}

class ModifierGroup {
  String id;
  String title;
  bool isSingleSelect; // true: pilih 1 (e.g. Level Pedas, Level Asin), false: pilih banyak (e.g. Topping)
  List<ModifierItem> items;
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPriceController = TextEditingController();

  ModifierGroup({
    required this.id,
    required this.title,
    this.isSingleSelect = true,
    List<ModifierItem>? items,
  }) : items = items ?? [];

  void dispose() {
    itemNameController.dispose();
    itemPriceController.dispose();
  }
}

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

  late String _selectedCategory;
  final List<ModifierGroup> _modifierGroups = [];
  bool _isLoading = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageDeleted = false;
  int _groupCounter = 1;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product?.price != null ? product!.price.toString() : '',
    );
    _selectedCategory = product?.category ?? 'makanan';

    _parseInitialOptions(product?.customizableOptions ?? []);
  }

  void _parseInitialOptions(List<String> rawOptions) {
    final Map<String, List<ModifierItem>> grouped = {};

    for (final opt in rawOptions) {
      final clean = opt.trim();
      if (clean.isEmpty) continue;

      String groupTitle = 'Pilihan Tambahan';
      String itemPart = clean;

      if (clean.contains(': ')) {
        final parts = clean.split(': ');
        groupTitle = parts[0].trim();
        itemPart = parts.sublist(1).join(': ').trim();
      }

      int price = 0;
      String name = itemPart;
      if (itemPart.contains(' (+Rp ')) {
        final sub = itemPart.split(' (+Rp ');
        name = sub[0].trim();
        final priceStr = sub[1].replaceAll(')', '').replaceAll('.', '').replaceAll(',', '').trim();
        price = int.tryParse(priceStr) ?? 0;
      }

      grouped.putIfAbsent(groupTitle, () => []).add(ModifierItem(name: name, price: price));
    }

    grouped.forEach((title, items) {
      final lower = title.toLowerCase();
      final isSingle = lower.contains('level') ||
          lower.contains('pedas') ||
          lower.contains('asin') ||
          lower.contains('rasa') ||
          lower.contains('porsi') ||
          lower.contains('ukuran') ||
          lower.contains('suhu') ||
          lower.contains('es') ||
          lower.contains('gula') ||
          lower.contains('pilih 1');

      _modifierGroups.add(ModifierGroup(
        id: 'group_${_groupCounter++}',
        title: title,
        isSingleSelect: isSingle,
        items: items,
      ));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    for (final g in _modifierGroups) {
      g.dispose();
    }
    super.dispose();
  }

  void _addNewGroup({String? title, bool isSingleSelect = true, List<ModifierItem>? initialItems}) {
    setState(() {
      _modifierGroups.add(ModifierGroup(
        id: 'group_${_groupCounter++}',
        title: title ?? 'Grup Pilihan ${_modifierGroups.length + 1}',
        isSingleSelect: isSingleSelect,
        items: initialItems ?? [],
      ));
    });
  }

  void _showAddGroupDialog() {
    final titleController = TextEditingController();
    bool isSingleSelect = true;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
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
                    'Tambah Grup Variasi Baru',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: ctx.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contoh: Tingkat Kepedasan, Tingkat Keasinan, Pilihan Topping, Ukuran Porsi',
                    style: GoogleFonts.inter(fontSize: 12, color: ctx.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                    onChanged: (val) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Nama Grup Variasi',
                      hintText: 'Contoh: Tingkat Keasinan',
                      errorText: errorMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aturan Pemilihan Pelanggan:',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: ctx.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  // Slide Selector in Add Group Dialog
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ctx.surfaceBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ctx.dividerCol, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isSingleSelect = true),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: isSingleSelect ? Nebula.teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSingleSelect
                                    ? [
                                        BoxShadow(
                                          color: Nebula.teal.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.radio_button_checked, size: 14, color: isSingleSelect ? Colors.white : ctx.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('Pilih 1', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: isSingleSelect ? Colors.white : ctx.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setDialogState(() => isSingleSelect = false),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: !isSingleSelect ? Nebula.teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isSingleSelect
                                    ? [
                                        BoxShadow(
                                          color: Nebula.teal.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_box_outlined, size: 14, color: !isSingleSelect ? Colors.white : ctx.textSecondary),
                                  const SizedBox(width: 6),
                                  Text('Pilih Banyak', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: !isSingleSelect ? Colors.white : ctx.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            setDialogState(() => errorMessage = 'Nama grup variasi wajib diisi');
                            return;
                          }
                          _addNewGroup(title: title, isSingleSelect: isSingleSelect);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Buat Grup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(ModifierGroup group, int itemIndex) {
    final item = group.items[itemIndex];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price > 0 ? item.price.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(22),
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
                  'Ubah Opsi Pilihan',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                  decoration: const InputDecoration(labelText: 'Nama Pilihan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
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
                        final name = nameController.text.trim();
                        final price = int.tryParse(priceController.text.trim()) ?? 0;
                        if (name.isNotEmpty) {
                          setState(() {
                            item.name = name;
                            item.price = price;
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

      // Compile modifier groups into serialized string options
      final List<String> compiledOptions = [];
      for (final group in _modifierGroups) {
        for (final item in group.items) {
          compiledOptions.add(item.toFormattedString(group.title));
        }
      }

      final payload = {
        'operator_id': operatorId,
        'name': _nameController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'is_available': widget.initialProduct?.isAvailable ?? true,
        'image_url': finalImageUrl,
        'customizable_options': compiledOptions,
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

                    // Category Selector (Clean Segmented Slide Tabs)
                    Text(
                      AppStrings.labelProductCategory,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.dividerCol, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          _buildCategorySlideTab('makanan', AppStrings.categoryFood),
                          _buildCategorySlideTab('minuman', AppStrings.categoryDrink),
                          _buildCategorySlideTab('camilan', 'Camilan'),
                        ],
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
                    // DYNAMIC MODIFIER GROUPS MANAGER (GoFood / GrabFood Standard)
                    // ══════════════════════════════════════════════════════════
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Grup Variasi & Pilihan Kustomisasi',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Atur kategori pilihan seperti Tingkat Kepedasan, Tingkat Keasinan, Ukuran Porsi, atau Ekstra Topping.',
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add Group Button
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddGroupDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(CupertinoIcons.plus, size: 16),
                          label: Text(
                            'Tambah Grup Variasi Baru',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Render Dynamic Modifier Groups
                    if (_modifierGroups.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                        decoration: BoxDecoration(
                          color: context.surfaceBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.dividerCol, width: 0.8),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.tune_rounded, size: 36, color: context.textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada grup variasi untuk jajanan ini.',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Klik tombol "+ Tambah Grup Variasi Baru" di atas untuk membuat kategori pilihan baru (misal: Tingkat Kepedasan, Pilihan Asin, Topping).',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _modifierGroups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, groupIndex) {
                          final group = _modifierGroups[groupIndex];
                          return _buildModifierGroupCard(group, groupIndex);
                        },
                      ),

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

  Widget _buildModifierGroupCard(ModifierGroup group, int groupIndex) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: context.surfaceBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: context.dividerCol, width: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Group Title on left, Edit Title & Delete side by side on right
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Static Edit & Delete buttons side-by-side
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.dividerCol, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _showEditGroupTitleDialog(group),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.pencil, size: 13, color: Nebula.teal),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Ubah',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 18, color: context.dividerCol),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _modifierGroups.removeAt(groupIndex);
                              });
                            },
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Icon(CupertinoIcons.trash, size: 13, color: Nebula.rose),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Direct Segmented Switch Bar
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.dividerCol, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => group.isSingleSelect = true),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: group.isSingleSelect ? Nebula.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.radio_button_checked,
                                  size: 13,
                                  color: group.isSingleSelect ? Colors.white : context.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pilih 1',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: group.isSingleSelect ? Colors.white : context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => group.isSingleSelect = false),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: !group.isSingleSelect ? Nebula.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_box_outlined,
                                  size: 13,
                                  color: !group.isSingleSelect ? Colors.white : context.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pilih Banyak',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: !group.isSingleSelect ? Colors.white : context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Group Items List
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada pilihan di dalam grup ini. Tambahkan pilihan di bawah.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, itemIndex) {
                      final item = group.items[itemIndex];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.dividerCol, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              group.isSingleSelect ? Icons.radio_button_checked : Icons.check_box_outlined,
                              size: 15,
                              color: Nebula.teal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: item.price > 0 ? Nebula.teal.withValues(alpha: 0.12) : context.cardBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: context.borderLight, width: 0.5),
                              ),
                              child: Text(
                                item.price > 0 ? '+${CurrencyFormatter.format(item.price)}' : 'Gratis',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.price > 0 ? Nebula.teal : context.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Action Buttons side by side with clean touch targets
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _showEditItemDialog(group, itemIndex),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: context.cardBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: context.borderLight, width: 0.5),
                                    ),
                                    child: const Icon(CupertinoIcons.pencil, size: 13, color: Nebula.teal),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      group.items.removeAt(itemIndex);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Nebula.rose.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Nebula.rose.withValues(alpha: 0.2), width: 0.5),
                                    ),
                                    child: const Icon(CupertinoIcons.trash, size: 13, color: Nebula.rose),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 12),

                // Inline Item Creator for this specific Group
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.surfaceBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.dividerCol, width: 0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+ Tambah Pilihan ke "${group.title}"',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: group.itemNameController,
                              style: GoogleFonts.inter(fontSize: 12.5, color: context.textPrimary),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Nama pilihan...',
                                hintStyle: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                                filled: true,
                                fillColor: context.cardBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: group.itemPriceController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Rp 0',
                                hintStyle: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                                filled: true,
                                fillColor: context.cardBg,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: context.dividerCol, width: 0.8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Nebula.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              minimumSize: const Size(0, 38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final name = group.itemNameController.text.trim();
                              final price = int.tryParse(group.itemPriceController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                              if (name.isNotEmpty) {
                                setState(() {
                                  group.items.add(ModifierItem(name: name, price: price));
                                  group.itemNameController.clear();
                                  group.itemPriceController.clear();
                                });
                              }
                            },
                            child: Text('+ Tambah', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGroupTitleDialog(ModifierGroup group) {
    final titleController = TextEditingController(text: group.title);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ctx.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ctx.dividerCol, width: 0.8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubah Nama Grup Variasi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ctx.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14, color: ctx.textPrimary),
                  onChanged: (val) {
                    if (errorMessage != null) {
                      setDialogState(() => errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Nama Grup',
                    errorText: errorMessage,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Batal', style: TextStyle(color: ctx.textSecondary))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Nebula.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          setDialogState(() => errorMessage = 'Nama grup wajib diisi');
                          return;
                        }
                        setState(() => group.title = title);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySlideTab(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = key),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Nebula.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
