/// ============================================================================
/// play_screen.dart - Active Game Scoring Interface
/// ============================================================================
///
/// This is the main screen where users score hands during a Spades game.
/// It's the most complex screen in the app, demonstrating:
///
/// - ConsumerStatefulWidget for stateful Riverpod integration
/// - Complex UI composition with multiple nested widgets
/// - Real-time score calculation and display
/// - State management for form inputs
/// - Win condition detection
///
/// UI STRUCTURE:
/// ┌──────────────────────────────────────┐
/// │ Navigation Bar (teams + save button) │
/// ├──────────────────────────────────────┤
/// │ Hand 1 Card                          │
/// │ ┌──────────────────────────────────┐ │
/// │ │ Player names header              │ │
/// │ │ Bids row (per player)            │ │
/// │ │ Nil toggles row                  │ │
/// │ │ Hands won row (per team)         │ │
/// │ │ Score display (when complete)    │ │
/// │ └──────────────────────────────────┘ │
/// │ Hand 2 Card...                       │
/// │ ...                                  │
/// │ [Add Hand Button]                    │
/// └──────────────────────────────────────┘
/// ============================================================================

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spades/widget/readonly_field.dart';

import '../colors.dart';
import '../models.dart';
import '../scoring.dart';
import '../state.dart';
import '../widget/numeric_stepper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PLAY SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// The main game scoring screen.
///
/// RIVERPOD CONCEPT: ConsumerStatefulWidget
/// Combines StatefulWidget with Riverpod access. Use when you need:
/// - Local state (like _bagsCarry map)
/// - Lifecycle methods (initState, dispose)
/// - And also need to access providers
///
/// The State class becomes ConsumerState<T>, which provides `ref`.
class PlayScreen extends ConsumerStatefulWidget {
  /// The ID of the game to display/score.
  final String gameId;

  const PlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

/// State for PlayScreen managing the active game scoring.
///
/// FLUTTER CONCEPT: State Lifecycle
/// StatefulWidget has a lifecycle:
/// 1. createState() - Creates the State object
/// 2. initState() - Called once when State is inserted into tree
/// 3. build() - Called whenever the widget needs to render
/// 4. setState() - Marks the widget as dirty, triggers rebuild
/// 5. dispose() - Called when State is removed from tree
class _PlayScreenState extends ConsumerState<PlayScreen> {
  /// The current game being scored.
  ///
  /// DART CONCEPT: Late Variables
  /// `late` means the variable will be initialized before use, but not
  /// at declaration time. Useful when:
  /// - You can't initialize in the declaration (needs async or context)
  /// - You're certain it will be set before access
  late Game _game;

  /// Tracks accumulated bags (mod 10) for each team.
  ///
  /// Key: Team ID
  /// Value: Current bag remainder (0-9)
  ///
  /// This is recalculated from scratch whenever hands change to ensure
  /// accuracy. Bags that triggered penalties are subtracted out.
  final Map<String, int> _bagsCarry = {};

  /// Confetti controller for the winning celebration animation.
  late ConfettiController _confettiController;

  /// Tracks which team has won (if any) to trigger confetti only once per win.
  _Winner _currentWinner = _Winner.none;

  /// Tracks if we've already shown confetti for the current winner.
  bool _hasShownConfetti = false;

  @override
  void initState() {
    super.initState();

    // Initialize confetti controller with 3 second duration
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Load the game from state
    // RIVERPOD: ref.read() in initState
    // We use read() here because we just want the current value,
    // not a subscription. initState can't use watch() anyway.
    final game = ref.read(gamesProvider.notifier).byId(widget.gameId);

    // Handle case where game doesn't exist (was deleted)
    if (game == null) {
      // Schedule navigation away after this frame completes
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pop(),
      );
      return;
    }

    _game = game;

    // Initialize bag tracking for each team
    for (final team in _game.teams) {
      _bagsCarry[team.id] = 0;
    }

    // Calculate current bag state from all existing hands
    _recomputeCarryOver();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Recalculates bag carry-over for all teams from scratch.
  ///
  /// ALGORITHM:
  /// For each COMPLETE hand in order (where total tricks = 13):
  ///   For each team:
  ///     1. Calculate score breakdown for that hand
  ///     2. Add bags earned to carry
  ///     3. Subtract bags consumed by penalties (penaltyBlocks * 10)
  ///
  /// This ensures bag state is always consistent with the recorded hands.
  /// Incomplete hands are ignored until all 13 tricks are recorded.
  void _recomputeCarryOver() {
    // Reset all carry values to zero
    _bagsCarry.updateAll((key, value) => 0);

    // Process each hand in order
    for (final hand in _game.hands) {
      // Check if this hand is complete (all 13 tricks accounted for)
      final totalTricksWon = hand.teamInputs
          .map((ti) => ti.teamBooksWon)
          .reduce((a, b) => a + b);

      // Skip incomplete hands
      if (totalTricksWon != 13) continue;

      for (final team in _game.teams) {
        // Find this team's input for this hand
        final input = hand.teamInputs.firstWhere((ti) => ti.teamId == team.id);

        // Calculate score breakdown
        final breakdown = computeTeamScore(
          config: _game.config,
          currentBagsRemainder: _bagsCarry[team.id]!,
          teamBid: input.teamBid.reduce((a, b) => a + b),
          teamBooksWon: input.teamBooksWon,
          playerBids: input.teamBid,
          nilAchieved: input.nilAchieved,
        );

        // Update carry: add new bags, subtract penalized bags
        _bagsCarry[team.id] =
            (_bagsCarry[team.id]! + breakdown.bags) -
            (breakdown.penaltyBlocks * 10);
      }
    }

    // Trigger rebuild to reflect updated state
    setState(() {});
  }

  /// Calculates cumulative totals up to and including a specific hand.
  ///
  /// Used to display running scores and detect win conditions.
  ///
  /// IMPORTANT: Only complete hands (where total tricks won = 13) are
  /// included in the score calculation. Incomplete hands are ignored.
  ///
  /// DART CONCEPT: Private Methods
  /// Methods starting with underscore are private to the library.
  /// They're implementation details not meant for external use.
  _CumTotals _cumulativeTotalsUpTo(int handIndex, String teamId) {
    int total = 0;
    int bags = 0;
    int carry = 0;

    // DART CONCEPT: Collection .where() Method
    // Filters a collection based on a predicate function.
    // Returns an Iterable (lazy - doesn't create a new list immediately).
    for (final hand in _game.hands.where((h) => h.index <= handIndex)) {
      // Check if this hand is complete (all 13 tricks accounted for)
      final totalTricksWon = hand.teamInputs
          .map((ti) => ti.teamBooksWon)
          .reduce((a, b) => a + b);

      // Skip incomplete hands - they shouldn't count toward the score yet
      if (totalTricksWon != 13) continue;

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

    // Check for winner and trigger confetti if needed
    _checkForWinnerAndCelebrate();

    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppColors.surface,
            border: null,
            // Team names in center
            middle: Text(
              '${teams[0].name} vs ${teams[1].name}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Back button with auto-save
            leading: CupertinoNavigationBarBackButton(
              color: AppColors.accent,
              onPressed: () async {
                // Save before leaving
                _game = _game.copyWith(updatedAt: DateTime.now());
                await ref.read(repoProvider).upsertGame(_game);
                if (!mounted) return;
                context.pop();
              },
            ),
            // Save button
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              onPressed: () async {
                _game = _game.copyWith(updatedAt: DateTime.now());
                await ref.read(repoProvider).upsertGame(_game);
                ref.read(gamesProvider.notifier).refresh();
              },
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surface, AppColors.background],
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Team header showing current standings
                  _buildTeamHeader(),

                  const SizedBox(height: 16),

                  // All recorded hands
                  // DART CONCEPT: Spread Operator with .map()
                  // `...collection.map(...)` spreads the mapped items into
                  // the surrounding list. This is useful for inline transformations.
                  ..._game.hands.map(
                    (hand) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HandCard(
                        hand: hand,
                        teams: teams,
                        players: players,
                        onChanged: (updated) => _handleHandChanged(hand, updated),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Add hand button
                  _buildAddHandButton(),
                ],
              ),
            ),
          ),
        ),

        // Confetti widget - positioned at top center
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFF00B4D8), // Accent/teal
              Color(0xFF00C853), // Success/green
              Color(0xFFFFB300), // Warning/gold
              Color(0xFFE07A5F), // Team B coral
              Color(0xFFFFFFFF), // White
              Color(0xFF415A77), // Spade blue
            ],
            numberOfParticles: 30,
            gravity: 0.2,
            emissionFrequency: 0.05,
            maxBlastForce: 20,
            minBlastForce: 8,
          ),
        ),
      ],
    );
  }

  /// Checks if there's a winner and triggers confetti celebration.
  /// Only triggers once per winner change to avoid repeated animations.
  void _checkForWinnerAndCelebrate() {
    if (_game.hands.isEmpty) return;

    final team0Totals = _cumulativeTotalsUpTo(_game.hands.last.index, _game.teams[0].id);
    final team1Totals = _cumulativeTotalsUpTo(_game.hands.last.index, _game.teams[1].id);

    // Win conditions (use displayed score = total minus bags):
    // 1. Displayed score >= 500 AND strictly ahead
    // 2. Lead of >= 500 points over opponent
    _Winner newWinner = _Winner.none;
    final scoreA = team0Totals.total - team0Totals.bags;
    final scoreB = team1Totals.total - team1Totals.bags;
    final aWins = (scoreA >= 500 && scoreA > scoreB) || (scoreA - scoreB >= 500);
    final bWins = (scoreB >= 500 && scoreB > scoreA) || (scoreB - scoreA >= 500);

    if (aWins) newWinner = _Winner.teamA;
    if (bWins) newWinner = _Winner.teamB;

    // If winner changed to a winning state, trigger confetti
    if (newWinner != _Winner.none && newWinner != _currentWinner) {
      _currentWinner = newWinner;
      _hasShownConfetti = true;
      // Schedule confetti after frame to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confettiController.play();
        }
      });
    } else if (newWinner == _Winner.none) {
      // Reset if no winner (score was corrected)
      _currentWinner = _Winner.none;
      _hasShownConfetti = false;
    }
  }

  /// Builds the team header showing current standings.
  Widget _buildTeamHeader() {
    // Calculate current standings
    final team0Totals = _game.hands.isEmpty
        ? const _CumTotals(total: 0, bags: 0)
        : _cumulativeTotalsUpTo(_game.hands.last.index, _game.teams[0].id);
    final team1Totals = _game.hands.isEmpty
        ? const _CumTotals(total: 0, bags: 0)
        : _cumulativeTotalsUpTo(_game.hands.last.index, _game.teams[1].id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTeamScore(_game.teams[0], team0Totals)),
          Container(
            width: 1,
            height: 50,
            color: AppColors.secondary.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(child: _buildTeamScore(_game.teams[1], team1Totals)),
        ],
      ),
    );
  }

  /// Builds score display for a single team.
  Widget _buildTeamScore(Team team, _CumTotals totals) {
    // Calculate base score without bags
    final baseScore = totals.total - totals.bags;
    final bagsRemaining = totals.bags % 10;

    return Column(
      children: [
        Text(
          team.name,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$baseScore',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$bagsRemaining bags',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Handles when a hand's data changes.
  Future<void> _handleHandChanged(Hand oldHand, Hand updatedHand) async {
    final idx = _game.hands.indexWhere((x) => x.index == oldHand.index);
    final newHands = [..._game.hands];
    newHands[idx] = updatedHand;

    _game = _game.copyWith(
      hands: newHands,
      updatedAt: DateTime.now(),
    );

    // Recalculate bags and trigger rebuild
    _recomputeCarryOver();

    // Persist changes
    await ref.read(repoProvider).upsertGame(_game);
    ref.read(gamesProvider.notifier).refresh();
  }

  /// Builds the "Add Hand" button.
  Widget _buildAddHandButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(12),
      onPressed: _addHand,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.add_circled, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Add Hand ${_game.hands.length + 1}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Adds a new hand to the game.
  Future<void> _addHand() async {
    final nextIndex = _game.hands.length + 1;
    final newHand = Hand(
      index: nextIndex,
      teamInputs: [
        TeamHandInput(
          teamId: _game.teams[0].id,
          teamBid: [0, 0],
          teamBooksWon: 0,
          nilAchieved: const [false, false],
        ),
        TeamHandInput(
          teamId: _game.teams[1].id,
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

    _recomputeCarryOver();

    await ref.read(repoProvider).upsertGame(_game);
    ref.read(gamesProvider.notifier).refresh();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Simple data class for cumulative totals.
///
/// DART CONCEPT: Data Classes
/// Dart doesn't have a special "data class" keyword like Kotlin.
/// We create simple immutable classes with final fields and const constructors.
class _CumTotals {
  final int total;
  final int bags;

  const _CumTotals({required this.total, required this.bags});
}

/// Enum representing which team (if any) has won.
///
/// DART CONCEPT: Enums
/// Enums define a fixed set of constant values. They're type-safe and
/// more readable than magic strings or numbers.
enum _Winner { teamA, teamB, none }

// ═══════════════════════════════════════════════════════════════════════════
// HAND CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

/// A card displaying and editing a single hand's data.
///
/// FLUTTER CONCEPT: StatefulWidget for Form State
/// This widget manages temporary form state (bids, hands won, nils)
/// before persisting to the parent. This pattern:
/// - Reduces state churn in parent
/// - Allows local validation
/// - Provides snappy UI feedback
///
/// STATE FLOW:
/// 1. initState: Copy data from widget.hand to local state
/// 2. User interacts: Update local state, call _emit()
/// 3. _emit(): Notify parent via onChanged callback
/// 4. Parent persists and may rebuild this widget
class _HandCard extends StatefulWidget {
  /// The hand data to display/edit.
  final Hand hand;

  /// Both teams in the game.
  final List<Team> teams;

  /// All four players in seating order.
  final List<Player> players;

  /// Callback when any hand data changes.
  final ValueChanged<Hand> onChanged;

  const _HandCard({
    required this.hand,
    required this.teams,
    required this.players,
    required this.onChanged,
  });

  @override
  State<_HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<_HandCard> {
  /// Bids per team: bidsPerTeam[teamIndex][playerIndex]
  late List<List<int>> bidsPerTeam;

  /// Hands won per team: handsWonPerTeam[teamIndex]
  late List<int> handsWonPerTeam;

  /// Nil status per team: nilsPerTeam[teamIndex][playerIndex]
  late List<List<bool>> nilsPerTeam;

  @override
  void initState() {
    super.initState();
    _initializeFromHand();
  }

  /// Initializes local state from the hand widget property.
  void _initializeFromHand() {
    final inputs = widget.hand.teamInputs;
    // DART CONCEPT: List.generate with nested lists
    // Creates a 2D structure for per-player data within teams
    bidsPerTeam = List.generate(2, (i) => List<int>.from(inputs[i].teamBid));
    handsWonPerTeam = List.generate(2, (i) => inputs[i].teamBooksWon);
    nilsPerTeam = List.generate(2, (i) => List<bool>.from(inputs[i].nilAchieved));
  }

  /// Notifies the parent of changes by creating an updated Hand object.
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

  /// Formats cumulative scores (base score without bags).
  List<String> _formatTotals(_CumTotals a, _CumTotals b) {
    // Show base score only (total minus bags)
    // Bags are displayed separately in the team header
    String formatScore(_CumTotals t) {
      final base = t.total - t.bags;
      return '$base';
    }
    return [formatScore(a), formatScore(b)];
  }

  @override
  Widget build(BuildContext context) {
    // Get cumulative totals from parent state
    final parent = context.findAncestorStateOfType<_PlayScreenState>()!;
    final teamA = widget.teams[0].id;
    final teamB = widget.teams[1].id;
    final cumA = parent._cumulativeTotalsUpTo(widget.hand.index, teamA);
    final cumB = parent._cumulativeTotalsUpTo(widget.hand.index, teamB);
    final formattedScores = _formatTotals(cumA, cumB);

    final winner = _determineWinner(cumA, cumB);

    // Check if hand is complete (all 13 tricks accounted for)
    final isComplete = handsWonPerTeam[0] + handsWonPerTeam[1] == 13;

    // Calculate overslagen (bags) earned this hand per team
    final teamBidA = bidsPerTeam[0].reduce((a, b) => a + b);
    final teamBidB = bidsPerTeam[1].reduce((a, b) => a + b);
    final madeBidA = handsWonPerTeam[0] >= teamBidA;
    final madeBidB = handsWonPerTeam[1] >= teamBidB;
    final handBagsA = madeBidA ? handsWonPerTeam[0] - teamBidA : 0;
    final handBagsB = madeBidB ? handsWonPerTeam[1] - teamBidB : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with hand number
          _buildHeader(),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Player name row
                _buildPlayerNameRow(),

                const SizedBox(height: 12),

                // Bids row
                _buildBidsRow(),

                const SizedBox(height: 12),

                // Nil toggles row
                _buildNilRow(),

                const SizedBox(height: 12),

                // Hands won row
                _buildHandsWonRow(),

                // Overslagen and score (only when hand is complete)
                if (isComplete) ...[
                  const SizedBox(height: 12),
                  _buildOverslagenRow(handBagsA, handBagsB),
                  const SizedBox(height: 8),
                  _buildScoreRow(formattedScores, winner),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Determines the winner based on current scores.
  _Winner _determineWinner(_CumTotals cumA, _CumTotals cumB) {
    // Win conditions (use displayed score = total minus bags):
    // 1. Displayed score >= 500 AND strictly ahead
    // 2. Lead of >= 500 points over opponent
    final scoreA = cumA.total - cumA.bags;
    final scoreB = cumB.total - cumB.bags;
    final aWins = (scoreA >= 500 && scoreA > scoreB) || (scoreA - scoreB >= 500);
    final bWins = (scoreB >= 500 && scoreB > scoreA) || (scoreB - scoreA >= 500);

    if (aWins) return _Winner.teamA;
    if (bWins) return _Winner.teamB;
    return _Winner.none;
  }

  /// Builds the header showing the hand number.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.hand_raised_fill,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            'Hand ${widget.hand.index}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row showing player name abbreviations.
  Widget _buildPlayerNameRow() {
    // Get abbreviated names (first 2 characters) for each player
    String abbrev(String fullName) {
      return fullName.length >= 2
          ? fullName.substring(0, 2).toUpperCase()
          : fullName.toUpperCase();
    }

    // Team names are in "Player1/Player2" format
    final teamNames = [
      widget.teams[0].name.split('/'),
      widget.teams[1].name.split('/'),
    ];

    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Player')),
        // Team 0 players
        Expanded(
          child: Text(
            abbrev(teamNames[0][0]),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            abbrev(teamNames[0].length > 1 ? teamNames[0][1] : ''),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        // Team 1 players
        Expanded(
          child: Text(
            abbrev(teamNames[1][0]),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            abbrev(teamNames[1].length > 1 ? teamNames[1][1] : ''),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the row for individual player bids.
  Widget _buildBidsRow() {
    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Bids')),
        // Team 0 Player 0
        Expanded(child: _buildBidStepper(0, 0)),
        const SizedBox(width: 8),
        // Team 0 Player 1
        Expanded(child: _buildBidStepper(0, 1)),
        const SizedBox(width: 8),
        // Team 1 Player 0
        Expanded(child: _buildBidStepper(1, 0)),
        const SizedBox(width: 8),
        // Team 1 Player 1
        Expanded(child: _buildBidStepper(1, 1)),
      ],
    );
  }

  /// Builds a stepper for a player's bid.
  Widget _buildBidStepper(int teamIdx, int playerIdx) {
    return NumericStepper(
      value: bidsPerTeam[teamIdx][playerIdx],
      min: 0,
      max: 13,
      direction: Axis.vertical,
      onDecrement: () {
        setState(() {
          bidsPerTeam[teamIdx][playerIdx] =
              (bidsPerTeam[teamIdx][playerIdx] - 1).clamp(0, 13);
          // Auto-clear nil status if bid > 0
          if (bidsPerTeam[teamIdx][playerIdx] > 0) {
            nilsPerTeam[teamIdx][playerIdx] = false;
          }
        });
        _emit();
      },
      onIncrement: () {
        setState(() {
          bidsPerTeam[teamIdx][playerIdx] =
              (bidsPerTeam[teamIdx][playerIdx] + 1).clamp(0, 13);
          if (bidsPerTeam[teamIdx][playerIdx] > 0) {
            nilsPerTeam[teamIdx][playerIdx] = false;
          }
        });
        _emit();
      },
    );
  }

  /// Builds the row for nil bid toggles.
  Widget _buildNilRow() {
    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Nil Made')),
        _buildNilToggle(0, 0),
        const SizedBox(width: 8),
        _buildNilToggle(0, 1),
        const SizedBox(width: 8),
        _buildNilToggle(1, 0),
        const SizedBox(width: 8),
        _buildNilToggle(1, 1),
      ],
    );
  }

  /// Builds a nil status toggle button.
  ///
  /// FLUTTER CONCEPT: Custom Toggle Button
  /// Instead of using a Switch, we create a custom toggle that better
  /// fits the UI. It shows a checkmark when nil was achieved.
  Widget _buildNilToggle(int teamIdx, int playerIdx) {
    final isNil = nilsPerTeam[teamIdx][playerIdx];
    final canToggle = bidsPerTeam[teamIdx][playerIdx] == 0;

    return Expanded(
      child: GestureDetector(
        onTap: canToggle ? () {
          setState(() {
            nilsPerTeam[teamIdx][playerIdx] = !isNil;
          });
          _emit();
        } : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isNil
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success.withValues(alpha: 0.25),
                      AppColors.success.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isNil ? null : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isNil
                  ? AppColors.success.withValues(alpha: 0.6)
                  : canToggle
                      ? AppColors.secondary.withValues(alpha: 0.3)
                      : AppColors.secondary.withValues(alpha: 0.1),
              width: isNil ? 1.5 : 1,
            ),
            boxShadow: isNil
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isNil
                      ? CupertinoIcons.checkmark_alt
                      : CupertinoIcons.minus,
                  key: ValueKey(isNil),
                  color: canToggle
                      ? (isNil ? AppColors.success : AppColors.textMuted)
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the row for hands won per team.
  Widget _buildHandsWonRow() {
    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Won')),
        Expanded(
          flex: 2,
          child: NumericStepper(
            value: handsWonPerTeam[0],
            min: 0,
            max: 13,
            onDecrement: () {
              setState(() {
                handsWonPerTeam[0] = (handsWonPerTeam[0] - 1).clamp(0, 13);
              });
              _emit();
            },
            onIncrement: () {
              setState(() {
                handsWonPerTeam[0] = (handsWonPerTeam[0] + 1).clamp(0, 13);
              });
              _emit();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: NumericStepper(
            value: handsWonPerTeam[1],
            min: 0,
            max: 13,
            onDecrement: () {
              setState(() {
                handsWonPerTeam[1] = (handsWonPerTeam[1] - 1).clamp(0, 13);
              });
              _emit();
            },
            onIncrement: () {
              setState(() {
                handsWonPerTeam[1] = (handsWonPerTeam[1] + 1).clamp(0, 13);
              });
              _emit();
            },
          ),
        ),
      ],
    );
  }

  /// Builds the overslagen (bags) display row for this hand.
  Widget _buildOverslagenRow(int bagsA, int bagsB) {
    Color bagColor(int bags) => bags > 0
        ? AppColors.warning.withValues(alpha: 0.3)
        : AppColors.surfaceElevated;

    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Overslagen')),
        Expanded(
          child: ReadonlyField(
            text: '$bagsA',
            backgroundColor: bagColor(bagsA),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReadonlyField(
            text: '$bagsB',
            backgroundColor: bagColor(bagsB),
          ),
        ),
      ],
    );
  }

  /// Builds the score display row.
  Widget _buildScoreRow(List<String> scores, _Winner winner) {
    return Row(
      children: [
        SizedBox(width: 80, child: _buildLabel('Score')),
        Expanded(
          child: ReadonlyField(
            text: scores[0],
            backgroundColor: winner == _Winner.teamA
                ? AppColors.success
                : winner == _Winner.teamB
                    ? AppColors.error.withValues(alpha: 0.7)
                    : AppColors.surfaceElevated,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReadonlyField(
            text: scores[1],
            backgroundColor: winner == _Winner.teamB
                ? AppColors.success
                : winner == _Winner.teamA
                    ? AppColors.error.withValues(alpha: 0.7)
                    : AppColors.surfaceElevated,
          ),
        ),
      ],
    );
  }

  /// Builds a row label.
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
