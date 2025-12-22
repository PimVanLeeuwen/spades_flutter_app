import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesProvider);
    final last = games.isNotEmpty ? games.first : null;

    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Spades')),
        child: SafeArea(child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CupertinoButton.filled(
              child: const Text('Start New Game'),
              onPressed: () async {
                await _promptNewGame(context, ref);
              },
            ),
            const SizedBox(height: 12),
            if (last != null)
              CupertinoButton(
                  child: const Text('Continue Last Game'),
                  onPressed: () {
                    context.push('/play/${last.id}');
                  }
              ),
            const SizedBox(height: 12),
            CupertinoButton(
              child: const Text('View Past Games'),
              onPressed: () {
                context.push('/games');
              },
            )
          ],
        ))
    );
  }

  Future<void> _promptNewGame(BuildContext context, WidgetRef ref) async {
    final names = await showCupertinoDialog(context: context, builder: (_) => const _NamesDialog(),);
    if (names == null || names.length != 4) return;
    final id = await ref.read(gamesProvider.notifier).createGame(playerNames: names);

    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.push('/play/$id');
    });

  }
}

class _NamesDialog extends StatefulWidget {
  const _NamesDialog();
  @override
  State<_NamesDialog> createState() => _NamesDialogState();
}

class _NamesDialogState extends State<_NamesDialog> {
  final controllers = List.generate(4, (_) => TextEditingController());
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Players (N / E / S / W)'),
      content: Column(
        children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            placeholder: 'Player ${i+1}',
            controller: controllers[i],
          ),
        )),
      ),
      actions: [
        CupertinoDialogAction(isDestructiveAction: true, child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop()),
        CupertinoDialogAction(isDefaultAction: true, child: const Text('Create'),
            onPressed: () {
              final names = controllers.map((c) => c.text.trim()).toList();
              if (names.any((n) => n.isEmpty)) return;
              Navigator.of(context).pop(names);
            }),
      ],
    );
  }
}