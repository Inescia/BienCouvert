import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../home/presentation/providers.dart';
import '../../domain/horse_location.dart';
import '../../../weather/domain/geo_place.dart';

class LocationSearchField extends ConsumerStatefulWidget {
  const LocationSearchField({super.key, this.initial, required this.onChanged});

  final HorseLocation? initial;
  final ValueChanged<HorseLocation?> onChanged;

  @override
  ConsumerState<LocationSearchField> createState() =>
      _LocationSearchFieldState();
}

class _LocationSearchFieldState extends ConsumerState<LocationSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<GeoPlace> _suggestions = const [];
  bool _loading = false;
  HorseLocation? _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial?.hasCoordinates == true ? widget.initial : null;
    _controller = TextEditingController(text: _selected?.displayName ?? '');
  }

  @override
  void didUpdateWidget(covariant LocationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initial;
    if (next != null &&
        next.hasCoordinates &&
        next.weatherCacheKey != oldWidget.initial?.weatherCacheKey &&
        _selected?.weatherCacheKey != next.weatherCacheKey) {
      _selected = next;
      _controller.text = next.displayName;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_selected != null && value != _selected!.displayName) {
      _selected = null;
      widget.onChanged(null);
    }
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value);
    });
  }

  Future<void> _search(String value) async {
    try {
      final results = await ref.read(geocodingProvider).search(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
        _error = results.isEmpty ? 'Aucun lieu trouvé' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _loading = false;
        _error = 'Recherche impossible, réessaie';
      });
    }
  }

  void _select(GeoPlace place) {
    final location = place.toLocation(id: widget.initial?.id);
    _controller.text = location.displayName;
    setState(() {
      _selected = location;
      _suggestions = const [];
      _error = null;
      _loading = false;
    });
    widget.onChanged(location);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          onChanged: _onTextChanged,
          textInputAction: TextInputAction.search,
          scrollPadding: const EdgeInsets.only(bottom: 160),
          decoration: InputDecoration(
            labelText: 'Ville ou commune du cheval',
            hintText: 'Ex. Mont-de-Marsan, Pau…',
            prefixIcon: const Icon(Icons.place_outlined),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _selected != null
                ? const Icon(Icons.check_circle_outline, color: AppColors.pine)
                : null,
          ),
        ),
        if (_error != null && _suggestions.isEmpty && !_loading) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.softError),
          ),
        ],
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          AppSurface(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(_suggestions[i].name),
                    subtitle: Text(_suggestions[i].displayLabel),
                    onTap: () => _select(_suggestions[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
