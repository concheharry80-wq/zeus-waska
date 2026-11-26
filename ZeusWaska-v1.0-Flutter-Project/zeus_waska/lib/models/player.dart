import 'package:flutter/material.dart';

class Player {
  final String id;
  final String name;
  final String avatar;
  final int colorValue;
  final int score;
  final int challengesCompleted;
  final int challengesSkipped;
  final int minigameWins;
  final bool hasShield;
  final int timesSelectedAsDoer;
  final int timesSelectedAsProposer;

  const Player({
    required this.id,
    required this.name,
    required this.avatar,
    required this.colorValue,
    this.score = 0,
    this.challengesCompleted = 0,
    this.challengesSkipped = 0,
    this.minigameWins = 0,
    this.hasShield = false,
    this.timesSelectedAsDoer = 0,
    this.timesSelectedAsProposer = 0,
  });

  Color get color => Color(colorValue);

  Player copyWith({
    String? id,
    String? name,
    String? avatar,
    int? colorValue,
    int? score,
    int? challengesCompleted,
    int? challengesSkipped,
    int? minigameWins,
    bool? hasShield,
    int? timesSelectedAsDoer,
    int? timesSelectedAsProposer,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      colorValue: colorValue ?? this.colorValue,
      score: score ?? this.score,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      challengesSkipped: challengesSkipped ?? this.challengesSkipped,
      minigameWins: minigameWins ?? this.minigameWins,
      hasShield: hasShield ?? this.hasShield,
      timesSelectedAsDoer: timesSelectedAsDoer ?? this.timesSelectedAsDoer,
      timesSelectedAsProposer:
          timesSelectedAsProposer ?? this.timesSelectedAsProposer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'colorValue': colorValue,
        'score': score,
        'challengesCompleted': challengesCompleted,
        'challengesSkipped': challengesSkipped,
        'minigameWins': minigameWins,
        'hasShield': hasShield,
        'timesSelectedAsDoer': timesSelectedAsDoer,
        'timesSelectedAsProposer': timesSelectedAsProposer,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: (json['avatar'] as String?) ?? '🎧',
        colorValue: (json['colorValue'] as int?) ?? 0xFF8B3DFF,
        score: (json['score'] as int?) ?? 0,
        challengesCompleted: (json['challengesCompleted'] as int?) ?? 0,
        challengesSkipped: (json['challengesSkipped'] as int?) ?? 0,
        minigameWins: (json['minigameWins'] as int?) ?? 0,
        hasShield: (json['hasShield'] as bool?) ?? false,
        timesSelectedAsDoer: (json['timesSelectedAsDoer'] as int?) ?? 0,
        timesSelectedAsProposer: (json['timesSelectedAsProposer'] as int?) ?? 0,
      );
}
