/// ============================================================================
/// game_repository.dart - Data Persistence Layer
/// ============================================================================
///
/// This file implements the Repository pattern for persisting game data.
/// It abstracts the storage mechanism (Hive) from the rest of the app.
///
/// ARCHITECTURE CONCEPT: Repository Pattern
/// The Repository pattern provides a clean API for data access:
/// - Hides storage implementation details (Hive, SQLite, API, etc.)
/// - Provides domain-focused methods (getGame, listGames, etc.)
/// - Makes the app testable (can mock the repository)
/// - Centralizes data access logic
///
/// HIVE OVERVIEW:
/// Hive is a lightweight, blazing-fast NoSQL database for Flutter.
/// - Key-value storage (like a persistent Map)
/// - No native dependencies (pure Dart)
/// - Works on all platforms (mobile, web, desktop)
/// - Supports encryption for sensitive data
///
/// DATA FLOW:
/// UI → State (Riverpod) → Repository → Hive → Local Storage
/// ============================================================================

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

/// Repository for CRUD operations on [Game] entities.
///
/// DART CONCEPT: Singleton Pattern
/// This class uses the singleton pattern to ensure only one instance exists.
/// This is important because:
/// - Hive boxes should only be opened once
/// - Consistent state across the app
/// - Efficient resource usage
///
/// IMPLEMENTATION:
/// 1. Private constructor `_internal()` prevents external instantiation
/// 2. Static `_instance` holds the single instance
/// 3. Factory constructor returns the existing instance
///
/// USAGE:
/// ```dart
/// final repo = GameRepository();  // Always returns same instance
/// await repo.init();              // Call once at app startup
/// ```
class GameRepository {
  // ─────────────────────────────────────────────────────────────────────────
  // Singleton Setup
  // ─────────────────────────────────────────────────────────────────────────

  /// The name of the Hive box (like a database table).
  static const _boxName = 'spades_games';

  /// Reference to the opened Hive box.
  ///
  /// DART CONCEPT: `late` Keyword
  /// The `late` modifier indicates this field will be initialized later,
  /// but before it's used. This is necessary because:
  /// - We can't open Hive synchronously in a constructor
  /// - We need async initialization in `init()`
  ///
  /// If accessed before initialization, Dart throws a runtime error.
  late final Box<String> _box;

  /// The single instance of this repository.
  ///
  /// DART CONCEPT: Static Fields
  /// Static fields belong to the class, not instances. There's only one
  /// `_instance` shared across all uses of GameRepository.
  static final GameRepository _instance = GameRepository._internal();

  /// Private named constructor.
  ///
  /// DART CONCEPT: Named Constructors
  /// Constructors can have names (after a dot). The underscore makes it
  /// private, so only this file can call `GameRepository._internal()`.
  GameRepository._internal();

  /// Factory constructor that returns the singleton instance.
  ///
  /// DART CONCEPT: Factory Constructors
  /// A `factory` constructor can return:
  /// - An existing instance (like here)
  /// - A subclass instance
  /// - A cached instance
  ///
  /// Unlike regular constructors, factory constructors don't implicitly
  /// create a new instance - they have full control over what's returned.
  factory GameRepository() {
    return _instance;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Initializes Hive and opens the games box.
  ///
  /// MUST be called once at app startup before using other methods.
  /// Typically called in `main()` before `runApp()`.
  ///
  /// DART CONCEPT: Async Initialization
  /// Hive requires async initialization, so this is an async method.
  /// The caller must await it to ensure Hive is ready.
  Future<void> init() async {
    // Initialize Hive with Flutter-specific path handling
    await Hive.initFlutter();

    // Open (or create) the box for storing games
    // Box<String> means values are stored as JSON strings
    _box = await Hive.openBox<String>(_boxName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates or updates a game in storage.
  ///
  /// "Upsert" = Update if exists, Insert if new.
  /// The game's ID is used as the storage key.
  ///
  /// SERIALIZATION:
  /// Games are converted to JSON strings for storage:
  /// Game → Map<String, dynamic> → JSON String → Hive
  Future<void> upsertGame(Game game) async {
    await _box.put(game.id, jsonEncode(_toMap(game)));
  }

  /// Retrieves a single game by ID, or null if not found.
  ///
  /// DESERIALIZATION:
  /// JSON String → Map<String, dynamic> → Game
  Game? getGame(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _fromMap(jsonDecode(raw));
  }

  /// Returns all games, sorted by most recently updated.
  ///
  /// DART CONCEPT: Cascade Operator (..)
  /// The `..sort()` is a cascade - it calls sort() on the list
  /// and then returns the list itself (not the sort return value).
  /// This allows chaining operations fluently.
  List<Game> listGames() {
    return _box.values.map((raw) => _fromMap(jsonDecode(raw))).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Permanently deletes a game by ID.
  Future<void> deleteGame(String id) async {
    await _box.delete(id);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Serialization Helpers (Game ↔ JSON)
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts a [Game] object to a JSON-compatible Map.
  ///
  /// DART CONCEPT: Map Literals
  /// Maps are created with `{key: value}` syntax. The return type
  /// `Map<String, dynamic>` means string keys with values of any type.
  ///
  /// DART CONCEPT: Method Chaining with .map()
  /// Collections have functional methods like `.map()` that transform
  /// each element. The result is an Iterable, so `.toList()` converts
  /// it back to a List.
  Map<String, dynamic> _toMap(Game g) => {
    'id': g.id,
    // DateTime is converted to ISO 8601 string for JSON compatibility
    'createdAt': g.createdAt.toIso8601String(),
    'updatedAt': g.updatedAt.toIso8601String(),
    // Nested objects are converted to Maps recursively
    'players': g.players.map((p) => {'id': p.id, 'name': p.name}).toList(),
    'teams': g.teams
        .map((t) => {'id': t.id, 'name': t.name, 'playerIds': t.playerIds})
        .toList(),
    'config': {
      'bagsPenalty': g.config.bagsPenalty,
      'nilMade': g.config.nilMade,
      'nilFailed': g.config.nilFailed,
    },
    'hands': g.hands
        .map(
          (h) => {
            'index': h.index,
            'inputs': h.teamInputs
                .map(
                  (ti) => {
                    'teamId': ti.teamId,
                    'teamBid': ti.teamBid,
                    'teamBooksWon': ti.teamBooksWon,
                    'nilAchieved': ti.nilAchieved
                  },
                )
                .toList(),
          },
        )
        .toList(),
  };

  /// Reconstructs a [Game] object from a JSON-compatible Map.
  ///
  /// DART CONCEPT: Type Casting
  /// JSON decoding returns `dynamic` types. We cast to specific types:
  /// - `m['players'] as List` - Cast to List
  /// - `List<String>.from(...)` - Create typed List from dynamic List
  Game _fromMap(Map<String, dynamic> m) {
    // Deserialize players
    final players = (m['players'] as List)
        .map((p) => Player(id: p['id'], name: p['name']))
        .toList();

    // Deserialize teams
    final teams = (m['teams'] as List)
        .map(
          (t) => Team(
            id: t['id'],
            name: t['name'],
            // List<String>.from() creates a typed list from dynamic
            playerIds: List<String>.from(t['playerIds']),
          ),
        )
        .toList();

    // Deserialize config
    final cfg = m['config'];
    final config = GameConfig(
      bagsPenalty: cfg['bagsPenalty'],
      nilMade: cfg['nilMade'],
      nilFailed: cfg['nilFailed'],
    );

    // Deserialize hands (most complex nested structure)
    final hands = (m['hands'] as List).map((h) {
      final inputs = (h['inputs'] as List)
          .map(
            (ti) => TeamHandInput(
              teamId: ti['teamId'],
              teamBid: List<int>.from(ti['teamBid']),
              teamBooksWon: ti['teamBooksWon'],
              nilAchieved: List<bool>.from(ti['nilAchieved']),
            ),
          )
          .toList();
      return Hand(index: h['index'], teamInputs: inputs);
    }).toList();

    // Reconstruct the full Game object
    return Game(
      id: m['id'],
      // DateTime.parse() converts ISO 8601 strings back to DateTime
      createdAt: DateTime.parse(m['createdAt']),
      updatedAt: DateTime.parse(m['updatedAt']),
      players: players,
      teams: teams,
      config: config,
      hands: hands,
    );
  }
}
