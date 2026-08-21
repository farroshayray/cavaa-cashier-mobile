import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/core/config/env.dart';
import '/core/utils/open_url.dart';

const _brand = Color(0xFFAE1504);

class _ResolvedCarouselImage {
  const _ResolvedCarouselImage.network(this.url)
      : bytes = null,
        isData = false;

  const _ResolvedCarouselImage.data(this.bytes)
      : url = null,
        isData = true;

  final String? url;
  final Uint8List? bytes;
  final bool isData;
}

/// Resolve mobile carousel image:
/// - prefer storage `image_path` rewritten to [Env.baseUrl]
/// - then `image_url` (http or data URI fallback)
_ResolvedCarouselImage? resolveCarouselImage(Map<String, dynamic> item) {
  final isDataFlag = item['image_is_data'] == true;
  final rawPath = item['image_path']?.toString().trim();
  final rawUrl = item['image_url']?.toString().trim();

  final candidates = <String>[
    if (rawPath != null && rawPath.isNotEmpty) rawPath,
    if (rawUrl != null && rawUrl.isNotEmpty) rawUrl,
  ];

  for (final value in candidates) {
    if (value.startsWith('data:image') ||
        (isDataFlag && value.contains('base64,'))) {
      final bytes = _decodeDataUri(value);
      if (bytes != null && bytes.isNotEmpty) {
        return _ResolvedCarouselImage.data(bytes);
      }
      continue;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri == null) continue;
      if (uri.path.contains('/storage/')) {
        final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
        final q = uri.hasQuery ? '?${uri.query}' : '';
        return _ResolvedCarouselImage.network('$base${uri.path}$q');
      }
      return _ResolvedCarouselImage.network(value);
    }

    final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
    final clean = value.replaceFirst(RegExp(r'^/+'), '');
    if (clean.startsWith('storage/')) {
      return _ResolvedCarouselImage.network('$base/$clean');
    }
    return _ResolvedCarouselImage.network('$base/storage/$clean');
  }

  return null;
}

Uint8List? _decodeDataUri(String raw) {
  try {
    const marker = 'base64,';
    final idx = raw.indexOf(marker);
    if (idx < 0) return null;
    final b64 =
        raw.substring(idx + marker.length).replaceAll(RegExp(r'\s'), '');
    return base64Decode(b64);
  } catch (_) {
    return null;
  }
}

class OwnerMobileCarousel extends StatefulWidget {
  const OwnerMobileCarousel({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  State<OwnerMobileCarousel> createState() => _OwnerMobileCarouselState();
}

class _OwnerMobileCarouselState extends State<OwnerMobileCarousel> {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _index = 0;
  bool _paused = false;

  List<({Map<String, dynamic> item, _ResolvedCarouselImage image})>
      get _items {
    final out =
        <({Map<String, dynamic> item, _ResolvedCarouselImage image})>[];
    for (final p in widget.items) {
      final image = resolveCarouselImage(p);
      if (image == null) continue;
      out.add((item: p, image: image));
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAuto();
  }

  @override
  void didUpdateWidget(covariant OwnerMobileCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _index = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAuto();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    if (_items.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _paused || !_pageController.hasClients) return;
      final next = (_index + 1) % _items.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseBriefly() {
    _paused = true;
    _autoTimer?.cancel();
    Future.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      _paused = false;
      _startAuto();
    });
  }

  Future<void> _openCta(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    if (url.startsWith('data:')) return;
    try {
      await openExternalUrl(url.trim());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka tautan')),
      );
    }
  }

  Widget _buildImage(_ResolvedCarouselImage image) {
    if (image.isData && image.bytes != null) {
      return Image.memory(
        image.bytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _errorBox(),
      );
    }

    final url = image.url ?? '';
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _brand,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _errorBox(),
    );
  }

  Widget _errorBox() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.black.withValues(alpha: 0.35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final height = width < 360 ? 148.0 : (width < 600 ? 168.0 : 200.0);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _pauseBriefly();
            },
            itemBuilder: (context, i) {
              final entry = items[i];
              final cta = entry.item['cta_url']?.toString();
              final hasCta = cta != null &&
                  cta.trim().isNotEmpty &&
                  !cta.startsWith('data:');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasCta
                        ? () => _openCta(cta)
                        : () => _pauseBriefly(),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildImage(entry.image),
                            if (hasCta)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _brand.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? _brand : _brand.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
