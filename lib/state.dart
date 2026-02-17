/// ============================================================================
/// state.dart - Application State Management with Riverpod
/// ============================================================================
///
/// This file implements state management using Riverpod, a popular reactive
/// state management solution for Flutter. It demonstrates:
///
/// - Provider pattern for dependency injection
/// - StateNotifier for mutable state with immutable updates
/// - Reactive data flow (UI rebuilds when state changes)
///
/// RIVERPOD OVERVIEW:
/// Riverpod is a compile-safe, testable state management library that builds
/// on the Provider pattern. Key concepts:
///
/// 1. **Provider** - A read-only value (service, repository, computed value)
/// 2. **StateNotifier** - A class that holds mutable state and exposes methods
/// 3. **ref** - A reference object used to read other providers
///
/// WHY RIVERPOD OVER PROVIDER?
/// - Compile-time safety (errors caught before runtime)
/// - No BuildContext needed to access state
/// - Better testability and dependency injection
/// - Supports async providers natively
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import 'game_repository.dart';
import 'models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS - Dependency Injection & State Containers
// ═══════════════════════════════════════════════════════════════════════════

/// Provides the singleton [GameRepository] instance.
///
/// RIVERPOD CONCEPT: Provider
/// A `Provider` is the most basic provider type - it exposes a read-only value.
/// Here it provides access to our repository (data layer).
///
/// The callback `(ref) => GameRepository()` is called lazily - the repository
/// is only created when first accessed.
///
/// USAGE:
/// ```dart
/// final repo = ref.read(repoProvider);  // Access without listening
/// final repo = ref.watch(repoProvider); // Access and rebuild on change
/// ```
final repoProvider = Provider<GameRepository>((ref) => GameRepository());

/// Provides the list of all games with reactive state management.
///
/// RIVERPOD CONCEPT: StateNotifierProvider
/// Combines two things:
/// 1. A `StateNotifier` subclass that holds and mutates state
/// 2. Automatic UI rebuilding when state changes
///
/// GENERIC PARAMETERS:
/// - `GamesController` - The StateNotifier class managing the state
/// - `List<Game>` - The type of state being managed
///
/// USAGE:
/// ```dart
/// // In a ConsumerWidget:
/// final games = ref.watch(gamesProvider);  // Gets List<Game>, rebuilds on change
/// ref.read(gamesProvider.notifier).createGame(...);  // Call methods
/// ```
final gamesProvider = StateNotifierProvider<GamesController, List<Game>>((ref) {
  return GamesController(ref);
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIER - Business Logic & State Mutations
// ═══════════════════════════════════════════════════════════════════════════

/// Controller for managing the collection of Spades games.
///
/// RIVERPOD CONCEPT: StateNotifier
/// `StateNotifier<T>` is a class that:
/// - Holds a single piece of state of type `T`
/// - Exposes that state via the `state` getter
/// - Notifies listeners when `state` is reassigned
///
/// KEY PRINCIPLE: Immutable Updates
/// Instead of mutating `state`, we always assign a NEW value:
/// ```dart
/// // ❌ Wrong - mutating existing state
/// state.add(newGame);
///
/// // ✅ Correct - assigning new state
/// state = [...state, newGame];
/// ```
///
/// This ensures Riverpod detects the change and rebuilds widgets.
class GamesController extends StateNotifier<List<Game>> {
  /// Reference to the Riverpod container for accessing other providers.
  ///
  /// DART CONCEPT: Private Fields
  /// The underscore prefix (`_ref`) makes this field private to the library.
  /// It can't be accessed from outside this file.
  final Ref _ref;

  /// Creates the controller and loads initial state from persistence.
  ///
  /// DART CONCEPT: Initializer List
  /// The `: super(...)` syntax is an initializer list - it runs before
  /// the constructor body. Here we initialize the parent class (StateNotifier)
  /// with the initial state loaded from the repository.
  GamesController(this._ref) : super(_ref.read(repoProvider).listGames());

  /// Reloads the game list from persistence.
  ///
  /// Called after mutations to ensure UI reflects persisted state.
  /// This triggers a rebuild of all widgets watching `gamesProvider`.
  void refresh() => state = _ref.read(repoProvider).listGames();

  /// Finds a game by its ID, or returns null if not found.
  ///
  /// DART CONCEPT: Collection Methods
  /// - `.where()` filters the list based on a predicate
  /// - `.firstOrNull` returns the first element or null (Dart 3 feature)
  ///
  /// ALTERNATIVE:
  /// ```dart
  /// state.firstWhere((g) => g.id == id, orElse: () => null);
  /// ```
  Game? byId(String id) => state.where((g) => g.id == id).firstOrNull;

  /// Creates a new game with the given player names.
  ///
  /// DART CONCEPT: Async/Await
  /// The `async` keyword marks this as an asynchronous function.
  /// `await` pauses execution until the Future completes.
  /// The function returns `Future<String>` (the new game's ID).
  ///
  /// PARAMETERS:
  /// - [playerNames]: List of 4 names in order: North, East, South, West
  /// - [config]: Optional scoring configuration (uses defaults if omitted)
  ///
  /// GAME SETUP:
  /// Players are seated N, E, S, W around the table.
  /// Teams are formed by players across from each other:
  /// - Team 1 (NS): North (index 0) + South (index 2)
  /// - Team 2 (EW): East (index 1) + West (index 3)
  Future<String> createGame({
    required List<String> playerNames,
    GameConfig config = const GameConfig(),
  }) async {
    // Generate unique IDs using UUID v4 (random-based)
    final uuid = const Uuid().v4();

    // DART CONCEPT: List.generate
    // Creates a list by calling a function for each index.
    // Here we create 4 Player objects with unique IDs.
    final players = List.generate(
      4,
      (i) => Player(id: const Uuid().v4(), name: playerNames[i]),
    );

    // Create Team 1: North/South (indices 0 and 2)
    final teamNS = Team(
      id: const Uuid().v4(),
      name: '${players[0].name}/${players[2].name}',
      playerIds: [players[0].id, players[2].id],
    );

    // Create Team 2: East/West (indices 1 and 3)
    final teamEW = Team(
      id: const Uuid().v4(),
      name: '${players[1].name}/${players[3].name}',
      playerIds: [players[1].id, players[3].id],
    );

    // Create the game object with empty hands list
    final game = Game(
      id: uuid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      players: players,
      teams: [teamNS, teamEW],
      config: config,
      hands: const [], // DART: Empty const list is more efficient
    );

    // Persist to storage and refresh state
    await _ref.read(repoProvider).upsertGame(game);
    refresh();

    return uuid;
  }

  /// Saves an existing game to persistent storage.
  ///
  /// This is used after modifying a game (adding hands, updating scores).
  Future<void> save(Game game) async {
    await _ref.read(repoProvider).upsertGame(game);
    refresh();
  }

  /// Deletes a game by its ID.
  ///
  /// This removes the game from persistent storage permanently.
  Future<void> delete(String id) async {
    await _ref.read(repoProvider).deleteGame(id);
    refresh();
  }
}
