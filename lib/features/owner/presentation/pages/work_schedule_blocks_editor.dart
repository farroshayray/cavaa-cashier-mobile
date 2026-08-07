import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'owner_home_page.dart';
import 'work_schedule_utils.dart';

const _brand = Color(0xFFAE1504);

class WorkScheduleBlocksEditor extends StatefulWidget {
  const WorkScheduleBlocksEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    this.profiles = const [],
    this.onProfilesChanged,
    this.onProfileApplied,
    this.showProfileTools = true,
    this.enabled = true,
    this.overlapError,
  });

  final List<WorkScheduleBlock> blocks;
  final ValueChanged<List<WorkScheduleBlock>> onChanged;
  final List<Map<String, dynamic>> profiles;
  final ValueChanged<List<Map<String, dynamic>>>? onProfilesChanged;
  final VoidCallback? onProfileApplied;
  final bool showProfileTools;
  final bool enabled;
  final String? overlapError;

  @override
  State<WorkScheduleBlocksEditor> createState() =>
      _WorkScheduleBlocksEditorState();
}

class _WorkScheduleBlocksEditorState extends State<WorkScheduleBlocksEditor> {
  Future<void> _pickTime(int index, {required bool isStart}) async {
    if (!widget.enabled) return;
    final block = widget.blocks[index];
    final current = isStart ? block.start : block.end;
    var initial = const TimeOfDay(hour: 9, minute: 0);
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(current)) {
      final parts = current.split(':');
      initial = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final next = [...widget.blocks];
    if (isStart) {
      next[index].start = formatted;
    } else {
      next[index].end = formatted;
    }
    widget.onChanged(next);
  }

  void _addBlock() {
    widget.onChanged([
      ...widget.blocks,
      WorkScheduleBlock(
        start: '09:00',
        end: '17:00',
        days: {
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
        },
      ),
    ]);
  }

  void _removeBlock(int index) {
    final next = [...widget.blocks]..removeAt(index);
    widget.onChanged(next);
  }

  void _toggleDay(int index, String day) {
    final next = [...widget.blocks];
    final days = {...next[index].days};
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    next[index].days = days;
    widget.onChanged(next);
  }

  Future<void> _applyProfile() async {
    if (widget.profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada profil jam kerja')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Terapkan profil',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            ...widget.profiles.map(
              (p) => ListTile(
                title: Text(p['name']?.toString() ?? '-'),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final blocks = profileToBlocks(selected);
    if (blocks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil ini belum memiliki jam kerja')),
      );
      return;
    }
    widget.onChanged(blocks);
    widget.onProfileApplied?.call();
  }

  Future<void> _saveAsProfile() async {
    final overlap = findScheduleOverlapError(widget.blocks);
    if (overlap != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(overlap)));
      return;
    }
    if (widget.blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu jam kerja')),
      );
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan sebagai profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama profil',
            hintText: 'Contoh: Shift Pagi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    try {
      await ownerApiOf(context).createWorkScheduleProfile(
        name: name,
        scheduleBlocks: widget.blocks.map((b) => b.toJson()).toList(),
      );
      if (!mounted) return;
      try {
        final data = await ownerApiOf(context).listWorkScheduleProfiles();
        final list = data['profiles'];
        if (list is List && widget.onProfilesChanged != null) {
          widget.onProfilesChanged!(
            list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
          );
        }
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil jam kerja disimpan')),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data is Map && data['message'] != null
                ? data['message'].toString()
                : 'Gagal menyimpan profil',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showProfileTools) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _applyProfile : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
              ),
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: const Text('Terapkan profil'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.blocks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Belum ada jam kerja. Tekan “+ Jam kerja”.',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ...List.generate(widget.blocks.length, (index) {
          final block = widget.blocks[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Jam kerja #${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          widget.enabled ? () => _removeBlock(index) : null,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: _brand,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.enabled
                            ? () => _pickTime(index, isStart: true)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(block.start),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–'),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.enabled
                            ? () => _pickTime(index, isStart: false)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(block.end),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Berlaku di hari',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: workScheduleDays.map((day) {
                    final selected = block.days.contains(day);
                    return FilterChip(
                      label: Text(
                        (workScheduleDayLabels[day] ?? day).substring(0, 3),
                      ),
                      selected: selected,
                      onSelected: widget.enabled
                          ? (_) => _toggleDay(index, day)
                          : null,
                      selectedColor: _brand.withValues(alpha: 0.12),
                      checkmarkColor: _brand,
                      side: BorderSide(
                        color: selected
                            ? _brand.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? _brand : const Color(0xFF334155),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        if (widget.overlapError != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.overlapError!,
            style: const TextStyle(color: _brand, fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        const Divider(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: widget.enabled ? _addBlock : null,
              style: FilledButton.styleFrom(
                foregroundColor: _brand,
                backgroundColor: _brand.withValues(alpha: 0.1),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Jam kerja'),
            ),
            if (widget.showProfileTools)
              FilledButton.icon(
                onPressed: widget.enabled ? _saveAsProfile : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Simpan sebagai profil'),
              ),
          ],
        ),
      ],
    );
  }
}
