import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

/// Displays search results in a scrollable list
///
/// Shows empty state when no results found, otherwise displays
/// a list of [SearchResultItem] widgets.
class SearchResults extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final ValueChanged<SearchResult> onResultTap;

  const SearchResults({
    super.key,
    required this.results,
    required this.query,
    required this.onResultTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _EmptyState(query: query);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return SearchResultItem(
                result: result,
                onTap: () => onResultTap(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual search result item
class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: _buildLeading(colorScheme),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: _buildTrailingIcon(colorScheme),
      onTap: onTap,
    );
  }

  Widget _buildLeading(ColorScheme colorScheme) {
    // For artists, always show person icon
    if (result.type == SearchResultType.artist) {
      return _buildPlaceholder(Icons.person, colorScheme);
    }

    // For albums and tracks, show cover image or fallback icon
    final coverUrl = result.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      final icon = result.type == SearchResultType.album
          ? Icons.album
          : Icons.music_note;
      return _buildPlaceholder(icon, colorScheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: coverUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 48,
          height: 48,
          color: colorScheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(
          result.type == SearchResultType.album ? Icons.album : Icons.music_note,
          colorScheme,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget? _buildTrailingIcon(ColorScheme colorScheme) {
    return Icon(
      Icons.chevron_right,
      color: colorScheme.onSurfaceVariant,
    );
  }
}

/// Empty state shown when no results match the query
class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
