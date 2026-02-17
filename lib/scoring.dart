/// ============================================================================
/// scoring.dart - Spades Game Scoring Logic (Pure Functions)
/// ============================================================================
///
/// This file implements the complete scoring rules for the card game Spades.
/// All functions here are "pure" - they have no side effects and always return
/// the same output for the same inputs.
///
/// ARCHITECTURE CONCEPT: Pure Functions & Separation of Concerns
/// By keeping scoring logic separate from UI and state management, we gain:
/// 1. **Testability** - Functions can be unit tested in isolation
/// 2. **Reusability** - Logic can be used anywhere without UI dependencies
/// 3. **Predictability** - No hidden state mutations or side effects
/// 4. **Maintainability** - Scoring rules are documented in one place
///
/// SPADES SCORING RULES (Quick Reference):
/// - Make your bid: +10 points per trick bid
/// - Fail your bid: -10 points per trick bid
/// - Overtricks ("bags"): +1 point each, but...
/// - Every 10 bags: -100 point penalty ("bagging out")
/// - Nil bid made: +100 points
/// - Nil bid failed: -100 points
/// ============================================================================

import 'models.dart';

/// A breakdown of score components for one team in one hand.
///
/// DART CONCEPT: Value Objects
/// This class exists purely to group related data together and return
/// multiple values from a function. It has no behavior, only data.
///
/// WHY A CLASS INSTEAD OF A RECORD?
/// Dart 3 introduced Records for simple data grouping, but a class provides:
/// - Named fields (more readable than positional access)
/// - Documentation per field
/// - Easier to extend if needed
class TeamScoreBreakdown {
  /// Base score from making or failing the bid.
  /// Positive if bid was made (+10 × bid), negative if failed (-10 × bid).
  final int base;

  /// Number of bags (overtricks) earned this hand.
  /// Only positive when bid was made; zero if bid failed.
  final int bags;

  /// Net adjustment from nil bids (sum of all nil outcomes for team).
  /// Can be -200 to +200 depending on both players' nil results.
  final int nilAdj;

  /// Penalty applied for accumulating 10+ bags.
  /// Typically -100 per block of 10 bags.
  final int penalty;

  /// Total points for this hand (base + bags + nilAdj + penalty).
  final int total;

  /// How many 10-bag penalty blocks were triggered this hand.
  /// Used to reset the bag counter after penalties are applied.
  final int penaltyBlocks;

  /// Creates a new score breakdown.
  ///
  /// DART CONCEPT: Const Constructor
  /// Even though this object holds computed values (not literals),
  /// the constructor is `const` to allow compiler optimizations when
  /// used with constant values in tests.
  const TeamScoreBreakdown({
    required this.base,
    required this.bags,
    required this.nilAdj,
    required this.penalty,
    required this.total,
    required this.penaltyBlocks,
  });
}

/// Computes the score breakdown for one team in a single hand.
///
/// DART CONCEPT: Top-Level Functions
/// Unlike Java/C# where functions must belong to a class, Dart allows
/// top-level functions. This is idiomatic for stateless utility functions.
///
/// PARAMETERS:
/// - [config]: Game rules configuration (nil values, bag penalties)
/// - [currentBagsRemainder]: Bags accumulated from previous hands (mod 10)
/// - [teamBid]: Combined bid for the team (sum of both players' bids)
/// - [teamBooksWon]: Actual tricks won by the team
/// - [playerBids]: Individual player bids [player1Bid, player2Bid]
/// - [nilAchieved]: Whether each player achieved nil [player1, player2]
///
/// RETURNS: A [TeamScoreBreakdown] with all score components itemized.
///
/// EXAMPLE:
/// ```dart
/// final score = computeTeamScore(
///   config: GameConfig(),
///   currentBagsRemainder: 7,  // Already have 7 bags
///   teamBid: 6,               // Team bid 6 total
///   teamBooksWon: 8,          // Team won 8 tricks
///   playerBids: [3, 3],       // Each player bid 3
///   nilAchieved: [false, false],
/// );
/// // Result: base=60, bags=2, nilAdj=0, penalty=-100 (7+2=9... no wait, that's 9)
/// // Actually with 7 bags + 2 = 9, no penalty yet. Penalty at 10+.
/// ```
TeamScoreBreakdown computeTeamScore({
  required GameConfig config,
  required int currentBagsRemainder,
  required int teamBid,
  required int teamBooksWon,
  required List<int> playerBids,
  required List<bool> nilAchieved,
}) {
  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: Determine if the team made their bid
  // ─────────────────────────────────────────────────────────────────────────

  // A team "makes" their bid if they won at least as many tricks as they bid.
  final bool madeBid = teamBooksWon >= teamBid;

  // Base points: +10 per trick bid if made, -10 per trick bid if failed.
  // DART CONCEPT: Conditional Expression
  // The ternary operator `condition ? valueIfTrue : valueIfFalse` is
  // an expression (returns a value) unlike if/else which is a statement.
  final int base = madeBid ? 10 * teamBid : -10 * teamBid;

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: Calculate bags (overtricks)
  // ─────────────────────────────────────────────────────────────────────────

  // Bags are tricks won beyond the bid. Only count if bid was made.
  // Each bag is worth +1 point but accumulating 10 triggers a penalty.
  final int handBags = madeBid ? (teamBooksWon - teamBid) : 0;

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: Calculate nil bid adjustments
  // ─────────────────────────────────────────────────────────────────────────

  // DART CONCEPT: For Loop with Index
  // We need the index to correlate playerBids[i] with nilAchieved[i].
  int nilAdj = 0;
  for (int i = 0; i < playerBids.length; i++) {
    // Only players who bid 0 (nil) get nil scoring applied.
    if (playerBids[i] == 0) {
      // Made nil = +100, failed nil = -100 (or whatever config specifies)
      nilAdj += nilAchieved[i] ? config.nilMade : config.nilFailed;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4: Calculate bag penalty ("bagging out")
  // ─────────────────────────────────────────────────────────────────────────

  // Total bags after this hand = carry-over from previous hands + this hand's bags
  final int totalBagsAfter = currentBagsRemainder + handBags;

  // DART CONCEPT: Integer Division (~/）
  // The `~/` operator performs integer division (rounds toward zero).
  // This tells us how many complete sets of 10 bags we've accumulated.
  final int penaltyBlocks = totalBagsAfter ~/ 10;

  // Apply penalty for each 10-bag block
  final int penalty = penaltyBlocks * config.bagsPenalty;

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 5: Sum it all up
  // ─────────────────────────────────────────────────────────────────────────

  final int total = base + handBags + nilAdj + penalty;

  return TeamScoreBreakdown(
    base: base,
    bags: handBags,
    nilAdj: nilAdj,
    penalty: penalty,
    total: total,
    penaltyBlocks: penaltyBlocks,
  );
}
