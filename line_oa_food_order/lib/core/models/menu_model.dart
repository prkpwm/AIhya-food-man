class AddonOption {
  final String id;
  final String name;
  final double price;
  const AddonOption({required this.id, required this.name, required this.price});

  factory AddonOption.fromJson(Map<String, dynamic> json) => AddonOption(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

class PortionOption {
  final String id;
  final String name;
  final double extraPrice;
  const PortionOption({required this.id, required this.name, required this.extraPrice});

  factory PortionOption.fromJson(Map<String, dynamic> json) => PortionOption(
        id: json['id'] as String,
        name: json['name'] as String,
        extraPrice: (json['extraPrice'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'extraPrice': extraPrice};
}

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
  final List<AddonOption> addons;
  final List<PortionOption> portionOptions;

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
    this.addons = const [],
    this.portionOptions = const [],
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
        addons: (json['addons'] as List? ?? [])
            .map((e) => AddonOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        portionOptions: (json['portionOptions'] as List? ?? [])
            .map((e) => PortionOption.fromJson(e as Map<String, dynamic>))
            .toList(),
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
        'addons': addons.map((e) => e.toJson()).toList(),
        'portionOptions': portionOptions.map((e) => e.toJson()).toList(),
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
