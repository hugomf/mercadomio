// Admin pricing models mirroring backend/models/pricing.go JSON.

enum PriceRuleKind {
  percentage,
  absolute,
  override;

  static PriceRuleKind fromName(String? name) {
    switch (name) {
      case 'absolute':
        return PriceRuleKind.absolute;
      case 'override':
        return PriceRuleKind.override;
      default:
        return PriceRuleKind.percentage;
    }
  }

  String get name => switch (this) {
        PriceRuleKind.percentage => 'percentage',
        PriceRuleKind.absolute => 'absolute',
        PriceRuleKind.override => 'override',
      };
}

enum RuleScope {
  all,
  product,
  category,
  variant,
  sku;

  static RuleScope fromName(String? name) {
    switch (name) {
      case 'product':
        return RuleScope.product;
      case 'category':
        return RuleScope.category;
      case 'variant':
        return RuleScope.variant;
      case 'sku':
        return RuleScope.sku;
      default:
        return RuleScope.all;
    }
  }

  String get name => switch (this) {
        RuleScope.all => 'all',
        RuleScope.product => 'product',
        RuleScope.category => 'category',
        RuleScope.variant => 'variant',
        RuleScope.sku => 'sku',
      };
}

class PriceRule {
  final PriceRuleKind kind;
  final double amount;
  final RuleScope scope;
  final List<String> scopeRefs;
  final double maxDiscount;
  final int priority;

  PriceRule({
    required this.kind,
    this.amount = 0,
    this.scope = RuleScope.all,
    this.scopeRefs = const [],
    this.maxDiscount = 0,
    this.priority = 1,
  });

  factory PriceRule.fromJson(Map<String, dynamic> json) {
    return PriceRule(
      kind: PriceRuleKind.fromName(json['kind']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      scope: RuleScope.fromName(json['scope']?.toString()),
      scopeRefs: (json['scopeRefs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'amount': amount,
        'scope': scope.name,
        if (scopeRefs.isNotEmpty) 'scopeRefs': scopeRefs,
        if (maxDiscount > 0) 'maxDiscount': maxDiscount,
        'priority': priority,
      };
}

class PriceConditions {
  final String couponCode;
  final double minSubtotal;
  final int minQuantity;
  final String customerTier;
  final List<String> customerIds;

  const PriceConditions({
    this.couponCode = '',
    this.minSubtotal = 0,
    this.minQuantity = 0,
    this.customerTier = '',
    this.customerIds = const [],
  });

  factory PriceConditions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PriceConditions();
    return PriceConditions(
      couponCode: json['couponCode']?.toString() ?? '',
      minSubtotal: (json['minSubtotal'] as num?)?.toDouble() ?? 0,
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 0,
      customerTier: json['customerTier']?.toString() ?? '',
      customerIds: (json['customerIDs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        if (couponCode.isNotEmpty) 'couponCode': couponCode,
        if (minSubtotal > 0) 'minSubtotal': minSubtotal,
        if (minQuantity > 0) 'minQuantity': minQuantity,
        if (customerTier.isNotEmpty) 'customerTier': customerTier,
        if (customerIds.isNotEmpty) 'customerIDs': customerIds,
      };
}

class PriceSet {
  final String id;
  final String name;
  final String description;
  final int priority;
  final bool stopFurtherRules;
  final PriceConditions conditions;
  final List<PriceRule> rules;
  final int maxUses;
  final int usedCount;
  final int maxUsesPerCustomer;
  final bool active;
  final DateTime? startsAt;
  final DateTime? endsAt;

  PriceSet({
    this.id = '',
    required this.name,
    this.description = '',
    this.priority = 1,
    this.stopFurtherRules = false,
    this.conditions = const PriceConditions(),
    this.rules = const [],
    this.maxUses = 0,
    this.usedCount = 0,
    this.maxUsesPerCustomer = 0,
    this.active = true,
    this.startsAt,
    this.endsAt,
  });

  factory PriceSet.fromJson(Map<String, dynamic> json) {
    return PriceSet(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      stopFurtherRules: json['stopFurtherRules'] == true,
      conditions: PriceConditions.fromJson(
          (json['conditions'] as Map<String, dynamic>?)),
      rules: (json['rules'] as List?)
              ?.map((e) => PriceRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 0,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      maxUsesPerCustomer: (json['maxUsesPerCustomer'] as num?)?.toInt() ?? 0,
      active: json['active'] ?? true,
      startsAt: json['startsAt'] != null
          ? DateTime.tryParse(json['startsAt'].toString())
          : null,
      endsAt: json['endsAt'] != null
          ? DateTime.tryParse(json['endsAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'priority': priority,
        'stopFurtherRules': stopFurtherRules,
        'conditions': conditions.toJson(),
        'rules': rules.map((r) => r.toJson()).toList(),
        if (maxUses > 0) 'maxUses': maxUses,
        if (maxUsesPerCustomer > 0) 'maxUsesPerCustomer': maxUsesPerCustomer,
        'active': active,
        if (startsAt != null) 'startsAt': startsAt!.toIso8601String(),
        if (endsAt != null) 'endsAt': endsAt!.toIso8601String(),
      };
}

enum ScheduleScope {
  global,
  category,
  product,
  variant;

  static ScheduleScope fromName(String? name) {
    switch (name) {
      case 'category':
        return ScheduleScope.category;
      case 'product':
        return ScheduleScope.product;
      case 'variant':
        return ScheduleScope.variant;
      default:
        return ScheduleScope.global;
    }
  }

  String get name => switch (this) {
        ScheduleScope.global => 'global',
        ScheduleScope.category => 'category',
        ScheduleScope.product => 'product',
        ScheduleScope.variant => 'variant',
      };
}

enum ScheduleMode {
  percentage,
  absolute,
  fixed;

  static ScheduleMode fromName(String? name) {
    switch (name) {
      case 'absolute':
        return ScheduleMode.absolute;
      case 'fixed':
        return ScheduleMode.fixed;
      default:
        return ScheduleMode.percentage;
    }
  }

  String get name => switch (this) {
        ScheduleMode.percentage => 'percentage',
        ScheduleMode.absolute => 'absolute',
        ScheduleMode.fixed => 'fixed',
      };
}

class PriceSchedule {
  final String id;
  final String name;
  final String description;
  final ScheduleScope scope;
  final List<String> scopeRefs;
  final ScheduleMode mode;
  final double value;
  final int priority;
  final bool active;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  PriceSchedule({
    this.id = '',
    required this.name,
    this.description = '',
    this.scope = ScheduleScope.global,
    this.scopeRefs = const [],
    this.mode = ScheduleMode.percentage,
    required this.value,
    this.priority = 1,
    this.active = true,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  factory PriceSchedule.fromJson(Map<String, dynamic> json) {
    return PriceSchedule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      scope: ScheduleScope.fromName(json['scope']?.toString()),
      scopeRefs: (json['scopeRefs'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      mode: ScheduleMode.fromName(json['mode']?.toString()),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      active: json['active'] ?? true,
      effectiveFrom: DateTime.tryParse(json['effectiveFrom']?.toString() ?? '') ?? DateTime.now(),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.tryParse(json['effectiveTo'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'scope': scope.name,
        if (scopeRefs.isNotEmpty) 'scopeRefs': scopeRefs,
        'mode': mode.name,
        'value': value,
        'priority': priority,
        'active': active,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
      };
}

class PriceHistoryEntry {
  final String productId;
  final String variantId;
  final double oldPrice;
  final double newPrice;
  final String reason;
  final String sourceType;
  final String sourceRef;
  final DateTime effectiveAt;

  PriceHistoryEntry({
    required this.productId,
    this.variantId = '',
    required this.oldPrice,
    required this.newPrice,
    this.reason = '',
    this.sourceType = '',
    this.sourceRef = '',
    required this.effectiveAt,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      oldPrice: (json['oldPrice'] as num?)?.toDouble() ?? 0,
      newPrice: (json['newPrice'] as num?)?.toDouble() ?? 0,
      reason: json['reason']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceRef: json['sourceRef']?.toString() ?? '',
      effectiveAt: DateTime.tryParse(json['effectiveAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}