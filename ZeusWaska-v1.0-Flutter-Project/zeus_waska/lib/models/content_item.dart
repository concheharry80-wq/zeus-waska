import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/models/player.dart';

class ContentItem {
  final String id;
  final String text;
  final ContentCategory category;
  final IntensityLevel intensity;
  final bool isCustom;

  const ContentItem({
    required this.id,
    required this.text,
    required this.category,
    required this.intensity,
    this.isCustom = false,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json,
      {bool isCustom = false}) {
    return ContentItem(
      id: json['id'] as String,
      text: json['text'] as String,
      category: ContentCategory.fromKey((json['category'] as String?) ?? 'humor'),
      intensity: IntensityLevel.fromKey((json['intensity'] as String?) ?? 'party'),
      isCustom: (json['isCustom'] as bool?) ?? isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category.key,
        'intensity': intensity.key,
        'isCustom': isCustom,
      };
}

class ImpostorWord {
  final String id;
  final String word;
  final String hintCategory;
  final ContentCategory category;
  final IntensityLevel intensity;

  const ImpostorWord({
    required this.id,
    required this.word,
    required this.hintCategory,
    required this.category,
    required this.intensity,
  });

  factory ImpostorWord.fromJson(Map<String, dynamic> json) => ImpostorWord(
        id: json['id'] as String,
        word: json['word'] as String,
        hintCategory: (json['hintCategory'] as String?) ?? 'General',
        category: ContentCategory.fromKey((json['category'] as String?) ?? 'humor'),
        intensity: IntensityLevel.fromKey((json['intensity'] as String?) ?? 'party'),
      );
}

class DuelRiddle {
  final String id;
  final String question;
  final String answer;

  const DuelRiddle({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory DuelRiddle.fromJson(Map<String, dynamic> json) => DuelRiddle(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}

class CustomChallenge {
  final String id;
  final String type; // 'dare' | 'truth' | 'group' | 'neverHaveIEver' | 'mostLikely'
  final String text;
  final ContentCategory category;
  final IntensityLevel intensity;

  const CustomChallenge({
    required this.id,
    required this.type,
    required this.text,
    required this.category,
    required this.intensity,
  });

  CustomChallenge copyWith({
    String? id,
    String? type,
    String? text,
    ContentCategory? category,
    IntensityLevel? intensity,
  }) {
    return CustomChallenge(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      category: category ?? this.category,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'text': text,
        'category': category.key,
        'intensity': intensity.key,
      };

  factory CustomChallenge.fromJson(Map<String, dynamic> json) => CustomChallenge(
        id: json['id'] as String,
        type: (json['type'] as String?) ?? 'dare',
        text: json['text'] as String,
        category: ContentCategory.fromKey((json['category'] as String?) ?? 'humor'),
        intensity: IntensityLevel.fromKey((json['intensity'] as String?) ?? 'party'),
      );
}

class SavedGroup {
  final String id;
  final String name;
  final List<Player> players;
  final DateTime updatedAt;

  const SavedGroup({
    required this.id,
    required this.name,
    required this.players,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players.map((p) => p.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavedGroup.fromJson(Map<String, dynamic> json) => SavedGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        players: (json['players'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
            DateTime.now(),
      );
}

class GameHistoryEntry {
  final String id;
  final DateTime playedAt;
  final int durationMinutes;
  final int totalRounds;
  final IntensityLevel intensity;
  final String winnerName;
  final int winnerScore;
  final List<Player> finalStandings;

  const GameHistoryEntry({
    required this.id,
    required this.playedAt,
    required this.durationMinutes,
    required this.totalRounds,
    required this.intensity,
    required this.winnerName,
    required this.winnerScore,
    required this.finalStandings,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'totalRounds': totalRounds,
        'intensity': intensity.key,
        'winnerName': winnerName,
        'winnerScore': winnerScore,
        'finalStandings': finalStandings.map((p) => p.toJson()).toList(),
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) =>
      GameHistoryEntry(
        id: json['id'] as String,
        playedAt: DateTime.tryParse((json['playedAt'] as String?) ?? '') ??
            DateTime.now(),
        durationMinutes: (json['durationMinutes'] as int?) ?? 1,
        totalRounds: (json['totalRounds'] as int?) ?? 0,
        intensity: IntensityLevel.fromKey((json['intensity'] as String?) ?? 'party'),
        winnerName: (json['winnerName'] as String?) ?? '',
        winnerScore: (json['winnerScore'] as int?) ?? 0,
        finalStandings: (json['finalStandings'] as List<dynamic>)
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AppSettings {
  final AppVisualTheme visualTheme;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final double rouletteSpeed; // 0.6 (lenta) a 1.6 (rápida)
  final int targetRounds; // 10, 20, 30, 50
  final Set<ContentCategory> enabledCategories;
  final bool specialCardsEnabled;

  const AppSettings({
    this.visualTheme = AppVisualTheme.neonNight,
    this.soundEnabled = true,
    this.musicEnabled = false,
    this.vibrationEnabled = true,
    this.rouletteSpeed = 1.0,
    this.targetRounds = 20,
    this.enabledCategories = const {
      ContentCategory.rompehielos,
      ContentCategory.humor,
      ContentCategory.confesiones,
      ContentCategory.amistad,
      ContentCategory.creatividad,
      ContentCategory.competitivo,
      ContentCategory.absurdo,
      ContentCategory.caosDivertido,
    },
    this.specialCardsEnabled = true,
  });

  AppSettings copyWith({
    AppVisualTheme? visualTheme,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    double? rouletteSpeed,
    int? targetRounds,
    Set<ContentCategory>? enabledCategories,
    bool? specialCardsEnabled,
  }) {
    return AppSettings(
      visualTheme: visualTheme ?? this.visualTheme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      rouletteSpeed: rouletteSpeed ?? this.rouletteSpeed,
      targetRounds: targetRounds ?? this.targetRounds,
      enabledCategories: enabledCategories ?? this.enabledCategories,
      specialCardsEnabled: specialCardsEnabled ?? this.specialCardsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'visualTheme': visualTheme.name,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'vibrationEnabled': vibrationEnabled,
        'rouletteSpeed': rouletteSpeed,
        'targetRounds': targetRounds,
        'enabledCategories': enabledCategories.map((e) => e.key).toList(),
        'specialCardsEnabled': specialCardsEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawCats = json['enabledCategories'] as List<dynamic>?;
    final parsedCats = rawCats == null || rawCats.isEmpty
        ? ContentCategory.values.toSet()
        : rawCats.map((e) => ContentCategory.fromKey(e as String)).toSet();

    return AppSettings(
      visualTheme: AppVisualTheme.values.firstWhere(
        (t) => t.name == json['visualTheme'],
        orElse: () => AppVisualTheme.neonNight,
      ),
      soundEnabled: (json['soundEnabled'] as bool?) ?? true,
      musicEnabled: (json['musicEnabled'] as bool?) ?? false,
      vibrationEnabled: (json['vibrationEnabled'] as bool?) ?? true,
      rouletteSpeed: ((json['rouletteSpeed'] as num?) ?? 1.0).toDouble(),
      targetRounds: (json['targetRounds'] as int?) ?? 20,
      enabledCategories: parsedCats,
      specialCardsEnabled: (json['specialCardsEnabled'] as bool?) ?? true,
    );
  }
}
