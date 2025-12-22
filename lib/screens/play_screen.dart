import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models.dart';
import '../scoring.dart';
import '../state.dart';
import '../widget/numeric_stepper.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String gameId;

  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  late Game _game;
  final Map<String, int> _bagsCarry = {};

  @override
  void initState() {
    super.initState();
    final g = ref.read(gamesProvider.notifier).byId(widget.gameId);
    if (g == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pop(),
      );
    } else {
      _game = g;
      for (final t in _game.teams) {
        _bagsCarry[t.id] = 0;
      }
      _recomputeCarryOver();
    }
  }

  void _recomputeCarryOver() {
    _bagsCarry.updateAll((key, value) => 0);
    for (final hand in _game.hands) {
      for (final team in _game.teams) {
        final input = hand.teamInputs.firstWhere((ti) => ti.teamId == team.id);
        final breakdown = computeTeamScore(
          config: _game.config,
          currentBagsRemainder: _bagsCarry[team.id]!,
          teamBid: input.teamBid.reduce((a, b) => a + b),
          teamBooksWon: input.teamBooksWon,
          playerBids: input.teamBid,
          nilAchieved: input.nilAchieved,
        );
        _bagsCarry[team.id] =
            (_bagsCarry[team.id]! + breakdown.bags) -
            (breakdown.penaltyBlocks * 10);
      }
    }
    setState(() {});
  }

  _CumTotals _cumulativeTotalsUpTo(int handIndex, String teamId) {
    int total = 0;
    int bags = 0;
    int carry = 0;

    for (final hand in _game.hands.where((h) => h.index <= handIndex)) {
      final input = hand.teamInputs.firstWhere((ti) => ti.teamId == teamId);

      final breakdown = computeTeamScore(
        config: _game.config,
        currentBagsRemainder: carry,
        teamBid: input.teamBid.reduce((a, b) => a + b),
        teamBooksWon: input.teamBooksWon,
        playerBids: input.teamBid,
        nilAchieved: input.nilAchieved,
      );

      total += breakdown.total;
      bags += breakdown.bags;
      carry = (carry + breakdown.bags) - (breakdown.penaltyBlocks * 10);
    }
    return _CumTotals(total: total, bags: bags);
  }

  @override
  Widget build(BuildContext context) {
    final players = _game.players;
    final teams = _game.teams;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${teams[0].name} vs ${teams[1].name}'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () async {
            _game = _game.copyWith(updatedAt: DateTime.now());
            await ref.read(repoProvider).upsertGame(_game);
            if (!mounted) return;
            context.pop();
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Save'),
          onPressed: () async {
            _game = _game.copyWith(updatedAt: DateTime.now());
            await ref.read(repoProvider).upsertGame(_game);
            ref.read(gamesProvider.notifier).refresh();
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SizedBox(height: 12),
            ..._game.hands.map(
              (h) => _HandRow(
                hand: h,
                teams: teams,
                players: players,
                onChanged: (updated) async {
                  final idx = _game.hands.indexWhere((x) => x.index == h.index);
                  final newHands = [..._game.hands];
                  newHands[idx] = updated;
                  _game = _game.copyWith(
                    hands: newHands,
                    updatedAt: DateTime.now(),
                  );
                  setState(_recomputeCarryOver);

                  await ref.read(repoProvider).upsertGame(_game);
                  ref.read(gamesProvider.notifier).refresh();
                },
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              child: const Text('Add Hand'),
              onPressed: () {
                final nextIndex = _game.hands.length + 1;
                final newHand = Hand(
                  index: nextIndex,
                  teamInputs: [
                    TeamHandInput(
                      teamId: teams[0].id,
                      teamBid: [0, 0],
                      teamBooksWon: 0,
                      nilAchieved: const [false, false],
                    ),
                    TeamHandInput(
                      teamId: teams[1].id,
                      teamBid: [0, 0],
                      teamBooksWon: 0,
                      nilAchieved: const [false, false],
                    ),
                  ],
                );
                _game = _game.copyWith(
                  hands: [..._game.hands, newHand],
                  updatedAt: DateTime.now(),
                );
                setState(_recomputeCarryOver);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CumTotals {
  final int total;
  final int bags;

  const _CumTotals({required this.total, required this.bags});
}

class _HandRow extends StatefulWidget {
  final Hand hand;
  final List<Team> teams;
  final List<Player> players; // N,E,S,W
  final ValueChanged<Hand> onChanged;

  const _HandRow({
    required this.hand,
    required this.teams,
    required this.players,
    required this.onChanged,
  });

  @override
  State<_HandRow> createState() => _HandRowState();
}

class _HandRowState extends State<_HandRow> {
  late List<List<int>> bidsPerTeam;
  late List<int> handsWonPerTeam;
  late List<List<bool>> nilsPerTeam;

  @override
  void initState() {
    super.initState();
    final inputs = widget.hand.teamInputs;
    bidsPerTeam = List.generate(2, (i) => List<int>.from(inputs[i].teamBid));
    handsWonPerTeam = List.generate(2, (i) => inputs[i].teamBooksWon);
    nilsPerTeam = List.generate(
      2,
      (i) => List<bool>.from(inputs[i].nilAchieved),
    );
  }

  void _emit() {
    final inputs = List.generate(
      2,
      (teamIdx) => TeamHandInput(
        teamId: widget.teams[teamIdx].id,
        teamBid: bidsPerTeam[teamIdx],
        teamBooksWon: handsWonPerTeam[teamIdx],
        nilAchieved: nilsPerTeam[teamIdx],
      ),
    );
    widget.onChanged(Hand(index: widget.hand.index, teamInputs: inputs));
  }

  String formatTotalsAndBags(_CumTotals a, _CumTotals b) {
    String plusBags(int n) => "+ ${n.abs()}";
    return "${a.total - a.bags} ${plusBags(a.bags % 10)} / ${b.total - b.bags} ${plusBags(b.bags % 10)}";
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_PlayScreenState>()!;
    final teamA = widget.teams[0].id;
    final teamB = widget.teams[1].id;

    final cumA = parent._cumulativeTotalsUpTo(widget.hand.index, teamA);
    final cumB = parent._cumulativeTotalsUpTo(widget.hand.index, teamB);

    final handLine = formatTotalsAndBags(cumA, cumB);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(blurRadius: 2, color: CupertinoColors.systemGrey),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hand ${widget.hand.index}',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(height: 8),
          _teamPanel(),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 120, child: Text('Score')),
              Align(
                alignment: Alignment.center,
                child: Text(
                  handsWonPerTeam[0] + handsWonPerTeam[1] == 13 ? handLine : "",
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),

        ],
      ),
    );
  }

  Widget _teamPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 120),
              Expanded(
                child: Text(
                  widget.teams[0].name.split('/')[0].substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.teams[0].name.split('/')[1].substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.teams[1].name.split('/')[0].substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.teams[1].name.split('/')[1].substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // --- Per-person bids row ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 120, child: Text('Bids')),
              Expanded(
                child: NumericStepper(
                  value: bidsPerTeam[0][0],
                  min: 0,
                  max: 13,
                  direction: Axis.vertical,
                  onDecrement: () {
                    setState(() {
                      bidsPerTeam[0][0] = (bidsPerTeam[0][0] - 1).clamp(0, 13);
                      // If bid > 0, nil cannot be achieved; auto-clear for UX
                      if (bidsPerTeam[0][0] > 0) nilsPerTeam[0][0] = false;
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      bidsPerTeam[0][0] = (bidsPerTeam[0][0] + 1).clamp(0, 13);
                      if (bidsPerTeam[0][0] > 0) nilsPerTeam[0][0] = false;
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumericStepper(
                  value: bidsPerTeam[0][1],
                  min: 0,
                  max: 13,
                  direction: Axis.vertical,
                  onDecrement: () {
                    setState(() {
                      bidsPerTeam[0][1] = (bidsPerTeam[0][1] - 1).clamp(0, 13);
                      // If bid > 0, nil cannot be achieved; auto-clear for UX
                      if (bidsPerTeam[0][1] > 0) nilsPerTeam[0][1] = false;
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      bidsPerTeam[0][1] = (bidsPerTeam[0][1] + 1).clamp(0, 13);
                      if (bidsPerTeam[0][1] > 0) nilsPerTeam[0][1] = false;
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumericStepper(
                  value: bidsPerTeam[1][0],
                  min: 0,
                  max: 13,
                  direction: Axis.vertical,
                  onDecrement: () {
                    setState(() {
                      bidsPerTeam[1][0] = (bidsPerTeam[1][0] - 1).clamp(0, 13);
                      // If bid > 0, nil cannot be achieved; auto-clear for UX
                      if (bidsPerTeam[1][0] > 0) nilsPerTeam[1][0] = false;
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      bidsPerTeam[1][0] = (bidsPerTeam[1][0] + 1).clamp(0, 13);
                      if (bidsPerTeam[1][0] > 0) nilsPerTeam[1][0] = false;
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NumericStepper(
                  value: bidsPerTeam[1][1],
                  min: 0,
                  max: 13,
                  direction: Axis.vertical,
                  onDecrement: () {
                    setState(() {
                      bidsPerTeam[1][1] = (bidsPerTeam[1][1] - 1).clamp(0, 13);
                      // If bid > 0, nil cannot be achieved; auto-clear for UX
                      if (bidsPerTeam[1][1] > 0) nilsPerTeam[1][1] = false;
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      bidsPerTeam[1][1] = (bidsPerTeam[1][1] + 1).clamp(0, 13);
                      if (bidsPerTeam[1][1] > 0) nilsPerTeam[1][1] = false;
                    });
                    _emit();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              SizedBox(width: 120, child: Text('Nil')),
              _nilPicker(0, 0),
              const SizedBox(width: 12),
              _nilPicker(0, 1),
              const SizedBox(width: 12),
              _nilPicker(1, 0),
              const SizedBox(width: 12),
              _nilPicker(1, 1),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const SizedBox(width: 120, child: Text('Hands Won')),
              Expanded(
                // width: 70,
                child: NumericStepper(
                  value: handsWonPerTeam[0],
                  min: 0,
                  max: 13,
                  onDecrement: () {
                    setState(() {
                      handsWonPerTeam[0] = (handsWonPerTeam[0] - 1).clamp(
                        0,
                        13,
                      );
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      handsWonPerTeam[0] = (handsWonPerTeam[0] + 1).clamp(
                        0,
                        13,
                      );
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // width: 70,
                child: NumericStepper(
                  value: handsWonPerTeam[1],
                  min: 0,
                  max: 13,
                  onDecrement: () {
                    setState(() {
                      handsWonPerTeam[1] = (handsWonPerTeam[1] - 1).clamp(
                        0,
                        13,
                      );
                    });
                    _emit();
                  },
                  onIncrement: () {
                    setState(() {
                      handsWonPerTeam[1] = (handsWonPerTeam[1] + 1).clamp(
                        0,
                        13,
                      );
                    });
                    _emit();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nilPicker(int teamIdx, int playerIdx) {
    final isNil = nilsPerTeam[teamIdx][playerIdx];
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() {
            nilsPerTeam[teamIdx][playerIdx] = !isNil;
          });
          _emit();
        },
        child: Icon(
          isNil
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.circle,
          color: isNil
              ? CupertinoColors.activeGreen
              : CupertinoColors.inactiveGray,
        ),
      ),
    );
  }
}
