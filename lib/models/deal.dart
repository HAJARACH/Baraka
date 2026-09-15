class Deal {
  final String id;
  final String businessName;
  final String title;
  final double originalPrice;
  final double discountedPrice;
  final String category;
  final String imageUrl;
  final String location;
  final double latitude;
  final double longitude;
  final int remainingCount;
  final DateTime expiresAt;

  Deal({
    required this.id,
    required this.businessName,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.category,
    required this.imageUrl,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.remainingCount,
    required this.expiresAt,
  });

  factory Deal.fromMap(Map<String, dynamic> map) {
    return Deal(
      id: map['id'].toString(),
      businessName: map['business_name'] ?? '',
      title: map['title'] ?? '',
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (map['discounted_price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Général',
      imageUrl: map['image_url'] ?? 'https://images.unsplash.com/photo-1541544741938-0af808871cc0',
      location: map['location'] ?? 'Marrakech',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 31.6295,
      longitude: (map['longitude'] as num?)?.toDouble() ?? -7.9811,
      remainingCount: (map['remaining_count'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(map['expires_at'] ?? '') ??
          DateTime.now().add(const Duration(hours: 2)),
    );
  }

  int get discountPercentage {
    if (originalPrice <= 0) return 0;
    return (((originalPrice - discountedPrice) / originalPrice) * 100).round();
  }
}