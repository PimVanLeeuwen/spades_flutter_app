import 'models.dart';

class TeamScoreBreakdown {
  final int base;     // +/- 10 * teamBid
  final int bags;     // +1 per overtrick when bid is made
  final int nilAdj;   // sum of nil bonuses/penalties
  final int penalty;  // -100 per 10 bags
  final int total;
  final int penaltyBlocks; // number of 10-bag penalties applied in this hand's carry computation

  const TeamScoreBreakdown({
    required this.base,
    required this.bags,
    required this.nilAdj,
    required this.penalty,
    required this.total,
    required this.penaltyBlocks,
  });
}

TeamScoreBreakdown computeTeamScore({
  required GameConfig config,         // game configuration
  required int currentBagsRemainder,  // carry from previous hands
  required int teamBid,               // bid for this hand
  required int teamBooksWon,          // books won this hand
  required List<int> playerBids,
  required List<bool> nilAchieved,      // nil statuses for this hand
}) {
  // score when bid is reached
  final made = teamBooksWon >= teamBid;
  final base = made ? 10 * teamBid : -10 * teamBid;

  // bags from this hand
  final handBags = made ? (teamBooksWon - teamBid) : 0;

  // Nil adjustments (per player)
  int nilAdj = 0;
  for (int i = 0; i < playerBids.length; i++) {
    if (playerBids[i] == 0) {
      nilAdj += nilAchieved[i] ? config.nilMade : config.nilFailed;
    }
  }

  // Carryover bags accounting
  final carryAfter = currentBagsRemainder + handBags;
  final blocks = carryAfter ~/ 10; // number of penalties this hand triggers
  final penalty = blocks * config.bagsPenalty; // e.g., -100 per block

  // Total points for this hand: base + bags + nil + penalty
  final total = base + handBags + nilAdj + penalty;

  return TeamScoreBreakdown(
    base: base,
    bags: handBags,
    nilAdj: nilAdj,
    penalty: penalty,
    total: total,
    penaltyBlocks: blocks,
  );
}
