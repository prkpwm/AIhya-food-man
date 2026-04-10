class IngredientModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double lowStockThreshold;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
  });

  bool get isAvailable => quantity > 0;
  bool get isLowStock => quantity <= lowStockThreshold && quantity > 0;

  factory IngredientModel.fromJson(Map<String, dynamic> json) => IngredientModel(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        lowStockThreshold: (json['lowStockThreshold'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'lowStockThreshold': lowStockThreshold,
      };
}
