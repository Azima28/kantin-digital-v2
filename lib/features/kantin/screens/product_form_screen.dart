import 'dart:io' show File; // TODO: Replace with cross-platform file picker for web
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_components.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';

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
  final TextEditingController _optionInputController = TextEditingController();
  final TextEditingController _optionPriceController = TextEditingController();
  late String _selectedCategory;
  List<String> _customizableOptions = [];
  bool _isLoading = false;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageDeleted = false;
  String? _quickToppingImageUrl;

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
    _optionInputController.dispose();
    _optionPriceController.dispose();
    super.dispose();
  }

  String _formatWithDots(int value) {
    final String str = value.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  Map<String, dynamic> _parseOption(String opt) {
    String imageUrl = '';
    final imgReg = RegExp(r'\[img:\s*([^\]]+)\]');
    final imgMatch = imgReg.firstMatch(opt);
    if (imgMatch != null) {
      imageUrl = imgMatch.group(1)!.trim();
    }
    String cleanOpt = opt.replaceAll(imgReg, '').trim();

    if (cleanOpt.contains(' (+Rp ')) {
      final parts = cleanOpt.split(' (+Rp ');
      final name = parts[0].trim();
      final priceStr = parts[1].replaceAll(')', '').replaceAll('.', '').trim();
      final price = int.tryParse(priceStr) ?? 0;
      return {'name': name, 'price': price, 'imageUrl': imageUrl};
    }
    return {'name': cleanOpt.trim(), 'price': 0, 'imageUrl': imageUrl};
  }

  bool _isSpiciness(String option) {
    final lower = option.toLowerCase();
    return (lower.contains('level') ||
            lower.contains('pedas') ||
            lower.contains('cabai') ||
            lower.contains('cabe') ||
            (lower.contains('sambal') && !lower.contains('tomat') && !lower.contains('tiram') && !lower.contains('barbekyu') && !lower.contains('teriyaki'))) &&
        !lower.contains('saus');
  }

  bool _isSauce(String option) {
    final lower = option.toLowerCase();
    return !_isSpiciness(option) && (
      lower.contains('saus') ||
      lower.contains('sauce') ||
      lower.contains('tiram') ||
      lower.contains('barbekyu') ||
      lower.contains('barbecue') ||
      lower.contains('teriyaki') ||
      lower.contains('mayo') ||
      lower.contains('mayonnaise')
    );
  }

  bool _isVegetable(String option) {
    final lower = option.toLowerCase();
    return !_isSpiciness(option) && !_isSauce(option) && (
      lower.contains('tomat') ||
      lower.contains('timun') ||
      lower.contains('bayam') ||
      lower.contains('selada') ||
      lower.contains('kubis') ||
      lower.contains('kol') ||
      lower.contains('kemangi') ||
      lower.contains('kangkung') ||
      lower.contains('wortel') ||
      lower.contains('terong') ||
      lower.contains('bawang') ||
      lower.contains('paprika') ||
      lower.contains('sayur') ||
      lower.contains('lalap') ||
      lower.contains('cucumber') ||
      lower.contains('lettuce') ||
      lower.contains('tomato')
    );
  }

  bool _isTopping(String option) {
    return !_isSpiciness(option) && !_isSauce(option) && !_isVegetable(option);
  }

  void _addSauceOption(String sauceName) {
    final String cleanName = sauceName.split(' (')[0].toLowerCase();
    final bool exists = _customizableOptions.any((opt) {
      final parsedName = _parseOption(opt)['name'].toString().toLowerCase();
      return parsedName.contains(cleanName);
    });

    if (!exists) {
      setState(() {
        _customizableOptions.add(sauceName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan "$sauceName"!'),
          backgroundColor: Nebula.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saus ini sudah ada di daftar kustomisasi.'),
          backgroundColor: Nebula.rose,
        ),
      );
    }
  }

  Widget _buildSaucePresetTile({
    required String title,
    required String description,
    required bool isSpicyLevelSupported,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSpicyLevelSupported
                ? Nebula.rose.withValues(alpha: 0.3)
                : context.borderLight.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSpicyLevelSupported
                              ? Nebula.rose.withValues(alpha: 0.12)
                              : Nebula.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSpicyLevelSupported ? 'Level 0 - N' : 'Standar (Tanpa Level)',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isSpicyLevelSupported ? Nebula.rose : Nebula.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSpicyLevelSupported ? Nebula.rose : Nebula.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSpicyLevelSupported ? '+ Level' : '+ Tambah',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaucePresetCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.03) : Nebula.teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥫', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preset Pilihan Saus & Sambal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Klik saus di bawah untuk menambahkan langsung ke daftar kustomisasi jajanan.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Saus Sambal (Dapat diatur level kepedasannya)
          _buildSaucePresetTile(
            title: 'Saus Sambal 🌶️',
            description: 'Saus cabai pedas favorit masyarakat Indonesia (Atur Level 0 - N)',
            isSpicyLevelSupported: true,
            onTap: _showSpicinessLevelDialog,
          ),
          const SizedBox(height: 8),

          // 2. Saus Tomat (Standar / Tanpa Level)
          _buildSaucePresetTile(
            title: 'Saus Tomat 🍅',
            description: 'Saus merah manis asam dari buah tomat',
            isSpicyLevelSupported: false,
            onTap: () => _addSauceOption('Saus Tomat (Saus merah manis asam dari buah tomat)'),
          ),
          const SizedBox(height: 8),

          // 3. Saus Tiram (Standar / Tanpa Level)
          _buildSaucePresetTile(
            title: 'Saus Tiram 🦪',
            description: 'Saus kental gurih khas masakan Tionghoa',
            isSpicyLevelSupported: false,
            onTap: () => _addSauceOption('Saus Tiram (Saus kental gurih khas masakan Tionghoa)'),
          ),
          const SizedBox(height: 8),

          // 4. Saus Barbekyu (Standar / Tanpa Level)
          _buildSaucePresetTile(
            title: 'Saus Barbekyu 🍖',
            description: 'Saus asap manis untuk daging panggang',
            isSpicyLevelSupported: false,
            onTap: () => _addSauceOption('Saus Barbekyu (Saus asap manis untuk daging panggang)'),
          ),
          const SizedBox(height: 8),

          // 5. Saus Teriyaki (Standar / Tanpa Level)
          _buildSaucePresetTile(
            title: 'Saus Teriyaki 🍱',
            description: 'Saus manis asin khas Jepang dari kecap asin dan mirin',
            isSpicyLevelSupported: false,
            onTap: () => _addSauceOption('Saus Teriyaki (Saus manis asin khas Jepang dari kecap asin)'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkPresetCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.03) : Nebula.teal.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍹', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preset Pilihan Kustomisasi Minuman',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      'Klik preset di bawah untuk menambahkan opsi minuman (Es batu, Level Gula, Topping Boba/Jelly).',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PressScale(
                onTap: () {
                  _addDrinkOption('Es Batu Separuh (Less Ice)');
                  _addDrinkOption('Tanpa Es (No Ice)');
                },
                child: _buildPresetChip('🧊 + Pilihan Es Batu'),
              ),
              PressScale(
                onTap: () {
                  _addDrinkOption('Manis Normal (100% Sugar)');
                  _addDrinkOption('Sedikit Manis (50% Sugar)');
                  _addDrinkOption('Tanpa Gula (0% Sugar)');
                },
                child: _buildPresetChip('🍬 + Level Gula (Sugar)'),
              ),
              PressScale(
                onTap: () {
                  _addDrinkOption('Topping Boba (+Rp 3.000)');
                  _addDrinkOption('Topping Grass Jelly (+Rp 2.500)');
                },
                child: _buildPresetChip('🧋 + Topping Boba & Jelly'),
              ),
              PressScale(
                onTap: () {
                  _addDrinkOption('Extra Susu Fresh Milk (+Rp 2.000)');
                },
                child: _buildPresetChip('🥛 + Extra Susu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Nebula.teal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  void _addDrinkOption(String optionName) {
    final cleanName = _parseOption(optionName)['name'].toString().toLowerCase();
    final bool exists = _customizableOptions.any((opt) {
      final parsedName = _parseOption(opt)['name'].toString().toLowerCase();
      return parsedName == cleanName;
    });

    if (!exists) {
      setState(() {
        _customizableOptions.add(optionName);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambahkan "$optionName"!'),
          backgroundColor: Nebula.teal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCategorizedOptionSection({
    required String title,
    required String icon,
    required List<String> options,
    required String emptyPlaceholder,
  }) {
    final bool isSpicinessSection = title.contains('Tingkat Kepedasan');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Nebula.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${options.length} item',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Nebula.teal,
                ),
              ),
            ),
            if (isSpicinessSection) ...[
              const Spacer(),
              PressScale(
                onTap: _showSpicinessLevelDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌶️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '+ Atur Level (0 - N)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Nebula.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderLight.withValues(alpha: 0.5), width: 0.5),
            ),
            child: Text(
              emptyPlaceholder,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final opt = options[index];
              final realIndex = _customizableOptions.indexOf(opt);
              final parsed = _parseOption(opt);
              final String name = parsed['name'];
              final int price = parsed['price'];
              final String imageUrl = parsed['imageUrl'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderLight, width: 0.5),
                ),
                child: Row(
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CupertinoActivityIndicator(radius: 8)),
                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Nebula.teal.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              if (imageUrl.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Foto',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (price > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+Rp ${_formatWithDots(price)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Nebula.teal,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text(
                              'Gratis / Tanpa Tambahan Harga',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondary,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        PressScale(
                          onTap: () => _showEditOptionDialog(realIndex, opt),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Nebula.teal.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              CupertinoIcons.pencil,
                              size: 16,
                              color: Nebula.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button
                        PressScale(
                          onTap: () {
                            setState(() {
                              if (realIndex != -1) {
                                _customizableOptions.removeAt(realIndex);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Nebula.rose.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              CupertinoIcons.trash,
                              size: 16,
                              color: Nebula.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showSpicinessLevelDialog() {
    int maxLevel = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<String> generatedLevels = [];
            final int count = maxLevel < 0 ? 0 : (maxLevel > 20 ? 20 : maxLevel);

            for (int i = 0; i <= count; i++) {
              String label = 'Level $i';
              if (i == 0) {
                label = 'Level 0 (Tidak Pedas)';
              } else if (i == 1) {
                label = 'Level 1 (Pedas Sedang)';
              } else if (i == 2) {
                label = 'Level 2 (Pedas)';
              } else if (i == 3) {
                label = 'Level 3 (Pedas Banget)';
              } else if (i == 4) {
                label = 'Level 4 (Extra Pedas)';
              } else if (i == 5) {
                label = 'Level 5 (Super Pedas)';
              } else {
                label = 'Level $i (Pedas Gila)';
              }

              generatedLevels.add(label);
            }

            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dialog Title Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Nebula.rose.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🌶️', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Atur Level Kepedasan',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Tentukan batas maksimal level kepedasan untuk jajanan ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Max Level Selection Stepper & Presets
                      Text(
                        'Pilih Maksimal Level Kepedasan (0 - N)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Preset Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [1, 3, 5, 7, 10, 15].map((level) {
                          final isSelected = maxLevel == level;
                          return PressScale(
                            onTap: () {
                              setDialogState(() {
                                maxLevel = level;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Nebula.teal
                                    : (context.isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Nebula.teal
                                      : context.borderLight.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                '0 s/d $level Level',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? Colors.white : context.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Numeric Counter Stepper
                      Row(
                        children: [
                          Text(
                            'Level Maksimal:',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          PressScale(
                            onTap: maxLevel > 0
                                ? () {
                                    setDialogState(() {
                                      maxLevel--;
                                    });
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.minus, size: 16, color: Nebula.teal),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Level $maxLevel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                          PressScale(
                            onTap: maxLevel < 20
                                ? () {
                                    setDialogState(() {
                                      maxLevel++;
                                    });
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.add, size: 16, color: Nebula.teal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Preview generated items card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.borderLight, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Preview Option Level (${generatedLevels.length} Item)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Nebula.teal,
                                  ),
                                ),
                                Text(
                                  'Murid dapat memilih di menu',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: generatedLevels.map((lvl) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Nebula.teal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Nebula.teal.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    lvl,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          PressScale(
                            onTap: () {
                              setState(() {
                                // Clear old spiciness options
                                _customizableOptions.removeWhere((opt) => _isSpiciness(opt));
                                // Add new generated levels at the beginning
                                _customizableOptions.insertAll(0, generatedLevels);
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Berhasil menambahkan Level 0 s/d Level $maxLevel kepedasan!'),
                                  backgroundColor: Nebula.teal,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Nebula.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Terapkan (${generatedLevels.length} Level)',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _uploadToppingImage(Function(bool) setUploadingState) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      setUploadingState(true);

      final client = ref.read(supabaseClientProvider);
      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.name.split('.').last;
      final fileName = 'topping_${DateTime.now().millisecondsSinceEpoch}.${fileExt.isEmpty ? 'jpg' : fileExt}';

      try {
        await client.storage.from('products').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
        );
      } catch (_) {
        try {
          await client.storage.createBucket('products', const BucketOptions(public: true));
          await client.storage.from('products').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
          );
        } catch (createErr) {
          setUploadingState(false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah foto toping: $createErr'), backgroundColor: Nebula.rose),
            );
          }
          return null;
        }
      }

      setUploadingState(false);
      return client.storage.from('products').getPublicUrl(fileName);
    } catch (e) {
      setUploadingState(false);
      debugPrint('Upload topping image error: $e');
      return null;
    }
  }

  void _showEditOptionDialog([int? index, String? opt]) {
    final parsed = opt != null ? _parseOption(opt) : {'name': '', 'price': 0, 'imageUrl': ''};

    final String initialName = index != null
        ? parsed['name']
        : _optionInputController.text.trim();
    final String initialPrice = index != null
        ? (parsed['price'] > 0 ? parsed['price'].toString() : '')
        : _optionPriceController.text.trim();

    final TextEditingController editNameController = TextEditingController(text: initialName);
    final TextEditingController editPriceController = TextEditingController(text: initialPrice);
    String? toppingImageUrl = parsed['imageUrl'] != ''
        ? parsed['imageUrl']
        : _quickToppingImageUrl;
    bool isUploadingImage = false;
    final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: editFormKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.isDark ? context.surfaceBg : const Color(0xFFFAF9F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.borderLight, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          index != null ? 'Ubah Toping / Kustomisasi' : 'Tambah Toping / Kustomisasi',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Atur nama, harga tambahan, dan foto toping untuk kustomisasi ini.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Nama Input
                        Text(
                          'Nama Kustomisasi',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: editNameController,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Misal: Es Batu, Sambal, Tomat, Telur',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama kustomisasi tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Harga Input
                        Text(
                          'Harga Tambahan (Opsional)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: editPriceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: const InputDecoration(
                            prefixText: '+Rp ',
                            hintText: 'Biarkan kosong jika gratis',
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              final parsedVal = int.tryParse(val.trim());
                              if (parsedVal == null || parsedVal < 0) {
                                return 'Masukkan harga yang valid';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Foto Toping Input
                        Text(
                          'Foto Toping (Opsional)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isUploadingImage)
                          Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.surfaceBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderLight, width: 0.5),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CupertinoActivityIndicator(),
                                  SizedBox(height: 10),
                                  Text(
                                    'Mengunggah foto toping...',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (toppingImageUrl != null && toppingImageUrl!.isNotEmpty)
                          Column(
                            children: [
                              Container(
                                height: 130,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: context.surfaceBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.borderLight, width: 0.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: toppingImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 36)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () async {
                                      final url = await _uploadToppingImage((val) {
                                        setDialogState(() => isUploadingImage = val);
                                      });
                                      if (url != null) {
                                        setDialogState(() => toppingImageUrl = url);
                                      }
                                    },
                                    icon: const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Nebula.teal),
                                    label: Text('Ganti Foto', style: GoogleFonts.inter(fontSize: 12, color: Nebula.teal, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      setDialogState(() => toppingImageUrl = null);
                                    },
                                    icon: const Icon(CupertinoIcons.trash, size: 14, color: Nebula.rose),
                                    label: Text('Hapus Foto', style: GoogleFonts.inter(fontSize: 12, color: Nebula.rose, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          GestureDetector(
                            onTap: () async {
                              final url = await _uploadToppingImage((val) {
                                setDialogState(() => isUploadingImage = val);
                              });
                              if (url != null) {
                                setDialogState(() => toppingImageUrl = url);
                              }
                            },
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: context.surfaceBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.borderLight, width: 0.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.cloud_upload,
                                    size: 36,
                                    color: Nebula.teal.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pilih Gambar Toping',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Format JPG, PNG (Maks. 5MB)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: context.textSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressScale(
                              onTap: () {
                                if (editFormKey.currentState!.validate()) {
                                  final String name = editNameController.text.trim();
                                  final String priceStr = editPriceController.text.trim();

                                  String finalOption = name;
                                  if (priceStr.isNotEmpty) {
                                    final int? price = int.tryParse(priceStr);
                                    if (price != null && price > 0) {
                                      finalOption = "$name (+Rp ${_formatWithDots(price)})";
                                    }
                                  }
                                  if (toppingImageUrl != null && toppingImageUrl!.isNotEmpty) {
                                    finalOption = "$finalOption [img: ${toppingImageUrl!.trim()}]";
                                  }

                                  final bool exists = _customizableOptions.asMap().entries.any((entry) {
                                    if (index != null && entry.key == index) return false;
                                    final parsedEntry = _parseOption(entry.value);
                                    return parsedEntry['name'].toString().toLowerCase() == name.toLowerCase();
                                  });

                                  if (!exists) {
                                    setState(() {
                                      if (index != null) {
                                        _customizableOptions[index] = finalOption;
                                      } else {
                                        _customizableOptions.add(finalOption);
                                        _optionInputController.clear();
                                        _optionPriceController.clear();
                                        _quickToppingImageUrl = null;
                                      }
                                    });
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Toping dengan nama tersebut sudah ada.'),
                                        backgroundColor: Nebula.rose,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Nebula.teal,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  index != null ? 'Simpan' : 'Tambah',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPhotoOnlyUploadDialog() {
    String? toppingImageUrl = _quickToppingImageUrl;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.isDark ? context.surfaceBg : const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.borderLight, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUploadingImage)
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF181818) : context.surfaceBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.borderLight, width: 0.5),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(),
                              SizedBox(height: 10),
                              Text(
                                'Mengunggah foto toping...',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (toppingImageUrl != null && toppingImageUrl!.isNotEmpty)
                      Column(
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.isDark ? const Color(0xFF181818) : context.surfaceBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderLight, width: 0.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: toppingImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 36)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  final url = await _uploadToppingImage((val) {
                                    setDialogState(() => isUploadingImage = val);
                                  });
                                  if (url != null) {
                                    setDialogState(() => toppingImageUrl = url);
                                  }
                                },
                                icon: const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Nebula.teal),
                                label: Text('Ganti Foto', style: GoogleFonts.inter(fontSize: 12, color: Nebula.teal, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setDialogState(() => toppingImageUrl = null);
                                },
                                icon: const Icon(CupertinoIcons.trash, size: 14, color: Nebula.rose),
                                label: Text('Hapus Foto', style: GoogleFonts.inter(fontSize: 12, color: Nebula.rose, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          final url = await _uploadToppingImage((val) {
                            setDialogState(() => isUploadingImage = val);
                          });
                          if (url != null) {
                            setDialogState(() => toppingImageUrl = url);
                          }
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.isDark ? const Color(0xFF181818) : context.surfaceBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.borderLight, width: 0.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.cloud_upload,
                                size: 40,
                                color: Nebula.teal.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pilih Gambar Toping',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Nebula.teal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Format JPG, PNG (Maks. 5MB)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: context.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PressScale(
                          onTap: () {
                            setState(() {
                              _quickToppingImageUrl = toppingImageUrl;
                            });

                            final String optionName = _optionInputController.text.trim();
                            final String optionPriceStr = _optionPriceController.text.trim();

                            if (optionName.isNotEmpty) {
                              String finalOption = optionName;
                              if (optionPriceStr.isNotEmpty) {
                                final int? price = int.tryParse(optionPriceStr);
                                if (price != null && price > 0) {
                                  finalOption = "$optionName (+Rp ${_formatWithDots(price)})";
                                }
                              }
                              if (_quickToppingImageUrl != null && _quickToppingImageUrl!.isNotEmpty) {
                                finalOption = "$finalOption [img: ${_quickToppingImageUrl!.trim()}]";
                              }

                              final bool exists = _customizableOptions.any((opt) {
                                final cleanOpt = _parseOption(opt)['name'].toString().toLowerCase();
                                return cleanOpt == optionName.toLowerCase();
                              });

                              if (!exists) {
                                setState(() {
                                  _customizableOptions.add(finalOption);
                                  _optionInputController.clear();
                                  _optionPriceController.clear();
                                  _quickToppingImageUrl = null;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Toping dengan nama tersebut sudah ada.'),
                                    backgroundColor: Nebula.rose,
                                  ),
                                );
                              }
                            }
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Nebula.teal,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Tambah',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          SnackBar(content: Text(AppStrings.labelFailedPickImage), backgroundColor: Nebula.rose),
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
        const SnackBar(content: Text(AppStrings.errorInvalidSession), backgroundColor: Nebula.rose),
      );
      return;
    }

    final String name = _nameController.text.trim();
    final double price = double.parse(_priceController.text.trim());
    final bool isEdit = widget.initialProduct != null;
    String? finalImageUrl = isEdit ? widget.initialProduct!.imageUrl : null;

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
            throw Exception('${AppStrings.labelFailed} mengunggah gambar. Pastikan bucket "products" sudah dibuat di Supabase Storage Anda. Detail: $storageErr');
          }
        }
        
        finalImageUrl = client.storage.from('products').getPublicUrl(fileName);
      }
      
      final Map<String, dynamic> data = {
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'image_url': finalImageUrl,
        'customizable_options': _customizableOptions,
      };

      if (isEdit) {
        final String productId = widget.initialProduct!.id;
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
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan',
          message: isEdit ? AppStrings.successProductUpdated : AppStrings.successProductSaved,
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Save product error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailedSaveProduct}: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Nebula.rose,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
                    // Input Nama Jajanan
                    Text(
                      AppStrings.labelProductName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.textPrimary,
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
                            color: context.textPrimary,
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
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
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
                            if (val == 'minuman') {
                              // Auto cleanup: Remove spiciness, sauce, and vegetable options when switching to minuman category
                              _customizableOptions.removeWhere((opt) => _isSpiciness(opt) || _isSauce(opt) || _isVegetable(opt));
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Upload Gambar Produk
                    Text(
                      'Gambar Produk (Opsional)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.textPrimary,
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
                          color: context.surfaceBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.borderLight,
                            width: 0.5,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? CachedNetworkImage(
                                        imageUrl: _imageFile!.path,
                                        fit: BoxFit.cover,
                                        placeholder: (c, i) => const Center(child: CupertinoActivityIndicator()),
                                      )
                                    : Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : showExistingImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.initialProduct!.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (c, i) => const Center(child: CupertinoActivityIndicator()),
                                      errorWidget: (c, i, e) => _buildUploadPlaceholder(),
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
                              foregroundColor: Nebula.rose,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _removeImage,
                            icon: const Icon(CupertinoIcons.trash, size: 14),
                            label: Text('Hapus Gambar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Customizable Toppings/Options Section
                    Text(
                      'Pilihan Toping / Kustomisasi (Untuk Murid)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan pilihan kustomisasi yang bisa dipilih murid (misal: "Es Batu", "Tanpa Sayur", "Telur Dadar"). Anda juga bisa mengunggah foto untuk setiap toping.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Input Row with camera button right above "Belum ada pilihan kustomisasi"
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _optionInputController,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Nama toping/kustomisasi...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _optionPriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: const InputDecoration(
                              prefixText: '+Rp ',
                              hintText: 'Harga (opsional)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add button
                        PressScale(
                          onTap: () {
                            final String optionName = _optionInputController.text.trim();
                            final String optionPriceStr = _optionPriceController.text.trim();
                            if (optionName.isNotEmpty) {
                              String finalOption = optionName;
                              if (optionPriceStr.isNotEmpty) {
                                final int? price = int.tryParse(optionPriceStr);
                                if (price != null && price > 0) {
                                  finalOption = "$optionName (+Rp ${_formatWithDots(price)})";
                                }
                              }
                              if (_quickToppingImageUrl != null && _quickToppingImageUrl!.isNotEmpty) {
                                finalOption = "$finalOption [img: ${_quickToppingImageUrl!.trim()}]";
                              }

                              final bool exists = _customizableOptions.any((opt) {
                                final cleanOpt = _parseOption(opt)['name'].toString().toLowerCase();
                                return cleanOpt == optionName.toLowerCase();
                              });

                              if (!exists) {
                                setState(() {
                                  _customizableOptions.add(finalOption);
                                  _optionInputController.clear();
                                  _optionPriceController.clear();
                                  _quickToppingImageUrl = null;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Toping dengan nama tersebut sudah ada.'),
                                    backgroundColor: Nebula.rose,
                                  ),
                                );
                              }
                            } else {
                              _showPhotoOnlyUploadDialog();
                            }
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Nebula.teal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Dedicated button positioned directly above "Belum ada pilihan kustomisasi"
                    PressScale(
                      onTap: () => _showPhotoOnlyUploadDialog(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Nebula.teal.withValues(alpha: 0.25), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.camera_fill, size: 16, color: Nebula.teal),
                            const SizedBox(width: 6),
                            Text(
                              '+ Tambahkan Toping dengan Foto (Form Lengkap)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Nebula.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category-Aware Quick Preset Cards
                    if (_selectedCategory.toLowerCase() == 'minuman')
                      _buildDrinkPresetCard()
                    else
                      _buildSaucePresetCard(),

                    // Categorized options rendering
                    Builder(
                      builder: (context) {
                        final bool isBeverage = _selectedCategory.toLowerCase() == 'minuman';

                        if (_customizableOptions.isEmpty) {
                          return NebulaCard(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                isBeverage
                                    ? 'Belum ada pilihan kustomisasi minuman yang ditambahkan.'
                                    : 'Belum ada pilihan kustomisasi yang ditambahkan.',
                                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ),
                          );
                        }

                        // If category is Minuman, ONLY show drink toppings / options (No Spiciness, No Sauces, No Vegetables)
                        if (isBeverage) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategorizedOptionSection(
                                title: 'Pilihan Topping & Kustomisasi Minuman',
                                icon: '🍹',
                                options: _customizableOptions,
                                emptyPlaceholder: 'Belum ada opsi minuman (Gunakan preset es batu, gula, atau topping boba di atas)',
                              ),
                            ],
                          );
                        }

                        // For Makanan & Camilan: Show 4 Categorized Sections
                        final spicinessList = _customizableOptions.where((opt) => _isSpiciness(opt)).toList();
                        final sauceList = _customizableOptions.where((opt) => _isSauce(opt)).toList();
                        final toppingList = _customizableOptions.where((opt) => _isTopping(opt)).toList();
                        final vegetableList = _customizableOptions.where((opt) => _isVegetable(opt)).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategorizedOptionSection(
                              title: '1. Tingkat Kepedasan Saus Sambal',
                              icon: '🌶️',
                              options: spicinessList,
                              emptyPlaceholder: 'Belum ada pilihan level kepedasan (Gunakan "+ Atur Level (0 - N)" di atas)',
                            ),
                            _buildCategorizedOptionSection(
                              title: '2. Pilihan Saus Lainnya (Standar)',
                              icon: '🥫',
                              options: sauceList,
                              emptyPlaceholder: 'Belum ada saus standar (Pilih Saus Tomat, Saus Tiram, Saus Barbekyu, atau Saus Teriyaki di atas)',
                            ),
                            _buildCategorizedOptionSection(
                              title: '3. Pilihan Topping',
                              icon: '🍳',
                              options: toppingList,
                              emptyPlaceholder: 'Belum ada pilihan topping (Misal: Telur, Bakso, Sosis, Keju)',
                            ),
                            _buildCategorizedOptionSection(
                              title: '4. Lalapan & Sayuran',
                              icon: '🥒',
                              options: vegetableList,
                              emptyPlaceholder: 'Belum ada pilihan lalapan & sayuran (Misal: Timun, Selada)',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 48),

                    // Simpan Button
                    const GradientLine(),
                    SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        onTap: _isLoading ? null : _handleSave,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? CupertinoActivityIndicator(color: context.cardBg)
                              : Text(
                                  AppStrings.buttonSaveProduct.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: context.cardBg,
                                    letterSpacing: 0.5,
                                  ),
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
          color: Nebula.teal.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 12),
        Text(
          '${AppStrings.buttonSelect} Gambar Jajanan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Nebula.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Format JPG, PNG (Maks. 5MB)',
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}