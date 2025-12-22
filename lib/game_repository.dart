import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

class GameRepository {
  static const _boxName = 'spades_games';
  late final Box<String> _box;

  static final GameRepository _instance = GameRepository._internal();

  GameRepository._internal();

  factory GameRepository() {
    return _instance;
  }

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  // C U - Create/Update
  Future<void> upsertGame(Game game) async {
    await _box.put(game.id, jsonEncode(_toMap(game)));
  }

  // R - Read
  Game? getGame(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _fromMap(jsonDecode(raw));
  }

  // R - Read
  List<Game> listGames() {
    return _box.values.map((raw) => _fromMap(jsonDecode(raw))).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // D - Delete
  Future<void> deleteGame(String id) async {
    await _box.delete(id);
  }

  Map<String, dynamic> _toMap(Game g) => {
    'id': g.id,
    'createdAt': g.createdAt.toIso8601String(),
    'updatedAt': g.updatedAt.toIso8601String(),
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

  Game _fromMap(Map<String, dynamic> m) {
    final players = (m['players'] as List)
        .map((p) => Player(id: p['id'], name: p['name']))
        .toList();
    final teams = (m['teams'] as List)
        .map(
          (t) => Team(
            id: t['id'],
            name: t['name'],
            playerIds: List<String>.from(t['playerIds']),
          ),
        )
        .toList();
    final cfg = m['config'];
    final config = GameConfig(
      bagsPenalty: cfg['bagsPenalty'],
      nilMade: cfg['nilMade'],
      nilFailed: cfg['nilFailed'],
    );
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

    return Game(
      id: m['id'],
      createdAt: DateTime.parse(m['createdAt']),
      updatedAt: DateTime.parse(m['updatedAt']),
      players: players,
      teams: teams,
      config: config,
      hands: hands,
    );
  }
}
