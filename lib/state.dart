import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import 'game_repository.dart';
import 'models.dart';

final repoProvider = Provider<GameRepository>((ref) => GameRepository());

final gamesProvider = StateNotifierProvider<GamesController, List<Game>>((ref) {
  return GamesController(ref);
});

class GamesController extends StateNotifier<List<Game>> {
  final Ref _ref;

  GamesController(this._ref) : super(_ref.read(repoProvider).listGames());

  void refresh() => state = _ref.read(repoProvider).listGames();

  Game? byId(String id) => state.where((g) => g.id == id).firstOrNull;

  Future<String> createGame({
    required List<String> playerNames,
    GameConfig config = const GameConfig(),
  }) async {
    final uuid = const Uuid().v4();
    final players = List.generate(
      4,
      (i) => Player(id: const Uuid().v4(), name: playerNames[i]),
    );
    final teamNS = Team(
      id: const Uuid().v4(),
      name: '${players[0].name}/${players[2].name}',
      playerIds: [players[0].id, players[2].id],
    );
    final teamEW = Team(
      id: const Uuid().v4(),
      name: '${players[1].name}/${players[3].name}',
      playerIds: [players[1].id, players[3].id],
    );

    final game = Game(
      id: uuid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      players: players,
      teams: [teamNS, teamEW],
      config: config,
      hands: const [],
    );

    await _ref.read(repoProvider).upsertGame(game);
    refresh();
    return uuid;
  }

  Future<void> save(Game game) async {
    await _ref.read(repoProvider).upsertGame(game);
    refresh();
  }

  Future<void> delete(String id) async {
    await _ref.read(repoProvider).deleteGame(id);
    refresh();
  }
}
