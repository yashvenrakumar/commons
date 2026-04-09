import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import 'movie_list_controller.dart';
import 'movie_detail_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    required this.userLocalId,
    required this.userName,
  });

  final String userLocalId;
  final String userName;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final ScrollController _scroll;
  final _search = TextEditingController();
  late final MovieListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MovieListController(repo: sl(), userLocalId: widget.userLocalId)
      ..refresh();
    _scroll = ScrollController()
      ..addListener(() {
        if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
          _controller.loadNextPage();
        }
      });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Builder(
        builder: (context) {
          final c = context.watch<MovieListController>();
          _search.value = _search.value.copyWith(text: c.query);
          return Scaffold(
            appBar: AppBar(
              title: Text('Movies • ${widget.userName}'),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (v) => c.setQuery(v),
                          decoration: const InputDecoration(
                            hintText: 'Search movies (OMDb)',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => c.setQuery(_search.text),
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Search',
                      ),
                    ],
                  ),
                ),
                if (c.reconnecting)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _ReconnectingInline(),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: c.refresh,
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: c.items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == c.items.length) {
                          if (c.loading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            );
                          }
                          if (c.error != null) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Text(
                                c.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            );
                          }
                          return const SizedBox(height: 24);
                        }

                        final m = c.items[i];
                        final bookmarked = c.isBookmarked(m.imdbId);
                        return ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(
                                userLocalId: widget.userLocalId,
                                imdbId: m.imdbId,
                                titleHint: m.title,
                                yearHint: m.year,
                                posterHint: m.poster,
                              ),
                            ),
                          ),
                          leading: _Poster(posterUrl: m.poster),
                          title: Text(m.title),
                          subtitle: Text(m.year),
                          trailing: IconButton(
                            onPressed: () => c.toggleBookmark(m),
                            icon: Icon(
                              bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                            ),
                            tooltip: bookmarked ? 'Unbookmark' : 'Bookmark',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.posterUrl});
  final String? posterUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 64,
        color: cs.secondary.withValues(alpha: 0.10),
        child: posterUrl == null
            ? const Icon(Icons.local_movies_outlined)
            : CachedNetworkImage(
                imageUrl: posterUrl!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class _ReconnectingInline extends StatelessWidget {
  const _ReconnectingInline();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.secondary),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Reconnecting…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

