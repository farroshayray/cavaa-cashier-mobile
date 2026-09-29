import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/auth/presentation/auth_provider.dart';
import 'owner_home_page.dart';

const _brand = Color(0xFFAE1504);

/// Create-only page — used by header "+" and onboarding.
class CreateStorePage extends StatefulWidget {
  const CreateStorePage({super.key});

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _address.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_refresh);
    _address.removeListener(_refresh);
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Nama dan alamat wajib diisi');
      return;
    }

    final auth = context.read<AuthProvider>();
    final api = ownerApiOf(context);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.createStore(
        name: _name.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        contactPhone: _phone.text.trim(),
      );
      await auth.refreshOwner();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko berhasil dibuat')),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() {
        _error = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Gagal membuat toko';
      });
    } catch (_) {
      setState(() => _error = 'Gagal membuat toko');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _field(
    String label, {
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      prefixIcon: Icon(icon, color: _brand),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<AuthProvider>().owner;
    final canCreate = owner?.canCreateStore ??
        owner?.onboarding?.canCreateStore ??
        true;
    final maxOutlets = owner?.plan?.maxOutlets;
    final storeCount = owner?.onboarding?.stores.length ?? 0;
    final firstStore = storeCount == 0;
    final nameReady = _name.text.trim().isNotEmpty;
    final addressReady = _address.text.trim().isNotEmpty;
    final ownerName = owner?.name ?? 'Owner';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(
          firstStore ? 'Toko pertama' : 'Tambah Toko',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (firstStore)
            _WelcomeHero(name: ownerName)
          else
            _QuotaCard(storeCount: storeCount, maxOutlets: maxOutlets),
          const SizedBox(height: 14),
          if (!canCreate)
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  maxOutlets == null
                      ? 'Anda tidak dapat menambah toko saat ini.'
                      : 'Batas outlet paket sudah tercapai ($maxOutlets).',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      firstStore ? 'Data toko' : 'Outlet baru',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nama dan alamat wajib. Kota serta nomor kontak bisa dikosongkan.',
                      style: TextStyle(
                        height: 1.35,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: _field(
                        'Nama toko',
                        icon: Icons.storefront_rounded,
                        hint: 'Contoh Kedai Cavaa',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _field(
                        'Alamat',
                        icon: Icons.location_on_outlined,
                        hint: 'Jalan, nomor, kelurahan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      decoration: _field(
                        'Kota (opsional)',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: _field(
                        'No. kontak (opsional)',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NeedRow(ok: nameReady, label: 'Nama toko sudah diisi'),
                    const SizedBox(height: 6),
                    _NeedRow(ok: addressReady, label: 'Alamat sudah diisi'),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                firstStore ? 'Buat toko pertama' : 'Buat toko',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAE1504), Color(0xFF6E0C02)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/cavaa_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selamat datang. Isi toko pertama supaya kasir bisa mulai dipakai.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.storeCount, required this.maxOutlets});

  final int storeCount;
  final int? maxOutlets;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_mall_directory_rounded, color: _brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outlet baru',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maxOutlets == null
                        ? 'Saat ini Anda punya $storeCount toko.'
                        : 'Kuota paket: $storeCount / $maxOutlets outlet.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({required this.ok, required this.label});

  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF067647) : const Color(0xFF8A9099);
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
