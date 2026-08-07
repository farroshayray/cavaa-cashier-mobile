class OwnerOnboarding {
  final bool hasStore;
  final bool hasProduct;
  final bool hasPaymentMethod;
  final bool storeHasPaymentAssigned;
  final bool hasEmployee;
  final int? selectedStoreId;
  final String nextStep;
  final bool canCreateStore;
  final bool forceOnboarding;
  final int storeCount;
  final List<OwnerStore> stores;

  const OwnerOnboarding({
    required this.hasStore,
    required this.hasProduct,
    required this.hasPaymentMethod,
    required this.storeHasPaymentAssigned,
    required this.hasEmployee,
    required this.selectedStoreId,
    required this.nextStep,
    required this.canCreateStore,
    required this.forceOnboarding,
    required this.storeCount,
    required this.stores,
  });

  factory OwnerOnboarding.fromJson(Map<String, dynamic> json) {
    final storesRaw = json['stores'];
    final stores = storesRaw is List
        ? storesRaw
              .whereType<Map>()
              .map((e) => OwnerStore.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <OwnerStore>[];

    final storeCount = json['store_count'] is int
        ? json['store_count'] as int
        : int.tryParse('${json['store_count'] ?? stores.length}') ??
              stores.length;

    return OwnerOnboarding(
      hasStore: json['has_store'] == true,
      hasProduct: json['has_product'] == true,
      hasPaymentMethod: json['has_payment_method'] == true,
      storeHasPaymentAssigned: json['store_has_payment_assigned'] == true,
      hasEmployee: json['has_employee'] == true,
      selectedStoreId: json['selected_store_id'] is int
          ? json['selected_store_id'] as int
          : int.tryParse('${json['selected_store_id'] ?? ''}'),
      nextStep: (json['next_step'] ?? 'ready').toString(),
      canCreateStore: json['can_create_store'] != false,
      forceOnboarding:
          json['force_onboarding'] == true || stores.isEmpty,
      storeCount: storeCount,
      stores: stores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_store': hasStore,
      'has_product': hasProduct,
      'has_payment_method': hasPaymentMethod,
      'store_has_payment_assigned': storeHasPaymentAssigned,
      'has_employee': hasEmployee,
      'selected_store_id': selectedStoreId,
      'next_step': nextStep,
      'can_create_store': canCreateStore,
      'force_onboarding': forceOnboarding,
      'store_count': storeCount,
      'stores': stores.map((e) => e.toJson()).toList(),
    };
  }
}

class OwnerStore {
  final int id;
  final String name;
  final String? slug;
  final String? city;
  final String? address;
  final bool isActive;
  final bool isCashierActive;

  const OwnerStore({
    required this.id,
    required this.name,
    this.slug,
    this.city,
    this.address,
    this.isActive = true,
    this.isCashierActive = true,
  });

  factory OwnerStore.fromJson(Map<String, dynamic> json) {
    return OwnerStore(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: json['slug']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isCashierActive:
          json['is_cashier_active'] == true || json['is_cashier_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'city': city,
      'address': address,
      'is_active': isActive,
      'is_cashier_active': isCashierActive,
    };
  }
}

class OwnerPlanInfo {
  final int id;
  final String name;
  final String? slug;
  final bool requireVerification;
  final int? maxOutlets;
  final bool isTrial;

  const OwnerPlanInfo({
    required this.id,
    required this.name,
    this.slug,
    this.requireVerification = true,
    this.maxOutlets,
    this.isTrial = false,
  });

  factory OwnerPlanInfo.fromJson(Map<String, dynamic> json) {
    return OwnerPlanInfo(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: json['slug']?.toString(),
      requireVerification: json['require_verification'] != false,
      maxOutlets: json['max_outlets'] is int
          ? json['max_outlets'] as int
          : int.tryParse('${json['max_outlets'] ?? ''}'),
      isTrial: json['is_trial'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'require_verification': requireVerification,
      'max_outlets': maxOutlets,
      'is_trial': isTrial,
    };
  }
}

class OwnerModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? image;
  final bool isActive;
  final String? verificationStatus;
  final bool passwordIsSet;
  final bool needsPassword;
  final int? selectedPartnerId;
  final bool canCreateStore;
  final bool forceOnboarding;
  final OwnerPlanInfo? plan;
  final OwnerOnboarding? onboarding;

  const OwnerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.image,
    this.isActive = true,
    this.verificationStatus,
    this.passwordIsSet = true,
    this.needsPassword = false,
    this.selectedPartnerId,
    this.canCreateStore = true,
    this.forceOnboarding = false,
    this.plan,
    this.onboarding,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    final onboardingRaw = json['onboarding'];
    final planRaw = json['plan'];
    final onboarding = onboardingRaw is Map
        ? OwnerOnboarding.fromJson(Map<String, dynamic>.from(onboardingRaw))
        : null;

    return OwnerModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'owner').toString(),
      phoneNumber: json['phone_number']?.toString(),
      image: json['image']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      verificationStatus: json['verification_status']?.toString(),
      passwordIsSet: json['password_is_set'] != false,
      needsPassword:
          json['needs_password'] == true || json['password_is_set'] == false,
      selectedPartnerId: json['selected_partner_id'] is int
          ? json['selected_partner_id'] as int
          : int.tryParse('${json['selected_partner_id'] ?? ''}'),
      canCreateStore: json['can_create_store'] != false &&
          (onboarding?.canCreateStore ?? true),
      forceOnboarding: json['force_onboarding'] == true ||
          (onboarding?.forceOnboarding ?? false),
      plan: planRaw is Map
          ? OwnerPlanInfo.fromJson(Map<String, dynamic>.from(planRaw))
          : null,
      onboarding: onboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'image': image,
      'is_active': isActive,
      'verification_status': verificationStatus,
      'password_is_set': passwordIsSet,
      'needs_password': needsPassword,
      'selected_partner_id': selectedPartnerId,
      'can_create_store': canCreateStore,
      'force_onboarding': forceOnboarding,
      'plan': plan?.toJson(),
      'onboarding': onboarding?.toJson(),
    };
  }

  OwnerModel copyWith({
    OwnerOnboarding? onboarding,
    bool? needsPassword,
    bool? passwordIsSet,
    int? selectedPartnerId,
    bool? canCreateStore,
    bool? forceOnboarding,
  }) {
    return OwnerModel(
      id: id,
      name: name,
      email: email,
      role: role,
      phoneNumber: phoneNumber,
      image: image,
      isActive: isActive,
      verificationStatus: verificationStatus,
      passwordIsSet: passwordIsSet ?? this.passwordIsSet,
      needsPassword: needsPassword ?? this.needsPassword,
      selectedPartnerId: selectedPartnerId ?? this.selectedPartnerId,
      canCreateStore: canCreateStore ?? this.canCreateStore,
      forceOnboarding: forceOnboarding ?? this.forceOnboarding,
      plan: plan,
      onboarding: onboarding ?? this.onboarding,
    );
  }
}
