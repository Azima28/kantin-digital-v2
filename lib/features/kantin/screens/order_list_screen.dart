import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';
import 'package:kantin_digital/features/kantin/widgets/order_item_card.dart';
import 'package:kantin_digital/features/kantin/widgets/order_status_tabs.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  String _selectedTab = 'semua';

  late List<OrderItem> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _buildMockOrders();
  }

  List<OrderItem> _buildMockOrders() {
    return [
      const OrderItem(
        id: '1',
        studentName: 'Budi Santoso',
        time: '10:15 WIB',
        status: 'Sedang Dimasak',
        items: [
          OrderSubItem(name: 'Nasi Goreng Spesial', qty: 1, price: 15000),
          OrderSubItem(name: 'Es Teh Manis', qty: 1, price: 5000),
        ],
        totalAmount: 20000,
      ),
      const OrderItem(
        id: '2',
        studentName: 'Siti Aminah',
        time: '09:45 WIB',
        status: 'Siap Diambil',
        items: [
          OrderSubItem(name: 'Mie Ayam Bakso', qty: 2, price: 30000),
          OrderSubItem(name: 'Jus Jeruk', qty: 1, price: 8000),
        ],
        totalAmount: 38000,
      ),
      const OrderItem(
        id: '3',
        studentName: 'Agus Pratama',
        time: '09:30 WIB',
        status: 'Siap Diantar',
        deliveryLocation: 'Ruang Guru',
        items: [
          OrderSubItem(name: 'Kopi Hitam', qty: 3, price: 15000),
          OrderSubItem(name: 'Roti Bakar Coklat', qty: 1, price: 12000),
        ],
        totalAmount: 27000,
      ),
      const OrderItem(
        id: '4',
        studentName: 'Dewi Lestari',
        time: '10:30 WIB',
        status: 'Baru',
        items: [
          OrderSubItem(name: 'Ayam Geprek', qty: 1, price: 15000),
          OrderSubItem(name: 'Air Mineral', qty: 1, price: 3000),
        ],
        totalAmount: 18000,
      ),
      const OrderItem(
        id: '5',
        studentName: 'Rian Hidayat',
        time: '10:25 WIB',
        status: 'Baru',
        items: [
          OrderSubItem(name: 'Roti Bakar', qty: 2, price: 16000),
          OrderSubItem(name: 'Susu Coklat', qty: 2, price: 10000),
        ],
        totalAmount: 26000,
      ),
      const OrderItem(
        id: '6',
        studentName: 'Eka Saputra',
        time: '10:20 WIB',
        status: 'Baru',
        items: [
          OrderSubItem(name: 'Nasi Uduk', qty: 1, price: 12000),
          OrderSubItem(name: 'Teh Tawar', qty: 1, price: 3000),
        ],
        totalAmount: 15000,
      ),
      const OrderItem(
        id: '7',
        studentName: 'Lina Marlina',
        time: '10:10 WIB',
        status: 'Baru',
        items: [
          OrderSubItem(name: 'Batagor', qty: 1, price: 10000),
        ],
        totalAmount: 10000,
      ),
      const OrderItem(
        id: '8',
        studentName: 'Dedi Kurniawan',
        time: '10:05 WIB',
        status: 'Baru',
        items: [
          OrderSubItem(name: 'Siomay', qty: 2, price: 16000),
          OrderSubItem(name: 'Es Jeruk', qty: 1, price: 7000),
        ],
        totalAmount: 23000,
      ),
      const OrderItem(
        id: '9',
        studentName: 'Fajar Siddiq',
        time: '09:55 WIB',
        status: 'Sedang Dimasak',
        items: [
          OrderSubItem(name: 'Soto Ayam', qty: 1, price: 15000),
          OrderSubItem(name: 'Es Teh Manis', qty: 1, price: 5000),
        ],
        totalAmount: 20000,
      ),
      const OrderItem(
        id: '10',
        studentName: 'Hendra Wijaya',
        time: '09:50 WIB',
        status: 'Sedang Dimasak',
        items: [
          OrderSubItem(name: 'Bakso Kuah', qty: 2, price: 24000),
        ],
        totalAmount: 24000,
      ),
      const OrderItem(
        id: '11',
        studentName: 'Rini Anggraini',
        time: '09:40 WIB',
        status: 'Sedang Dimasak',
        items: [
          OrderSubItem(name: 'Gado-Gado', qty: 1, price: 12000),
          OrderSubItem(name: 'Es Jeruk', qty: 1, price: 7000),
        ],
        totalAmount: 19000,
      ),
      const OrderItem(
        id: '12',
        studentName: 'Mega Lestari',
        time: '09:35 WIB',
        status: 'Sedang Dimasak',
        items: [
          OrderSubItem(name: 'Mie Goreng', qty: 1, price: 12000),
        ],
        totalAmount: 12000,
      ),
    ];
  }

  void _updateOrderStatus(String id, String newStatus) {
    setState(() {
      _orders = _orders.map((order) {
        if (order.id == id) {
          return order.copyWith(status: newStatus);
        }
        return order;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status pesanan berhasil diubah menjadi "$newStatus"'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<OrderItem> filteredOrders = _orders.where((order) {
      if (_selectedTab == 'baru') {
        return order.status == 'Baru';
      } else if (_selectedTab == 'proses') {
        return order.status == 'Sedang Dimasak' ||
            order.status == 'Siap Diambil' ||
            order.status == 'Siap Diantar';
      }
      return true;
    }).toList();

    final int countSemua = _orders.length;
    final int countBaru = _orders.where((o) => o.status == 'Baru').length;
    final int countProses = _orders.where((o) =>
        o.status == 'Sedang Dimasak' ||
        o.status == 'Siap Diambil' ||
        o.status == 'Siap Diantar').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.gray400.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        leading: Center(
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                CupertinoIcons.person_crop_circle,
                color: AppColors.teal,
                size: 24,
              ),
              onPressed: () {},
            ),
          ),
        ),
        title: Text(
          'Daftar Pesanan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.teal,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.bell,
              color: AppColors.teal,
              size: 24,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Segmented Tabs Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: OrderStatusTabs(
                    selectedTab: _selectedTab,
                    countSemua: countSemua,
                    countBaru: countBaru,
                    countProses: countProses,
                    onTabChanged: (tab) {
                      setState(() => _selectedTab = tab);
                    },
                  ),
                ),

                // Order Cards List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.square_list,
                                size: 64,
                                color: AppColors.gray400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada pesanan',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return OrderItemCard(
                              order: filteredOrders[index],
                              onStatusChanged: _updateOrderStatus,
                            );
                          },
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
