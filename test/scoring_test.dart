// test/scoring_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spades/models.dart';
import 'package:spades/scoring.dart';

class FakeGameConfig extends GameConfig {
  @override
  int get nilMade => 100;
  @override
  int get nilFailed => -100;
  @override
  int get bagsPenalty => -100;
}

void main() {
  final config = FakeGameConfig();

  test('Team makes bid with no nils or bags', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 0,
      teamBid: 5,
      teamBooksWon: 5,
      playerBids: [2, 3],
      nilAchieved: [false, false],
    );
    expect(result.base, 50);
    expect(result.bags, 0);
    expect(result.nilAdj, 0);
    expect(result.penalty, 0);
    expect(result.total, 50);
    expect(result.penaltyBlocks, 0);
  });

  test('Team makes bid with bags, no nils', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 0,
      teamBid: 4,
      teamBooksWon: 6,
      playerBids: [2, 2],
      nilAchieved: [false, false],
    );
    expect(result.base, 40);
    expect(result.bags, 2);
    expect(result.nilAdj, 0);
    expect(result.penalty, 0);
    expect(result.total, 42);
    expect(result.penaltyBlocks, 0);
  });

  test('Team fails bid, no nils', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 0,
      teamBid: 6,
      teamBooksWon: 5,
      playerBids: [3, 3],
      nilAchieved: [false, false],
    );
    expect(result.base, -60);
    expect(result.bags, 0);
    expect(result.nilAdj, 0);
    expect(result.penalty, 0);
    expect(result.total, -60);
    expect(result.penaltyBlocks, 0);
  });

  test('Team makes bid, one nil made, one nil failed', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 0,
      teamBid: 4,
      teamBooksWon: 4,
      playerBids: [0, 0],
      nilAchieved: [true, false],
    );
    expect(result.base, 40);
    expect(result.bags, 0);
    expect(result.nilAdj, 0); // 100 + (-100)
    expect(result.penalty, 0);
    expect(result.total, 40);
    expect(result.penaltyBlocks, 0);
  });

  test('Team accumulates enough bags for penalty', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 8,
      teamBid: 2,
      teamBooksWon: 5,
      playerBids: [2, 0],
      nilAchieved: [false, true],
    );
    // made bid, 3 bags, 8+3=11, so 1 penalty block
    expect(result.base, 20);
    expect(result.bags, 3);
    expect(result.nilAdj, 100);
    expect(result.penalty, -100);
    expect(result.total, 23);
    expect(result.penaltyBlocks, 1);
  });

  test('Multiple penalty blocks in one hand', () {
    final result = computeTeamScore(
      config: config,
      currentBagsRemainder: 18,
      teamBid: 1,
      teamBooksWon: 13,
      playerBids: [1, 0],
      nilAchieved: [false, true],
    );
    // made bid, 12 bags, 18+12=30, 3 penalty blocks
    expect(result.base, 10);
    expect(result.bags, 12);
    expect(result.nilAdj, 100);
    expect(result.penalty, -300);
    expect(result.total, -178);
    expect(result.penaltyBlocks, 3);
  });
}
