import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'owner_home_page.dart';
import 'work_schedule_blocks_editor.dart';
import 'work_schedule_utils.dart';

const _brand = Color(0xFFAE1504);
const _bg = Color(0xFFF6F7F9);

class WorkScheduleProfilesPage extends StatefulWidget {
  const WorkScheduleProfilesPage({super.key});

  @override
  State<WorkScheduleProfilesPage> createState() =>
      _WorkScheduleProfilesPageState();
}

class _WorkScheduleProfilesPageState extends State<WorkScheduleProfilesPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ownerApiOf(context).listWorkScheduleProfiles();
      final list = data['profiles'];
      setState(() {
        _profiles = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat profil jam kerja');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? profile}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkScheduleProfileEditorPage(profile: profile),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _delete(Map<String, dynamic> profile) async {
    final id = int.tryParse('${profile['id']}') ?? 0;
    if (id <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus profil?'),
        content: Text('Hapus “${profile['name']}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ownerApiOf(context).deleteWorkScheduleProfile(id);
      await _load();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menghapus profil',
          ),
        ),
      );
    }
  }

  String _summary(Map<String, dynamic> profile) {
    final blocks = profileToBlocks(profile);
    if (blocks.isEmpty) return 'Tanpa jam';
    return blocks
        .take(3)
        .map((b) =>
            '${b.start}–${b.end} (${b.days.length} hari)')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Profil Jam Kerja',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_profiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 48,
                            color: _brand.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada profil',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Buat pola jam kerja yang bisa diterapkan ke banyak pegawai.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._profiles.map(
                      (p) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            8,
                            8,
                          ),
                          title: Text(
                            p['name']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(_summary(p)),
                          onTap: () => _openEditor(profile: p),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _openEditor(profile: p);
                              if (v == 'delete') _delete(p);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class WorkScheduleProfileEditorPage extends StatefulWidget {
  const WorkScheduleProfileEditorPage({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  State<WorkScheduleProfileEditorPage> createState() =>
      _WorkScheduleProfileEditorPageState();
}

class _WorkScheduleProfileEditorPageState
    extends State<WorkScheduleProfileEditorPage> {
  late final TextEditingController _name;
  late List<WorkScheduleBlock> _blocks;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.profile != null;
  int? get _id => int.tryParse('${widget.profile?['id'] ?? ''}');
  String? get _overlapError => findScheduleOverlapError(_blocks);

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?['name']?.toString() ?? '');
    if (p == null) {
      _blocks = [];
    } else {
      final converted = profileToBlocks(p);
      _blocks = converted.isNotEmpty
          ? converted
          : dayMapToBlocks(p['blocks'] ?? p['schedule']);
    }
    _isActive = p == null
        ? true
        : (p['is_active'] == true || p['is_active'] == 1);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama profil wajib diisi');
      return;
    }
    if (_blocks.isEmpty) {
      setState(() => _error = 'Tambahkan minimal satu jam kerja');
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
      final blocks = _blocks.map((b) => b.toJson()).toList();
      if (_isEdit) {
        await api.updateWorkScheduleProfile(
          id: _id!,
          name: name,
          scheduleBlocks: blocks,
          isActive: _isActive,
        );
      } else {
        await api.createWorkScheduleProfile(
          name: name,
          scheduleBlocks: blocks,
          isActive: _isActive,
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
        setState(() => _error = 'Gagal menyimpan profil');
      }
    } catch (_) {
      setState(() => _error = 'Gagal menyimpan profil');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Profil' : 'Tambah Profil',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: 'Nama profil',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Profil aktif',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  value: _isActive,
                  activeThumbColor: _brand,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: WorkScheduleBlocksEditor(
              blocks: _blocks,
              showProfileTools: false,
              enabled: !_saving,
              overlapError: _overlapError,
              onChanged: (next) => setState(() => _blocks = next),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
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
                : const Text(
                    'Simpan Profil',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }
}
