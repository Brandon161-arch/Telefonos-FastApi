class Phone {
  const Phone({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.stock,
    required this.ramGb,
    required this.storageGb,
    required this.color,
    required this.imageUrl,
    this.brandId,
    this.discountPrice,
    this.description,
    this.processor,
    this.screenSize,
    this.screenType,
    this.batteryMah,
    this.mainCameraMp,
    this.frontCameraMp,
    this.os,
    this.is5g = false,
    this.isFeatured = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.brandName,
  });

  final int id;
  final int? brandId;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final int stock;
  final int ramGb;
  final int storageGb;
  final String color;
  final String imageUrl;
  final String? description;
  final String? processor;
  final double? screenSize;
  final String? screenType;
  final int? batteryMah;
  final int? mainCameraMp;
  final int? frontCameraMp;
  final String? os;
  final bool is5g;
  final bool isFeatured;
  final double rating;
  final int ratingCount;
  final String? brandName;

  double get currentPrice => discountPrice != null && discountPrice! > 0
      ? discountPrice!
      : price;

  factory Phone.fromJson(Map<String, dynamic> json) {
    final brand = json['brand'];
    return Phone(
      id: (json['id'] as num).toInt(),
      brandId: (json['brand_id'] as num?)?.toInt(),
      name: json['name'] as String? ?? 'Teléfono',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      ramGb: (json['ram_gb'] as num?)?.toInt() ?? 0,
      storageGb: (json['storage_gb'] as num?)?.toInt() ?? 0,
      color: json['color'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String?,
      processor: json['processor'] as String?,
      screenSize: (json['screen_size'] as num?)?.toDouble(),
      screenType: json['screen_type'] as String?,
      batteryMah: (json['battery_mah'] as num?)?.toInt(),
      mainCameraMp: (json['main_camera_mp'] as num?)?.toInt(),
      frontCameraMp: (json['front_camera_mp'] as num?)?.toInt(),
      os: json['os'] as String?,
      is5g: json['is_5g'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      brandName: brand is Map<String, dynamic> ? brand['name'] as String? : null,
    );
  }
}
