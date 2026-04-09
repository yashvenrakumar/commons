import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/widgets/app_feedback.dart';
import 'movie_detail_controller.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({
    super.key,
    required this.userLocalId,
    required this.imdbId,
    this.titleHint,
    this.yearHint,
    this.posterHint,
  });

  final String userLocalId;
  final String imdbId;
  final String? titleHint;
  final String? yearHint;
  final String? posterHint;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MovieDetailController(repo: sl(), userLocalId: userLocalId, imdbId: imdbId)
        ..load(),
      child: Builder(
        builder: (context) {
          final c = context.watch<MovieDetailController>();
          final detail = c.detail;
          final title = detail?.title ?? titleHint ?? imdbId;
          final year = detail?.year ?? yearHint;
          final poster = detail?.poster ?? posterHint;
          final cs = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  onPressed: () async {
                    final added = await c.toggleBookmark(
                      title: title,
                      posterUrl: poster,
                      year: year,
                    );
                    if (!context.mounted) return;
                    AppFeedback.showToast(
                      context,
                      tone: added ? FeedbackTone.success : FeedbackTone.info,
                      message: added
                          ? 'Bookmarked for this user'
                          : 'Bookmark removed',
                    );
                  },
                  icon: Icon(
                    c.bookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                  ),
                  tooltip: c.bookmarked ? 'Unbookmark' : 'Bookmark',
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                children: [
                  if (c.reconnecting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _ReconnectingInline(),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.26)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroPoster(url: poster),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (year != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  year,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (c.loading && detail == null)
                                const Center(child: CircularProgressIndicator.adaptive())
                              else if (c.error != null)
                                Text(
                                  c.error!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                )
                              else if (detail != null) ...[
                                Text(
                                  detail.plot,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Released: ${detail.released}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          color: cs.secondary.withValues(alpha: 0.10),
          child: url == null
              ? const Center(child: Icon(Icons.local_movies_outlined, size: 48))
              : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
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

