import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controller/location_provider.dart';
import '../model/geo_location.dart';
import '../repository/open_meteo_repository.dart';

/// 城市搜索页——输入关键字 → Open-Meteo geocoding → 选中后写入
/// [selectedLocationProvider] 并返回。后续路由 redirect 自行处理：
/// 从 onboarding 进来的会被引到 `/weather`，从 settings 进来的留在 settings。
class CitySearchPage extends ConsumerStatefulWidget {
  const CitySearchPage({super.key});

  @override
  ConsumerState<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends ConsumerState<CitySearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  // 自增 token——任何新查询都会让在飞的旧请求结果被丢弃，避免乱序覆盖。
  int _queryToken = 0;
  AsyncValue<List<GeoLocation>>? _result;

  @override
  void initState() {
    super.initState();
    // 进页面就把焦点给到搜索框，省一次点击。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() => _result = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final token = ++_queryToken;
    setState(() => _result = const AsyncValue.loading());
    try {
      final list =
          await ref.read(weatherRepositoryProvider).searchCity(q, count: 12);
      if (!mounted || token != _queryToken) return;
      setState(() => _result = AsyncValue.data(list));
    } catch (e, st) {
      if (!mounted || token != _queryToken) return;
      setState(() => _result = AsyncValue.error(e, st));
    }
  }

  void _select(GeoLocation loc) {
    ref.read(selectedLocationProvider.notifier).set(loc);
    if (context.canPop()) {
      context.pop();
    } else {
      // 兜底——理论上从 onboarding 或 settings 都能 pop，这里只是保险。
      context.go('/weather');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          '切换城市',
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.onSurface,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/weather'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '输入城市名（中文 / 英文）',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        ),
                ),
                onChanged: _onChanged,
                onSubmitted: (q) {
                  final t = q.trim();
                  if (t.isNotEmpty) _search(t);
                },
              ),
            ),
            Expanded(child: _Results(result: _result, onTap: _select)),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.onTap});

  final AsyncValue<List<GeoLocation>>? result;
  final ValueChanged<GeoLocation> onTap;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const _Hint(text: '试试搜索 "上海"、"Tokyo"、"Paris"…');
    }
    return result!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Hint(text: friendlyErrorMessage(e)),
      data: (cities) {
        if (cities.isEmpty) {
          return const _Hint(text: '没有找到匹配的城市');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          itemCount: cities.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _CityTile(loc: cities[i], onTap: onTap),
        );
      },
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.loc, required this.onTap});

  final GeoLocation loc;
  final ValueChanged<GeoLocation> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap(loc),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primaryContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.name,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_subtitle(loc).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(loc),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(GeoLocation loc) {
    final parts = <String>[
      if (loc.admin1 != null && loc.admin1!.isNotEmpty && loc.admin1 != loc.name) loc.admin1!,
      if (loc.country != null && loc.country!.isNotEmpty) loc.country!,
    ];
    return parts.join(' · ');
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
