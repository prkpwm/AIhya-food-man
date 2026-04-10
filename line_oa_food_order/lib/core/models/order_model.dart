class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final DateTime createdAt;
  final int estimatedWaitMinutes;
  final String? note;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.estimatedWaitMinutes,
    this.note,
  });

  double get totalPrice =>
      items.fold(0, (sum, item) => sum + item.totalPrice);

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        items: (json['items'] as List)
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: OrderStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        estimatedWaitMinutes: json['estimatedWaitMinutes'] as int,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'estimatedWaitMinutes': estimatedWaitMinutes,
        'note': note,
      };
}

class OrderItemModel {
  final String menuId;
  final String menuName;
  final int quantity;
  final double unitPrice;
  final int spiceLevel;
  final String? customNote;

  const OrderItemModel({
    required this.menuId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    required this.spiceLevel,
    this.customNote,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        menuId: json['menuId'] as String,
        menuName: json['menuName'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        spiceLevel: json['spiceLevel'] as int,
        customNote: json['customNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menuId': menuId,
        'menuName': menuName,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'spiceLevel': spiceLevel,
        'customNote': customNote,
      };
}

enum OrderStatus { pending, confirmed, preparing, ready, completed, cancelled }

extension OrderStatusExt on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'รอยืนยัน';
      case OrderStatus.confirmed:
        return 'ยืนยันแล้ว';
      case OrderStatus.preparing:
        return 'กำลังทำ';
      case OrderStatus.ready:
        return 'พร้อมส่ง';
      case OrderStatus.completed:
        return 'เสร็จสิ้น';
      case OrderStatus.cancelled:
        return 'ยกเลิก';
    }
  }
}
