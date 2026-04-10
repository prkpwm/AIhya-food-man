class UserModel {
  final String id;
  final String email;
  final String password;
  final String shopName;
  final String lineChannelId;
  final String lineChannelSecret;
  final SubscriptionTier tier;
  final DateTime? subscriptionExpiry;

  const UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.shopName,
    required this.lineChannelId,
    required this.lineChannelSecret,
    required this.tier,
    this.subscriptionExpiry,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        shopName: json['shopName'] as String,
        lineChannelId: json['lineChannelId'] as String,
        lineChannelSecret: json['lineChannelSecret'] as String,
        tier: SubscriptionTier.values.byName(json['tier'] as String),
        subscriptionExpiry: json['subscriptionExpiry'] != null
            ? DateTime.parse(json['subscriptionExpiry'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'shopName': shopName,
        'lineChannelId': lineChannelId,
        'lineChannelSecret': lineChannelSecret,
        'tier': tier.name,
        'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      };
}

enum SubscriptionTier { free, silver, gold, platinum }

extension SubscriptionTierExt on SubscriptionTier {
  int get dailyCustomerLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 20;
      case SubscriptionTier.silver:
        return 100;
      case SubscriptionTier.gold:
        return 500;
      case SubscriptionTier.platinum:
        return -1; // unlimited
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.silver:
        return 'Silver';
      case SubscriptionTier.gold:
        return 'Gold';
      case SubscriptionTier.platinum:
        return 'Platinum';
    }
  }
}
