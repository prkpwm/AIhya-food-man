class MenuModel {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final ShopType shopType;
  final int maxSpiceLevel;
  final List<String> ingredientIds;
  final bool isAvailable;

  const MenuModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.shopType,
    required this.maxSpiceLevel,
    required this.ingredientIds,
    required this.isAvailable,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) => MenuModel(
        id: json['id'] as String,
        merchantId: json['merchantId'] as String? ?? 'merchant-001',
        name: json['name'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String,
        shopType: ShopType.values.byName(json['shopType'] as String),
        maxSpiceLevel: json['maxSpiceLevel'] as int,
        ingredientIds: List<String>.from(json['ingredientIds'] as List),
        isAvailable: json['isAvailable'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchantId': merchantId,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'shopType': shopType.name,
        'maxSpiceLevel': maxSpiceLevel,
        'ingredientIds': ingredientIds,
        'isAvailable': isAvailable,
      };
}

enum ShopType { streetFood, restaurant, buffet }

extension ShopTypeExt on ShopType {
  String get displayName {
    switch (this) {
      case ShopType.streetFood:
        return 'ร้านตามสั่ง';
      case ShopType.restaurant:
        return 'ภัตตาคาร';
      case ShopType.buffet:
        return 'บุฟเฟ่ต์';
    }
  }
}
