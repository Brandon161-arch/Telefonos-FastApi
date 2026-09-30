class Brand {
  const Brand({required this.id, required this.name, required this.slug});
  final int id;
  final String name;
  final String slug;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? 'Marca',
        slug: json['slug'] as String? ?? '',
      );
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  final int id;
  final String orderNumber;
  final String customerName;
  final double total;
  final String status;
  final String paymentMethod;
  final String? createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: (json['id'] as num).toInt(),
        orderNumber: json['order_number'] as String? ?? '',
        customerName: json['customer_name'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? '',
        paymentMethod: json['payment_method'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}

class AdminMetrics {
  const AdminMetrics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalPhones,
    required this.totalBrands,
    required this.totalUsers,
    required this.lowStockCount,
    required this.lowStockItems,
  });

  final double totalRevenue;
  final int totalOrders;
  final int totalPhones;
  final int totalBrands;
  final int totalUsers;
  final int lowStockCount;
  final List<Map<String, dynamic>> lowStockItems;

  factory AdminMetrics.fromJson(Map<String, dynamic> json) => AdminMetrics(
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
        totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
        totalPhones: (json['total_phones'] as num?)?.toInt() ?? 0,
        totalBrands: (json['total_brands'] as num?)?.toInt() ?? 0,
        totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
        lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
        lowStockItems: (json['low_stock_items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
