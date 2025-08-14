class SubscriptionModel {
  final String status;
  final String product;
  final String name;
  final int daysLeft;
  final int commentsRemaining;
  final int noc;
  final String? nextInvoiceDate;
  final PaymentDetails? paymentDetails;

  SubscriptionModel({
    required this.status,
    required this.product,
    required this.name,
    required this.daysLeft,
    required this.commentsRemaining,
    required this.noc,
    this.nextInvoiceDate,
    this.paymentDetails,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      status: json['status'] ?? 'inactive',
      product: json['product'] ?? 'Unknown',
      name: json['name'] ?? 'User',
      daysLeft: json['daysleft'] ?? json['daysLeft'] ?? 0,
      commentsRemaining: json['comments_remaining'] ?? json['NOC'] ?? 0,
      noc: json['NOC'] ?? json['comments_remaining'] ?? 0,
      nextInvoiceDate: json['nextInvoice'],
      paymentDetails: json['paymentDetails'] != null 
        ? PaymentDetails.fromJson(json['paymentDetails'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'product': product,
      'name': name,
      'daysLeft': daysLeft,
      'comments_remaining': commentsRemaining,
      'NOC': noc,
      'nextInvoice': nextInvoiceDate,
      'paymentDetails': paymentDetails?.toJson(),
    };
  }

  bool get isActive => status == 'active' || status == 'trialing';
  bool get isTrial => status == 'trialing';
  bool get isInactive => status == 'inactive';
  bool get hasPaidPlan => product != 'Free Trial' && product != 'No Product';
  bool get hasComments => commentsRemaining > 0;

  String get planDisplayName {
    switch (product) {
      case 'Pro Monthly':
        return 'Pro (Monthly)';
      case 'Pro Yearly':
        return 'Pro (Yearly)';
      case 'Gold Monthly':
        return 'Gold (Monthly)';
      case 'Gold Yearly':
        return 'Gold (Yearly)';
      case 'Free Trial':
        return 'Free Trial';
      default:
        return product;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active':
        return 'Active';
      case 'trialing':
        return 'Trial';
      case 'inactive':
        return 'Inactive';
      case 'canceled':
        return 'Canceled';
      case 'past_due':
        return 'Past Due';
      default:
        return status.toUpperCase();
    }
  }
}

class PaymentDetails {
  final String cardType;
  final String last4;

  PaymentDetails({
    required this.cardType,
    required this.last4,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      cardType: json['cardType'] ?? 'No Card Provided',
      last4: json['last4'] ?? '0000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardType': cardType,
      'last4': last4,
    };
  }

  bool get hasCard => cardType != 'No Card Provided' && last4 != '0000';

  String get displayCardInfo {
    if (!hasCard) return 'No payment method';
    return '${cardType.toUpperCase()} •••• $last4';
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String displayName;
  final double monthlyPrice;
  final double yearlyPrice;
  final double monthlyPriceINR;
  final double yearlyPriceINR;
  final double discountedYearlyPriceINR;
  final int monthlyComments;
  final int yearlyComments;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.monthlyPriceINR,
    required this.yearlyPriceINR,
    required this.discountedYearlyPriceINR,
    required this.monthlyComments,
    required this.yearlyComments,
    required this.features,
    this.isPopular = false,
  });

  static List<SubscriptionPlan> get availablePlans => [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      displayName: 'Free',
      monthlyPrice: 0,
      yearlyPrice: 0,
      monthlyPriceINR: 0,
      yearlyPriceINR: 0,
      discountedYearlyPriceINR: 0,
      monthlyComments: 75,
      yearlyComments: 75,
      features: [
        '75 Comments per month',
        'Basic Gold Access',
        'Dashboard Access',
        'No Credit Card Required',
      ],
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      displayName: 'Pro',
      monthlyPrice: 9.99,
      yearlyPrice: 107.91,
      monthlyPriceINR: 499,
      yearlyPriceINR: 4999,
      discountedYearlyPriceINR: 4491,
      monthlyComments: 300,
      yearlyComments: 3600,
      features: [
        '3600 Comments per year',
        '3 Different Tones',
        'Customer support 3-4 business days',
        'Multilingual support',
      ],
    ),
    SubscriptionPlan(
      id: 'gold',
      name: 'Gold',
      displayName: 'Gold',
      monthlyPrice: 12.49,
      yearlyPrice: 134.91,
      monthlyPriceINR: 630,
      yearlyPriceINR: 6300,
      discountedYearlyPriceINR: 5666,
      monthlyComments: 500,
      yearlyComments: 6000,
      features: [
        'All-Inclusive Pro Features',
        '6000 Comments per year',
        'Customer support priority (48 hours)',
        'Proof Read',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      id: 'enterprise',
      name: 'Enterprise',
      displayName: 'Enterprise',
      monthlyPrice: 0, // Contact sales
      yearlyPrice: 0, // Contact sales
      monthlyPriceINR: 0,
      yearlyPriceINR: 0,
      discountedYearlyPriceINR: 0,
      monthlyComments: -1, // Unlimited
      yearlyComments: -1, // Unlimited
      features: [
        'Custom Integrations',
        'Flexible Comment Packages',
        'Tailored onboarding',
        'Analytics and Reporting',
      ],
    ),
  ];

  String getPriceDisplay(bool isYearly, {bool isIndianUser = false}) {
    if (monthlyPrice == 0 && yearlyPrice == 0) {
      return name == 'Free' ? (isIndianUser ? '₹0' : '\$0') : 'Contact Sales';
    }
    
    if (isIndianUser) {
      return isYearly 
        ? '₹${discountedYearlyPriceINR.toStringAsFixed(0)}/year'
        : '₹${monthlyPriceINR.toStringAsFixed(0)}/month';
    } else {
      return isYearly 
        ? '\$${yearlyPrice.toStringAsFixed(2)}/year'
        : '\$${monthlyPrice.toStringAsFixed(2)}/month';
    }
  }

  String getOriginalPriceDisplay(bool isYearly, {bool isIndianUser = false}) {
    if (!isYearly || (name != 'Pro' && name != 'Gold')) {
      return ''; // No original price to show
    }
    
    if (isIndianUser) {
      return '₹${yearlyPriceINR.toStringAsFixed(0)}/year';
    } else {
      // For USD, calculate original price based on monthly * 12
      final originalYearlyPrice = monthlyPrice * 12;
      return '\$${originalYearlyPrice.toStringAsFixed(2)}/year';
    }
  }

  String getCommentsDisplay(bool isYearly) {
    final comments = isYearly ? yearlyComments : monthlyComments;
    if (comments == -1) return 'Unlimited';
    return '$comments per ${isYearly ? 'year' : 'month'}';
  }

  double getSavingsPercentage() {
    if (monthlyPrice == 0 || yearlyPrice == 0) return 0;
    final yearlyEquivalent = monthlyPrice * 12;
    return ((yearlyEquivalent - yearlyPrice) / yearlyEquivalent * 100);
  }

  bool get isFreePlan => monthlyPrice == 0 && yearlyPrice == 0 && name == 'Free';
  bool get isEnterprisePlan => name == 'Enterprise';
}
