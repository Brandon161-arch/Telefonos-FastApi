class StoreReview {
  const StoreReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory StoreReview.fromJson(Map<String, dynamic> json) => StoreReview(
        id: (json['id'] as num).toInt(),
        userName: json['user_name'] as String? ?? 'Cliente',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}
