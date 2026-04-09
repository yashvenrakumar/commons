import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/db/app_database.dart';
import '../../app/app_controller.dart';
import '../../movies/presentation/movie_list_screen.dart';
import '../data/reqres_api.dart';
import '../data/user_repository.dart';
import 'users_controller.dart';
import 'add_user_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()
      ..addListener(() {
        final c = context.read<UsersController>();
        if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
          c.loadNextPage();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UsersController>().refresh();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<UsersController>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Theme',
            onSelected: (v) {
              final app = context.read<AppController>();
              app.setThemeMode(
                switch (v) {
                  'light' => ThemeMode.light,
                  'dark' => ThemeMode.dark,
                  _ => ThemeMode.system,
                },
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'system', child: Text('System theme')),
              PopupMenuItem(value: 'light', child: Text('Light')),
              PopupMenuItem(value: 'dark', child: Text('Dark')),
            ],
            icon: const Icon(Icons.color_lens_outlined),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddUserScreen()),
            ),
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add user',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.20),
                    cs.secondary.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/branding/platformcommons_logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium User Hub',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Offline-first users + bookmarks sync',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _SectionHeader(title: 'Local users'),
            StreamBuilder<List<AppUser>>(
              stream: c.localUsersStream,
              builder: (context, snapshot) {
                final users = snapshot.data ?? const [];
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text('No local users yet. Tap + to create one (works offline).'),
                  );
                }
                return Column(
                  children: [
                    for (final u in users)
                      _LocalUserTile(
                        user: u,
                        onTap: () => _openMovies(context, u.localId, u.name),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const _SectionHeader(title: 'Remote users (reqres.in)'),
            if (c.reconnecting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: _ReconnectingPill(),
              ),
            for (final u in c.remoteUsers)
              _RemoteUserTile(
                user: u,
                onTap: () async {
                  final repo = sl<UserRepository>();
                  final localId = await repo.ensureLocalUserForRemote(u);
                  if (!context.mounted) return;
                  _openMovies(context, localId, u.fullName);
                },
              ),
            if (c.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (c.hasMore)
              const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddUserScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openMovies(BuildContext context, String userLocalId, String userName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieListScreen(userLocalId: userLocalId, userName: userName),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LocalUserTile extends StatelessWidget {
  const _LocalUserTile({required this.user, required this.onTap});
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (user.syncStatus) {
      SyncStatus.synced => 'Synced',
      SyncStatus.pending => 'Pending sync',
      SyncStatus.failed => 'Sync failed (will retry)',
    };
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.14),
          child: Text(user.name.isEmpty ? '?' : user.name.trim()[0].toUpperCase()),
        ),
        title: Text(user.name),
        subtitle: Text(subtitle),
        trailing: const Icon(CupertinoIcons.chevron_right),
      ),
    );
  }
}

class _RemoteUserTile extends StatelessWidget {
  const _RemoteUserTile({required this.user, required this.onTap});
  final ReqresUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = user.recordId.isEmpty ? user.lastName : 'ID: ${user.recordId}';
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(user.avatar),
        ),
        title: Text(user.fullName),
        subtitle: Text(subtitle),
        trailing: const Icon(CupertinoIcons.chevron_right),
      ),
    );
  }
}

class _ReconnectingPill extends StatelessWidget {
  const _ReconnectingPill();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                style: TextStyle(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

