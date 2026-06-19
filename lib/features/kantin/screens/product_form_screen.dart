import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialProduct;
  const ProductFormScreen({super.key, this.initialProduct});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late String _selectedCategory;
  bool _isLoading = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageDeleted = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?['name']?.toString() ?? '');
    _priceController = TextEditingController(
      text: product?['price'] != null ? product!['price'].toString().replaceAll('.00', '') : '',
    );
    _selectedCategory = product?['category']?.toString() ?? 'makanan';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageDeleted = true;
    });
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
          SnackBar(content: Text('Gagal memilih gambar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authState = ref.read(authNotifierProvider);
    final String? operatorId = authState.profile?['id'];
    
    if (operatorId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi kasir tidak valid. Harap login kembali.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final String name = _nameController.text.trim();
    final double price = double.parse(_priceController.text.trim());
    final bool isEdit = widget.initialProduct != null;
    String? finalImageUrl = isEdit ? widget.initialProduct!['image_url']?.toString() : null;

    if (_imageDeleted) {
      finalImageUrl = null;
    }

    try {
      final client = ref.read(supabaseClientProvider);

      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileExt = _imageFile!.name.split('.').last;
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        try {
          await client.storage.from('products').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
          );
        } catch (storageErr) {
          try {
            await client.storage.createBucket('products', const BucketOptions(public: true));
            await client.storage.from('products').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
            );
          } catch (createErr) {
            throw Exception('Gagal mengunggah gambar. Pastikan bucket "products" sudah dibuat di Supabase Storage Anda. Detail: $storageErr');
          }
        }
        
        finalImageUrl = client.storage.from('products').getPublicUrl(fileName);
      }
      
      final Map<String, dynamic> data = {
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'image_url': finalImageUrl,
      };

      if (isEdit) {
        final String productId = widget.initialProduct!['id'].toString();
        await client.from('products').update(data).eq('id', productId);
      } else {
        data['operator_id'] = operatorId;
        data['is_available'] = true;
        await client.from('products').insert(data);
      }

      // Write to audit logs
      try {
        final actorName = authState.profile?['full_name'] ?? 'Petugas Kantin';
        await client.from('audit_logs').insert({
          'actor_id': operatorId,
          'actor_name': actorName,
          'action_type': isEdit ? 'UBAH_PRODUK' : 'TAMBAH_PRODUK',
          'description': isEdit
              ? 'Mengubah data produk jajanan: $name'
              : 'Menambahkan produk jajanan baru: $name',
          'new_value': data,
        });
      } catch (_) {}

      // Refresh list providers
      ref.invalidate(posProductsProvider);
      ref.invalidate(manageProductsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Jajanan berhasil diubah!' : 'Jajanan berhasil ditambahkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan jajanan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.initialProduct != null;
    final bool hasExistingImage = isEdit &&
        widget.initialProduct!['image_url'] != null &&
        widget.initialProduct!['image_url'].toString().isNotEmpty;
    final bool showExistingImage = hasExistingImage && !_imageDeleted;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Jajanan' : 'Tambah Jajanan',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
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
                    // Input Nama Jajanan
                    Text(
                      AppStrings.labelProductName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Nasi Goreng Gila',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama jajanan wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Input Harga Jajanan
                    Text(
                      AppStrings.labelProductPrice,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '12000',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harga jajanan wajib diisi';
                        }
                        final double? val = double.tryParse(value);
                        if (val == null || val <= 0) {
                          return 'Masukkan nominal harga yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Kategori Selector (Cupertino style)
                    Text(
                      AppStrings.labelProductCategory,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSegmentedControl<String>(
                        groupValue: _selectedCategory,
                        selectedColor: AppColors.primary,
                        unselectedColor: AppColors.systemBackground,
                        borderColor: AppColors.borderLight,
                        children: const <String, Widget>{
                          'makanan': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              AppStrings.categoryFood,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          'minuman': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              AppStrings.categoryDrink,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          'camilan': Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Camilan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        },
                        onValueChanged: (String val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Upload Gambar Produk
                    Text(
                      'Gambar Produk (Opsional)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.systemBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderLight,
                            width: 0.5,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? Image.network(
                                        _imageFile!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : showExistingImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.initialProduct!['image_url'].toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildUploadPlaceholder(),
                                    ),
                                  )
                                : _buildUploadPlaceholder(),
                      ),
                    ),
                    if (_imageFile != null || showExistingImage) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _removeImage,
                            icon: const Icon(CupertinoIcons.trash, size: 14),
                            label: const Text('Hapus Gambar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 48),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : Text(
                                AppStrings.buttonSaveProduct.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.cloud_upload,
          size: 40,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pilih Gambar Jajanan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Format JPG, PNG (Maks. 5MB)',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
