/// ============================================================================
/// models.dart - Immutable Data Models for Spades Game State
/// ============================================================================
///
/// This file contains all the data models that represent the domain of a
/// Spades card game. Each model follows Dart's best practices for immutability
/// and value semantics.
///
/// ARCHITECTURE CONCEPT: Domain Models
/// These classes represent the "entities" of our application - the core
/// business objects that model the real-world concepts of a Spades game.
///
/// KEY DART CONCEPTS DEMONSTRATED:
/// - @immutable annotation and const constructors
/// - Named parameters with `required` keyword
/// - Final fields for immutability
/// - The copyWith pattern for immutable updates
/// ============================================================================

import 'package:flutter/foundation.dart';

/// Represents a single player in the game.
///
/// DART CONCEPT: @immutable Annotation
/// The `@immutable` annotation from `package:flutter/foundation.dart` is a
/// documentation hint that indicates:
/// 1. All instance fields should be `final`
/// 2. Instances should not be modified after creation
/// 3. The Dart analyzer will warn if these rules are violated
///
/// WHY IMMUTABILITY?
/// - Safer state management (no unexpected side effects)
/// - Better for Flutter's widget rebuild system
/// - Enables efficient comparison (identity vs. equality)
/// - Thread-safe by default
@immutable
class Player {
  /// Unique identifier for this player (typically a UUID).
  ///
  /// DART CONCEPT: Final Fields
  /// The `final` keyword means this field can only be assigned once,
  /// in the constructor. This is different from `const` which requires
  /// a compile-time constant value.
  final String id;

  /// Display name shown in the UI.
  final String name;

  /// Creates a new [Player] instance.
  ///
  /// DART CONCEPT: Const Constructor
  /// A `const` constructor allows creating compile-time constants when all
  /// arguments are also constants. This enables Flutter optimizations like
  /// widget caching. Even when called without `const`, it still works as a
  /// regular constructor.
  ///
  /// DART CONCEPT: Named Parameters with `required`
  /// Named parameters (inside `{}`) make code more readable at call sites:
  ///   `Player(id: '123', name: 'Alice')` vs `Player('123', 'Alice')`
  /// The `required` keyword makes them mandatory.
  const Player({required this.id, required this.name});
}

/// Represents a team of two players working together.
///
/// In Spades, teams are traditionally:
/// - North/South (players across from each other)
/// - East/West (the opposing partnership)
@immutable
class Team {
  /// Unique identifier for this team.
  final String id;

  /// Display name (typically "Player1/Player3" format).
  final String name;

  /// List of player IDs belonging to this team.
  ///
  /// DART CONCEPT: List<T> Generics
  /// `List<String>` is a generic type - a list that can only contain Strings.
  /// This provides compile-time type checking and better IDE support.
  final List<String> playerIds;

  const Team({
    required this.id,
    required this.name,
    required this.playerIds,
  });
}

/// Captures the bid and result for one team in a single hand.
///
/// This is a "value object" - it has no identity of its own and is defined
/// entirely by its values. Two TeamHandInput objects with the same values
/// are conceptually equal.
@immutable
class TeamHandInput {
  /// The team this input belongs to.
  final String teamId;

  /// Individual bids from each player on the team.
  /// Index 0 = first team member, Index 1 = second team member.
  ///
  /// WHY A LIST?
  /// While a team's combined bid matters for scoring, tracking individual
  /// bids allows us to properly handle nil bids (bid of 0).
  final List<int> teamBid;

  /// Total number of "books" (tricks) won by this team in this hand.
  /// Range: 0-13 (a full deck has 13 tricks).
  final int teamBooksWon;

  /// Whether each player achieved their nil bid (if they bid nil).
  /// Index 0 = first team member, Index 1 = second team member.
  ///
  /// GAME RULE: A "nil" bid means bidding 0 and trying to win no tricks.
  /// If successful: +100 points. If failed: -100 points.
  final List<bool> nilAchieved;

  const TeamHandInput({
    required this.teamId,
    required this.teamBid,
    required this.teamBooksWon,
    required this.nilAchieved,
  });
}

/// Represents a single "hand" (round) of play.
///
/// In Spades, a hand consists of:
/// 1. Players bidding how many tricks they'll win
/// 2. Playing all 13 tricks
/// 3. Scoring based on bids vs. actual tricks won
@immutable
class Hand {
  /// 1-based index of this hand in the game (Hand 1, Hand 2, etc.).
  final int index;

  /// Input data from each team for this hand.
  /// Always contains exactly 2 elements (one per team).
  final List<TeamHandInput> teamInputs;

  const Hand({required this.index, required this.teamInputs});
}

/// Configuration options for scoring rules.
///
/// DART CONCEPT: Default Parameter Values
/// Parameters can have default values, making them optional at call sites.
/// If not specified, the defaults represent standard Spades rules.
@immutable
class GameConfig {
  /// Points lost when accumulating 10 bags (-100 by default).
  /// "Bags" are tricks won beyond what was bid.
  final int bagsPenalty;

  /// Points earned for successfully making a nil bid (+100).
  final int nilMade;

  /// Points lost for failing a nil bid (-100).
  final int nilFailed;

  /// Creates a [GameConfig] with standard Spades scoring rules.
  /// All parameters are optional with sensible defaults.
  const GameConfig({
    this.bagsPenalty = -100,
    this.nilMade = 100,
    this.nilFailed = -100,
  });
}

/// The root game entity containing all game state.
///
/// This is the aggregate root for game data - the single entry point for
/// accessing all related entities (players, teams, hands).
@immutable
class Game {
  /// Unique identifier for this game.
  final String id;

  /// When this game was first created.
  final DateTime createdAt;

  /// When this game was last modified (used for sorting).
  final DateTime updatedAt;

  /// All four players in seating order: North, East, South, West.
  ///
  /// GAME CONCEPT: Seating matters in Spades because partners sit across
  /// from each other (N/S and E/W).
  final List<Player> players;

  /// The two teams: index 0 = N/S, index 1 = E/W.
  final List<Team> teams;

  /// Scoring configuration for this game.
  final GameConfig config;

  /// All completed hands in this game.
  final List<Hand> hands;

  const Game({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.players,
    required this.teams,
    required this.config,
    required this.hands,
  });

  /// Creates a modified copy of this game with updated fields.
  ///
  /// DART CONCEPT: The copyWith Pattern
  /// Since immutable objects can't be modified, we create new instances
  /// when we need to "change" something. The `copyWith` method makes this
  /// ergonomic by defaulting to existing values for unchanged fields.
  ///
  /// USAGE:
  /// ```dart
  /// final updatedGame = game.copyWith(
  ///   updatedAt: DateTime.now(),
  ///   hands: [...game.hands, newHand],
  /// );
  /// ```
  ///
  /// DART CONCEPT: Nullable Parameters
  /// Parameters like `DateTime? updatedAt` use the `?` suffix to indicate
  /// they can be null. We use the `??` null-coalescing operator to fall
  /// back to the existing value when null is passed.
  Game copyWith({DateTime? updatedAt, List<Hand>? hands}) => Game(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    players: players,
    teams: teams,
    config: config,
    hands: hands ?? this.hands,
  );
}