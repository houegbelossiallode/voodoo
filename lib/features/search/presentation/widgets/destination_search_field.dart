import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vodou/features/search/presentation/providers/search_provider.dart';

/// Champ de recherche de destination avec suggestions
class DestinationSearchField extends ConsumerStatefulWidget {
  const DestinationSearchField({super.key});

  @override
  ConsumerState<DestinationSearchField> createState() =>
      _DestinationSearchFieldState();
}

class _DestinationSearchFieldState
    extends ConsumerState<DestinationSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(
      destinationSuggestionsProvider(_controller.text),
    );

    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Où souhaitez-vous aller ?',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref
                          .read(searchFiltersProvider.notifier)
                          .setDestination(null);
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() {
              _showSuggestions = value.isNotEmpty;
            });
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(searchFiltersProvider.notifier).setDestination(value);
              setState(() {
                _showSuggestions = false;
              });
            }
          },
        ),

        // Suggestions
        if (_showSuggestions)
          suggestionsAsync.when(
            data: (suggestions) {
              if (suggestions.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, size: 20),
                      title: Text(suggestion),
                      onTap: () {
                        _controller.text = suggestion;
                        ref
                            .read(searchFiltersProvider.notifier)
                            .setDestination(suggestion);
                        setState(() {
                          _showSuggestions = false;
                        });
                        _focusNode.unfocus();
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
