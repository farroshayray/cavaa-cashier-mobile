import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/config/env.dart';
import 'owner_home_page.dart';
import 'work_schedule_blocks_editor.dart';
import 'work_schedule_utils.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

final _usernameRegex = RegExp(r'^[A-Za-z0-9._\-]+$');

String? resolveEmployeeImageUrl(dynamic raw) {
  final path = raw?.toString().trim();
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
  final clean = path.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('storage/')) return '$base/$clean';
  return '$base/storage/$clean';
}

class EmployeeEditorPage extends StatefulWidget {
  const EmployeeEditorPage({
    super.key,
    required this.stores,
    required this.allowedRoles,
    required this.defaultPartnerId,
    required this.categories,
    required this.availableMenus,
    this.workScheduleProfiles = const [],
    this.employee,
  });

  final Map<String, dynamic>? employee;
  final List<Map<String, dynamic>> stores;
  final List<String> allowedRoles;
  final int defaultPartnerId;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> availableMenus;
  final List<Map<String, dynamic>> workScheduleProfiles;

  @override
  State<EmployeeEditorPage> createState() => _EmployeeEditorPageState();
}

class _EmployeeEditorPageState extends State<EmployeeEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late int? _partnerId;
  late String _role;
  late bool _isActive;
  late bool _enforceSchedule;
  late List<WorkScheduleBlock> _blocks;
  late List<Map<String, dynamic>> _profiles;
  late Set<int> _kitchenCategoryIds;
  late Set<String> _permissions;

  String? _existingImagePath;
  String? _pickedImagePath;
  bool _removeImage = false;

  bool _obscure = true;
  bool _saving = false;
  String? _error;
  String? _usernameStatus;
  bool? _usernameAvailable;
  bool _checkingUsername = false;
  Timer? _usernameDebounce;
  final _picker = ImagePicker();
  final Set<String> _expandedSections = {};

  bool get _isEdit => widget.employee != null;
  int? get _employeeId =>
      int.tryParse('${widget.employee?['id'] ?? ''}');
  String? get _overlapError => findScheduleOverlapError(_blocks);

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _name = TextEditingController(text: e?['name']?.toString() ?? '');
    _username = TextEditingController(text: e?['user_name']?.toString() ?? '');
    _email = TextEditingController(text: e?['email']?.toString() ?? '');
    _password = TextEditingController();
    _partnerId = e?['partner_id'] is int
        ? e!['partner_id'] as int
        : int.tryParse('${e?['partner_id'] ?? ''}') ?? widget.defaultPartnerId;
    final role = e?['role']?.toString();
    _role = (role != null && widget.allowedRoles.contains(role))
        ? role
        : (widget.allowedRoles.isNotEmpty
            ? widget.allowedRoles.first
            : 'CASHIER');
    _isActive = e == null
        ? true
        : (e['is_active'] == true || e['is_active'] == 1);
    _enforceSchedule = e == null
        ? false
        : (e['enforce_work_schedule'] == true ||
            e['enforce_work_schedule'] == 1);
    _blocks = dayMapToBlocks(e?['schedule_blocks'] ?? e?['work_schedule']);
    _profiles = [...widget.workScheduleProfiles];
    _existingImagePath = e?['image']?.toString();
    final kitchen = e?['kitchen_category_ids'];
    _kitchenCategoryIds = {
      if (kitchen is List)
        ...kitchen
            .map((x) => int.tryParse('$x'))
            .whereType<int>(),
    };
    final perms = e?['permissions'];
    _permissions = {
      if (perms is List) ...perms.map((x) => x.toString()),
    };
    _username.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _username.removeListener(_onUsernameChanged);
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _usernameDebounce?.cancel();
    final value = _username.text.trim();
    if (value.isEmpty) {
      setState(() {
        _usernameStatus = null;
        _usernameAvailable = null;
        _checkingUsername = false;
      });
      return;
    }
    if (value.length < 3 || value.length > 30 || !_usernameRegex.hasMatch(value)) {
      setState(() {
        _usernameStatus =
            'Username 3–30 karakter: huruf, angka, titik, underscore, strip';
        _usernameAvailable = false;
        _checkingUsername = false;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameStatus = 'Memeriksa username…';
      _usernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final data = await ownerApiOf(context).checkEmployeeUsername(
          username: value,
          excludeId: _employeeId,
        );
        if (!mounted || _username.text.trim() != value) return;
        final available = data['available'] == true;
        setState(() {
          _usernameAvailable = available;
          _usernameStatus = data['message']?.toString() ??
              (available ? 'Username tersedia' : 'Username sudah dipakai');
          _checkingUsername = false;
        });
      } catch (_) {
        if (!mounted || _username.text.trim() != value) return;
        setState(() {
          _checkingUsername = false;
          _usernameAvailable = null;
          _usernameStatus = 'Gagal memeriksa username';
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _pickedImagePath = file.path;
      _removeImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _pickedImagePath = null;
      if (_existingImagePath != null && _existingImagePath!.isNotEmpty) {
        _removeImage = true;
      }
    });
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'CASHIER':
        return 'Kasir';
      case 'KITCHEN':
        return 'Kitchen';
      case 'MANAGER':
        return 'Manager';
      case 'SUPERVISOR':
        return 'Supervisor';
      default:
        return role;
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty || _partnerId == null) {
      setState(() => _error = 'Lengkapi nama, username, email, dan toko');
      return;
    }
    if (username.length < 3 ||
        username.length > 30 ||
        !_usernameRegex.hasMatch(username)) {
      setState(() => _error =
          'Username 3–30 karakter: huruf, angka, titik, underscore, strip');
      return;
    }
    if (_usernameAvailable == false) {
      setState(() => _error = _usernameStatus ?? 'Username tidak tersedia');
      return;
    }
    if (!_isEdit && _password.text.length < 8) {
      setState(() => _error = 'Password minimal 8 karakter');
      return;
    }
    if (_isEdit &&
        _password.text.isNotEmpty &&
        _password.text.length < 8) {
      setState(() => _error = 'Password baru minimal 8 karakter');
      return;
    }
    if (_enforceSchedule && _blocks.isEmpty) {
      setState(() => _error =
          'Tambahkan minimal satu rentang jam kerja jika pembatasan diaktifkan');
      return;
    }
    final overlap = _overlapError;
    if (overlap != null) {
      setState(() => _error = overlap);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ownerApiOf(context);
      final scheduleBlocks = _blocks.map((b) => b.toJson()).toList();
      final schedulePayload = blocksToDayMap(_blocks);

      if (_isEdit) {
        await api.updateEmployee(
          id: _employeeId!,
          name: name,
          username: username,
          email: email,
          partnerId: _partnerId!,
          role: _role,
          password: _password.text.trim().isEmpty ? null : _password.text,
          isActive: _isActive,
          enforceWorkSchedule: _enforceSchedule,
          workSchedule: schedulePayload,
          scheduleBlocks: scheduleBlocks,
          kitchenCategoryIds: _role == 'KITCHEN'
              ? _kitchenCategoryIds.toList()
              : const [],
          permissions: (_role == 'MANAGER' || _role == 'SUPERVISOR')
              ? _permissions.toList()
              : const [],
          imagePath: _pickedImagePath,
          removeImage: _removeImage && _pickedImagePath == null,
        );
      } else {
        await api.createEmployee(
          name: name,
          username: username,
          email: email,
          password: _password.text,
          partnerId: _partnerId!,
          role: _role,
          isActive: _isActive,
          enforceWorkSchedule: _enforceSchedule,
          workSchedule: schedulePayload,
          scheduleBlocks: scheduleBlocks,
          kitchenCategoryIds: _role == 'KITCHEN'
              ? _kitchenCategoryIds.toList()
              : const [],
          permissions: (_role == 'MANAGER' || _role == 'SUPERVISOR')
              ? _permissions.toList()
              : const [],
          imagePath: _pickedImagePath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        setState(() => _error = data['message'].toString());
      } else if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        setState(() {
          _error = errors.values
              .expand((v) => v is List ? v : [v])
              .map((x) => x.toString())
              .join('\n');
        });
      } else {
        setState(() => _error = 'Gagal menyimpan pegawai');
      }
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan pegawai');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    final expanded = _expandedSections.contains(id);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedSections.remove(id);
                  } else {
                    _expandedSections.add(id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: _brand, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Colors.black.withValues(alpha: 0.48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null && expanded) trailing,
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      Padding(
                        // Extra top padding so floating labels aren't clipped.
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? helper,
    Widget? suffix,
    Color? helperColor,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      helperStyle: TextStyle(
        color: helperColor ?? Colors.black.withValues(alpha: 0.45),
        fontSize: 12,
        height: 1.3,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.4),
      ),
    );
  }

  Widget _fieldGap() => const SizedBox(height: 16);

  @override
  Widget build(BuildContext context) {
    final previewUrl = _removeImage
        ? null
        : (_pickedImagePath != null
            ? null
            : resolveEmployeeImageUrl(_existingImagePath));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Pegawai' : 'Tambah Pegawai',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _sectionCard(
            id: 'photo',
            title: 'Foto profil',
            subtitle: 'Opsional. Disarankan foto wajah yang jelas.',
            icon: Icons.photo_camera_outlined,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _pickedImagePath != null
                            ? Image.file(
                                File(_pickedImagePath!),
                                fit: BoxFit.cover,
                              )
                            : previewUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: previewUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => ColoredBox(
                                      color: _brand.withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: _brand,
                                      ),
                                    ),
                                  )
                                : ColoredBox(
                                    color: _brand.withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: _brand,
                                      size: 34,
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubah foto pegawai',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG, atau WEBP. Maks. 2MB.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _saving ? null : _pickImage,
                                style: FilledButton.styleFrom(
                                  foregroundColor: _brand,
                                  backgroundColor:
                                      _brand.withValues(alpha: 0.1),
                                ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Pilih foto'),
                              ),
                              if (_pickedImagePath != null ||
                                  (!_removeImage &&
                                      (_existingImagePath?.isNotEmpty ??
                                          false)))
                                TextButton(
                                  onPressed: _saving ? null : _clearImage,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Hapus'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            id: 'account',
            title: 'Data akun',
            subtitle: 'Informasi login dan penempatan pegawai.',
            icon: Icons.badge_outlined,
            children: [
              DropdownButtonFormField<int>(
                key: ValueKey('partner-$_partnerId'),
                initialValue: _partnerId,
                decoration: _fieldDecoration(
                  _isEdit ? 'Toko (bisa dipindah)' : 'Toko / outlet',
                  helper: _isEdit
                      ? 'Ubah toko untuk memindahkan pegawai'
                      : null,
                ),
                items: widget.stores
                    .map(
                      (s) => DropdownMenuItem(
                        value: int.tryParse('${s['id']}'),
                        child: Text(s['name']?.toString() ?? '-'),
                      ),
                    )
                    .where((i) => i.value != null)
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _partnerId = v),
              ),
              _fieldGap(),
              DropdownButtonFormField<String>(
                key: ValueKey('role-$_role'),
                initialValue: _role,
                decoration: _fieldDecoration('Role'),
                items: widget.allowedRoles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_roleLabel(r)),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _role = v ?? _role),
              ),
              _fieldGap(),
              TextField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: _fieldDecoration('Nama lengkap'),
              ),
              _fieldGap(),
              TextField(
                controller: _username,
                enabled: !_saving,
                decoration: _fieldDecoration(
                  'Username login',
                  helper: _usernameStatus,
                  helperColor: _usernameAvailable == true
                      ? const Color(0xFF1B7F4E)
                      : _usernameAvailable == false
                          ? Colors.red
                          : null,
                  suffix: _checkingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameAvailable == null
                          ? null
                          : Icon(
                              _usernameAvailable!
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _usernameAvailable!
                                  ? const Color(0xFF1B7F4E)
                                  : Colors.red,
                            ),
                ),
              ),
              _fieldGap(),
              TextField(
                controller: _email,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('Email'),
              ),
              _fieldGap(),
              TextField(
                controller: _password,
                enabled: !_saving,
                obscureText: _obscure,
                decoration: _fieldDecoration(
                  _isEdit ? 'Password baru (opsional)' : 'Password',
                  helper: _isEdit
                      ? 'Kosongkan jika tidak ingin mengganti'
                      : 'Minimal 8 karakter',
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text(
                    'Akun aktif',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Nonaktifkan untuk memblokir login pegawai',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12.5,
                    ),
                  ),
                  activeThumbColor: _brand,
                  value: _isActive,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _isActive = v),
                ),
              ),
            ],
          ),
          if (_role == 'KITCHEN') ...[
            const SizedBox(height: 14),
            _sectionCard(
              id: 'kitchen',
              title: 'Kategori kitchen',
              subtitle: 'Pilih kategori yang boleh ditangani dapur.',
              icon: Icons.restaurant_menu_rounded,
              children: [
                if (widget.categories.isEmpty)
                  Text(
                    'Belum ada kategori produk.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  )
                else
                  ...widget.categories.map((c) {
                    final id = int.tryParse('${c['id']}') ?? 0;
                    final selected = _kitchenCategoryIds.contains(id);
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _brand,
                      title: Text(c['name']?.toString() ?? '-'),
                      onChanged: _saving
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _kitchenCategoryIds.add(id);
                                } else {
                                  _kitchenCategoryIds.remove(id);
                                }
                              });
                            },
                    );
                  }),
              ],
            ),
          ],
          if (_role == 'MANAGER' || _role == 'SUPERVISOR') ...[
            const SizedBox(height: 14),
            _sectionCard(
              id: 'permissions',
              title: 'Hak akses menu',
              subtitle: 'Menu staff yang boleh dibuka di web.',
              icon: Icons.lock_open_rounded,
              children: [
                if (widget.availableMenus.isEmpty)
                  Text(
                    'Tidak ada menu yang tersedia di paket Anda.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  )
                else
                  ...widget.availableMenus.map((m) {
                    final key = m['key']?.toString() ?? '';
                    final selected = _permissions.contains(key);
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _brand,
                      title: Text(m['label']?.toString() ?? key),
                      subtitle: (m['section']?.toString().isNotEmpty ?? false)
                          ? Text(m['section'].toString())
                          : null,
                      onChanged: _saving || key.isEmpty
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _permissions.add(key);
                                } else {
                                  _permissions.remove(key);
                                }
                              });
                            },
                    );
                  }),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _sectionCard(
            id: 'schedule',
            title: 'Jam kerja',
            subtitle: 'Tambah rentang jam, lalu pilih hari. Overnight diizinkan.',
            icon: Icons.schedule_rounded,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text(
                    'Batasi jam kerja',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Jika aktif, pegawai hanya bisa login saat jam kerja',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                      fontSize: 12.5,
                    ),
                  ),
                  activeThumbColor: _brand,
                  value: _enforceSchedule,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _enforceSchedule = v),
                ),
              ),
              const SizedBox(height: 14),
              WorkScheduleBlocksEditor(
                blocks: _blocks,
                profiles: _profiles,
                enabled: !_saving,
                overlapError: _overlapError,
                onChanged: (next) => setState(() => _blocks = next),
                onProfilesChanged: (next) =>
                    setState(() => _profiles = next),
                onProfileApplied: () => setState(() {
                  _expandedSections.add('schedule');
                }),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEdit ? 'Simpan Perubahan' : 'Simpan Pegawai',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
