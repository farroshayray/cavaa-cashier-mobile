import 'dart:convert';

import 'package:dio/dio.dart';
import '/core/network/dio_client.dart';
import '/features/auth/data/models/owner_model.dart';

class OwnerApi {
  final DioClient client;

  OwnerApi(this.client);

  Future<Map<String, dynamic>> createStore({
    required String name,
    required String address,
    String? city,
    String? province,
    String? contactPhone,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/stores',
      data: {
        'name': name,
        'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (province != null && province.isNotEmpty) 'province': province,
        if (contactPhone != null && contactPhone.isNotEmpty)
          'contact_phone': contactPhone,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getStore(int storeId) async {
    final res = await client.dio.get('/api/v1/mobile/owner/stores/$storeId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateStore({
    required int storeId,
    required String name,
    required String address,
    String? city,
    String? province,
    String? district,
    String? village,
    bool isActive = true,
    bool isCashierActive = true,
    bool isQrActive = false,
    bool isOpenbill = false,
    String? userWifi,
    String? passWifi,
    bool isWifiShown = false,
    bool isPpnActive = false,
    num? ppn,
    int cashRoundingUnit = 0,
    String? contactPerson,
    String? contactPhone,
    String? whatsapp,
    String? gmapsUrl,
    String? instagram,
    List<int>? manualPaymentIds,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/stores/$storeId',
      data: {
        'name': name,
        'address': address,
        if (city != null) 'city': city,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (village != null) 'village': village,
        'is_active': isActive,
        'is_cashier_active': isCashierActive,
        'is_qr_active': isQrActive,
        'is_openbill': isOpenbill,
        if (userWifi != null) 'user_wifi': userWifi,
        if (passWifi != null) 'pass_wifi': passWifi,
        'is_wifi_shown': isWifiShown,
        'is_ppn_active': isPpnActive,
        if (ppn != null) 'ppn': ppn,
        'cash_rounding_unit': cashRoundingUnit,
        if (contactPerson != null) 'contact_person': contactPerson,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (gmapsUrl != null) 'gmaps_url': gmapsUrl,
        if (instagram != null) 'instagram': instagram,
        if (manualPaymentIds != null) 'manual_payment_ids': manualPaymentIds,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<OwnerModel> selectStore(int storeId) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/stores/select',
      data: {'store_id': storeId},
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    final user = data['user'];
    if (user is! Map) {
      throw Exception('Invalid select store response');
    }
    return OwnerModel.fromJson(Map<String, dynamic>.from(user));
  }

  Future<Map<String, dynamic>> listProducts() async {
    final res = await client.dio.get('/api/v1/mobile/owner/products');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getProduct(int id) async {
    final res = await client.dio.get('/api/v1/mobile/owner/products/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required num price,
    String? description,
    String? categoryName,
    int? categoryId,
    int? promotionId,
    bool alwaysAvailable = true,
    bool isActive = true,
    bool isHotProduct = false,
    List<Map<String, dynamic>>? menuOptions,
    List<String>? imagePaths,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryId == null) 'category_name': categoryName ?? 'Umum',
      if (promotionId != null) 'promotion_id': promotionId,
      'always_available': alwaysAvailable ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'is_hot_product': isHotProduct ? 1 : 0,
      if (menuOptions != null) 'menu_options': jsonEncode(menuOptions),
    };
    if (imagePaths != null) {
      for (var i = 0; i < imagePaths.length; i++) {
        map['images[$i]'] = await MultipartFile.fromFile(imagePaths[i]);
      }
    }
    final res = await client.dio.post(
      '/api/v1/mobile/owner/products',
      data: FormData.fromMap(map),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateProduct({
    required int id,
    required num price,
    bool? alwaysAvailable,
    bool? isActive,
    bool? isHotProduct,
    int? promotionId,
    bool clearPromotion = false,
    List<Map<String, dynamic>>? optionSettings,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/products/$id',
      data: FormData.fromMap({
        'price': price,
        if (alwaysAvailable != null)
          'always_available': alwaysAvailable ? 1 : 0,
        if (isActive != null) 'is_active': isActive ? 1 : 0,
        if (isHotProduct != null) 'is_hot_product': isHotProduct ? 1 : 0,
        if (clearPromotion)
          'promotion_id': ''
        else if (promotionId != null)
          'promotion_id': promotionId,
        if (optionSettings != null)
          'option_settings': jsonEncode(optionSettings),
      }),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> assignProductsToStore(
    List<int> masterProductIds, {
    num? price,
    bool? alwaysAvailable,
    bool? isActive,
    bool? isHotProduct,
    int? promotionId,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/products/assign',
      data: {
        'master_product_ids': masterProductIds,
        if (price != null) 'price': price,
        if (alwaysAvailable != null) 'always_available': alwaysAvailable,
        if (isActive != null) 'is_active': isActive,
        if (isHotProduct != null) 'is_hot_product': isHotProduct,
        if (promotionId != null) 'promotion_id': promotionId,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> listMasterProducts() async {
    final res = await client.dio.get('/api/v1/mobile/owner/master-products');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getMasterProduct(int id) async {
    final res =
        await client.dio.get('/api/v1/mobile/owner/master-products/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createMasterProduct({
    required String name,
    required num price,
    String? description,
    String? categoryName,
    int? categoryId,
    int? promotionId,
    List<Map<String, dynamic>>? menuOptions,
    List<String>? imagePaths,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryId == null) 'category_name': categoryName ?? 'Umum',
      if (promotionId != null) 'promotion_id': promotionId,
      if (menuOptions != null) 'menu_options': jsonEncode(menuOptions),
    };
    if (imagePaths != null) {
      for (var i = 0; i < imagePaths.length; i++) {
        map['images[$i]'] = await MultipartFile.fromFile(imagePaths[i]);
      }
    }
    final res = await client.dio.post(
      '/api/v1/mobile/owner/master-products',
      data: FormData.fromMap(map),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateMasterProduct({
    required int id,
    required String name,
    required num price,
    String? description,
    String? categoryName,
    int? categoryId,
    int? promotionId,
    bool clearPromotion = false,
    List<Map<String, dynamic>>? menuOptions,
    List<String>? imagePaths,
    List<String>? keepImageFilenames,
    bool applyPriceAllOutlets = false,
    bool applyPromotionAllOutlets = false,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryId == null) 'category_name': categoryName ?? 'Umum',
      if (clearPromotion)
        'promotion_id': ''
      else if (promotionId != null)
        'promotion_id': promotionId,
      if (menuOptions != null) 'menu_options': jsonEncode(menuOptions),
      'keep_image_filenames': jsonEncode(keepImageFilenames ?? const []),
      'apply_price_all_outlets': applyPriceAllOutlets ? 1 : 0,
      'apply_promotion_all_outlets': applyPromotionAllOutlets ? 1 : 0,
    };
    if (imagePaths != null) {
      for (var i = 0; i < imagePaths.length; i++) {
        map['images[$i]'] = await MultipartFile.fromFile(imagePaths[i]);
      }
    }
    final res = await client.dio.post(
      '/api/v1/mobile/owner/master-products/$id',
      data: FormData.fromMap(map),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> deleteMasterProduct(int id) async {
    final res =
        await client.dio.delete('/api/v1/mobile/owner/master-products/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> listPaymentMethods() async {
    final res = await client.dio.get('/api/v1/mobile/owner/payment-methods');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createPaymentMethod({
    required String paymentType,
    required String providerName,
    required String providerAccountName,
    String? providerAccountNo,
    String? additionalInfo,
    String? imagePath,
    bool isActive = true,
  }) async {
    final form = FormData.fromMap({
      'payment_type': paymentType,
      'provider_name': providerName,
      'provider_account_name': providerAccountName,
      if (providerAccountNo != null && providerAccountNo.isNotEmpty)
        'provider_account_no': providerAccountNo,
      if (additionalInfo != null && additionalInfo.isNotEmpty)
        'additional_info': additionalInfo,
      'is_active': isActive ? 1 : 0,
      if (imagePath != null && imagePath.isNotEmpty)
        'images': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split(RegExp(r'[\\/]')).last,
        ),
    });

    final res = await client.dio.post(
      '/api/v1/mobile/owner/payment-methods',
      data: form,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updatePaymentMethod({
    required int id,
    required String paymentType,
    required String providerName,
    required String providerAccountName,
    String? providerAccountNo,
    String? additionalInfo,
    String? imagePath,
    bool isActive = true,
    bool removeQris = false,
  }) async {
    final form = FormData.fromMap({
      'payment_type': paymentType,
      'provider_name': providerName,
      'provider_account_name': providerAccountName,
      if (providerAccountNo != null && providerAccountNo.isNotEmpty)
        'provider_account_no': providerAccountNo,
      if (additionalInfo != null && additionalInfo.isNotEmpty)
        'additional_info': additionalInfo,
      'is_active': isActive ? 1 : 0,
      'remove_qris': removeQris ? 1 : 0,
      if (imagePath != null && imagePath.isNotEmpty)
        'images': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split(RegExp(r'[\\/]')).last,
        ),
    });

    final res = await client.dio.post(
      '/api/v1/mobile/owner/payment-methods/$id',
      data: form,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> deletePaymentMethod(int id) async {
    final res = await client.dio.delete(
      '/api/v1/mobile/owner/payment-methods/$id',
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> assignPaymentMethods(List<int> ids) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/payment-methods/assign',
      data: {'manual_payment_ids': ids},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> listEmployees({
    String? role,
    String? status,
    String? q,
  }) async {
    final res = await client.dio.get(
      '/api/v1/mobile/owner/employees',
      queryParameters: {
        if (role != null && role.isNotEmpty) 'role': role,
        if (status != null && status.isNotEmpty) 'status': status,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> checkEmployeeUsername({
    required String username,
    int? excludeId,
  }) async {
    final res = await client.dio.get(
      '/api/v1/mobile/owner/employees/check-username',
      queryParameters: {
        'username': username,
        if (excludeId != null) 'exclude_id': excludeId,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createEmployee({
    required String name,
    required String username,
    required String email,
    required String password,
    required int partnerId,
    required String role,
    bool isActive = true,
    bool enforceWorkSchedule = false,
    Map<String, dynamic>? workSchedule,
    List<Map<String, dynamic>>? scheduleBlocks,
    List<int>? kitchenCategoryIds,
    List<String>? permissions,
    String? imagePath,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'partner_id': partnerId,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'enforce_work_schedule': enforceWorkSchedule ? 1 : 0,
      if (scheduleBlocks != null) 'schedule_blocks': jsonEncode(scheduleBlocks),
      if (workSchedule != null) 'work_schedule': jsonEncode(workSchedule),
      if (kitchenCategoryIds != null)
        'kitchen_category_ids': jsonEncode(kitchenCategoryIds),
      if (permissions != null) 'permissions': jsonEncode(permissions),
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split(RegExp(r'[\\/]')).last,
        ),
    });

    final res = await client.dio.post(
      '/api/v1/mobile/owner/employees',
      data: form,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateEmployee({
    required int id,
    required String name,
    required String username,
    required String email,
    required int partnerId,
    required String role,
    String? password,
    bool isActive = true,
    bool enforceWorkSchedule = false,
    Map<String, dynamic>? workSchedule,
    List<Map<String, dynamic>>? scheduleBlocks,
    List<int>? kitchenCategoryIds,
    List<String>? permissions,
    String? imagePath,
    bool removeImage = false,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'username': username,
      'email': email,
      'partner_id': partnerId,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'enforce_work_schedule': enforceWorkSchedule ? 1 : 0,
      'remove_image': removeImage ? 1 : 0,
      if (password != null && password.isNotEmpty) ...{
        'password': password,
        'password_confirmation': password,
      },
      if (scheduleBlocks != null) 'schedule_blocks': jsonEncode(scheduleBlocks),
      if (workSchedule != null) 'work_schedule': jsonEncode(workSchedule),
      if (kitchenCategoryIds != null)
        'kitchen_category_ids': jsonEncode(kitchenCategoryIds),
      if (permissions != null) 'permissions': jsonEncode(permissions),
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split(RegExp(r'[\\/]')).last,
        ),
    });

    final res = await client.dio.post(
      '/api/v1/mobile/owner/employees/$id',
      data: form,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    final res = await client.dio.delete('/api/v1/mobile/owner/employees/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> listWorkScheduleProfiles() async {
    final res = await client.dio.get(
      '/api/v1/mobile/owner/work-schedule-profiles',
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createWorkScheduleProfile({
    required String name,
    required List<Map<String, dynamic>> scheduleBlocks,
    bool isActive = true,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/work-schedule-profiles',
      data: {
        'name': name,
        'schedule_blocks': scheduleBlocks,
        'is_active': isActive,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateWorkScheduleProfile({
    required int id,
    required String name,
    required List<Map<String, dynamic>> scheduleBlocks,
    bool isActive = true,
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/work-schedule-profiles/$id',
      data: {
        'name': name,
        'schedule_blocks': scheduleBlocks,
        'is_active': isActive,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> deleteWorkScheduleProfile(int id) async {
    final res = await client.dio.delete(
      '/api/v1/mobile/owner/work-schedule-profiles/$id',
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> listTables() async {
    final res = await client.dio.get('/api/v1/mobile/owner/tables');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createTable({
    required String tableNo,
    required String tableClass,
    String? newTableClass,
    String? description,
    String status = 'available',
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/tables',
      data: {
        'table_no': tableNo,
        'table_class': tableClass,
        if (newTableClass != null && newTableClass.isNotEmpty)
          'new_table_class': newTableClass,
        if (description != null && description.isNotEmpty)
          'description': description,
        'status': status,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> updateTable({
    required int id,
    required String tableNo,
    required String tableClass,
    String? newTableClass,
    String? description,
    String status = 'available',
  }) async {
    final res = await client.dio.post(
      '/api/v1/mobile/owner/tables/$id',
      data: {
        'table_no': tableNo,
        'table_class': tableClass,
        if (newTableClass != null && newTableClass.isNotEmpty)
          'new_table_class': newTableClass,
        if (description != null && description.isNotEmpty)
          'description': description,
        'status': status,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> deleteTable(int id) async {
    final res = await client.dio.delete('/api/v1/mobile/owner/tables/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getTableBarcode(int id) async {
    final res = await client.dio.get('/api/v1/mobile/owner/tables/$id/barcode');
    return Map<String, dynamic>.from(res.data as Map);
  }

  OwnerModel? parseUser(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map) {
      return OwnerModel.fromJson(Map<String, dynamic>.from(user));
    }
    return null;
  }
}
