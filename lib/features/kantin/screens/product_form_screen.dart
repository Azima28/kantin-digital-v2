import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  late TextEditingController _imageController;
  late String _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?['name']?.toString() ?? '');
    _priceController = TextEditingController(
      text: product?['price'] != null ? product!['price'].toString().replaceAll('.00', '') : '',
    );
    _imageController = TextEditingController(text: product?['image_url']?.toString() ?? '');
    _selectedCategory = product?['category']?.toString() ?? 'makanan';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
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
    final String imageUrl = _imageController.text.trim();
    final bool isEdit = widget.initialProduct != null;

    try {
      final client = ref.read(supabaseClientProvider);
      
      final Map<String, dynamic> data = {
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      };

      if (isEdit) {
        final String productId = widget.initialProduct!['id'].toString();
        await client.from('products').update(data).eq('id', productId);
      } else {
        data['operator_id'] = operatorId;
        data['is_available'] = true;
        await client.from('products').insert(data);
      }

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
                    pressedColor: AppColors.primaryLight,
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
                    },
                    onValueChanged: (String val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Input URL Gambar
                Text(
                  'URL Gambar Produk (Opsional)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextFormField(
                  controller: _imageController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/gambar.jpg',
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
    );
  }
}
