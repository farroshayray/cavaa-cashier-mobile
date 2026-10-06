import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _brand = Color(0xFFAE1504);

/// In-app crop screen with SafeArea AppBar (avoids status-bar overlap from UCrop).
class StoreImageCropPage extends StatefulWidget {
  const StoreImageCropPage({
    super.key,
    required this.sourcePath,
    required this.title,
    required this.aspectRatio,
    required this.outputWidth,
    required this.outputHeight,
  });

  final String sourcePath;
  final String title;
  final double aspectRatio;
  final int outputWidth;
  final int outputHeight;

  @override
  State<StoreImageCropPage> createState() => _StoreImageCropPageState();
}

class _StoreImageCropPageState extends State<StoreImageCropPage> {
  final _controller = CropController();
  Uint8List? _bytes;
  bool _loading = true;
  bool _cropping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.sourcePath).readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat gambar';
      });
    }
  }

  Future<void> _confirm() async {
    if (_cropping || _bytes == null) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  Future<void> _onCropped(CropResult result) async {
    try {
      switch (result) {
        case CropSuccess(:final croppedImage):
          final outPath = await _encodeOutput(croppedImage);
          if (!mounted) return;
          Navigator.of(context).pop(outPath);
        case CropFailure(:final cause):
          if (!mounted) return;
          setState(() {
            _cropping = false;
            _error = 'Gagal crop: $cause';
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cropping = false;
        _error = 'Gagal menyimpan hasil crop';
      });
    }
  }

  Future<String> _encodeOutput(Uint8List croppedBytes) async {
    final decoded = img.decodeImage(croppedBytes);
    if (decoded == null) {
      throw StateError('decode failed');
    }

    final resized = img.copyResize(
      decoded,
      width: widget.outputWidth,
      height: widget.outputHeight,
      interpolation: img.Interpolation.cubic,
    );

    final jpg = img.encodeJpg(resized, quality: 92);
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'store_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(jpg, flush: true);
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: _brand,
              elevation: 2,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _cropping
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      tooltip: 'Batal',
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: (_cropping || _bytes == null) ? null : _confirm,
                      icon: _cropping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      color: Colors.white,
                      tooltip: 'Simpan',
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                color: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _brand),
                    )
                  : _bytes == null
                      ? const Center(
                          child: Text(
                            'Gambar tidak tersedia',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : Crop(
                          image: _bytes!,
                          controller: _controller,
                          aspectRatio: widget.aspectRatio,
                          initialRectBuilder:
                              InitialRectBuilder.withSizeAndRatio(
                            size: 0.9,
                            aspectRatio: widget.aspectRatio,
                          ),
                          baseColor: const Color(0xFF0F0F10),
                          maskColor: Colors.black.withValues(alpha: 0.65),
                          cornerDotBuilder: (size, _) => Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: _brand,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          interactive: true,
                          fixCropRect: false,
                          onCropped: _onCropped,
                        ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                color: const Color(0xFF1A1A1C),
                child: Text(
                  'Geser & pinch untuk menyesuaikan. Rasio terkunci.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
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
