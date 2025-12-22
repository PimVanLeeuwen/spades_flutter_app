import 'package:flutter/foundation.dart';

@immutable
class Player {
  final String id;
  final String name;

  const Player({required this.id, required this.name});
}

@immutable
class Team {
  final String id;
  final String name;
  final List<String> playerIds;

  const Team({required this.id, required this.name, required this.playerIds});
}

@immutable
class TeamHandInput {
  final String teamId;
  final List<int> teamBid;
  final int teamBooksWon;

  final List<bool> nilAchieved;

  const TeamHandInput({
    required this.teamId,
    required this.teamBid,
    required this.teamBooksWon,
    required this.nilAchieved,
  });
}

@immutable
class Hand {
  final int index;
  final List<TeamHandInput> teamInputs;

  const Hand({required this.index, required this.teamInputs});
}

@immutable
class GameConfig {
  final int bagsPenalty; // default -100 at 10 bags
  final int nilMade; // +100
  final int nilFailed; // -100

  const GameConfig({
    this.bagsPenalty = -100,
    this.nilMade = 100,
    this.nilFailed = -100,
  });
}

@immutable
class Game {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Player> players; // N,E,S,W order
  final List<Team> teams; // NS and EW
  final GameConfig config;
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