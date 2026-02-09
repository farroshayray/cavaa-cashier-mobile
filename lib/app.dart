import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/storage/secure_storage_service.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/pages/splash_page.dart';

class CavaaApp extends StatelessWidget {
  const CavaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorageService();
    final dioClient = DioClient(storage);
    final authApi = AuthApi(dioClient);
    final authRepo = AuthRepository(api: authApi, storage: storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cavaa Cashier',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFAE1504)),
        home: const SplashPage(),
      ),
    );
  }
}
