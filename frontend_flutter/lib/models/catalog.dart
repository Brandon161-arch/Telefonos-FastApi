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
