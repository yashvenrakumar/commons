import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
    _search.text = _controller.query;
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
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: Text('Movies • ${widget.userName}'),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoSearchTextField(
                                controller: _search,
                                onSubmitted: (v) => c.setQuery(v),
                                placeholder: 'Search movies',
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              onPressed: () => c.setQuery(_search.text),
                              child: const Icon(CupertinoIcons.arrow_right_circle),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                      itemBuilder: (context, i) {
                        if (i == c.items.length) {
                          if (c.loading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator.adaptive()),
                            );
                          }
                          if (c.error != null) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              child: Text(
                                c.error!,
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            );
                          }
                          return const SizedBox(height: 24);
                        }

                        final m = c.items[i];
                        final isBookmarked = c.isBookmarked(m.imdbId);
                        final tile = ListTile(
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
                              isBookmarked
                                  ? CupertinoIcons.bookmark_fill
                                  : CupertinoIcons.bookmark,
                            ),
                            tooltip: isBookmarked ? 'Unbookmark' : 'Bookmark',
                          ),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: tile,
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

