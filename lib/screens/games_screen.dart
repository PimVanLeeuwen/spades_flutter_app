import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../state.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: const Text('Games'), leading: CupertinoNavigationBarBackButton(onPressed: () => context.go('/'))),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) => _GameTile(game: games[i]),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemCount: games.length,
        ),
      ),
    );
  }
}

class _GameTile extends ConsumerWidget {
  final Game game;

  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoListTile(
      title: Text('${game.teams[0].name} vs ${game.teams[1].name}'),
      subtitle: Text(
        'Hands: ${game.hands.length} • Updated: ${game.updatedAt.toLocal()}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Text('Open'),
            onPressed: () {
              context.push('/play/${game.id}');
            },
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Text('Delete'),
            onPressed: () {
              ref.read(gamesProvider.notifier).delete(game.id);
            },
          ),
        ],
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  const CupertinoListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: CupertinoTheme.of(context).textTheme.textStyle,
                  child: title,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsetsGeometry.only(top: 4),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                      child: subtitle!,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
