import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/enums.dart';

class ContentDatabase {
  final List<ContentItem> dares;
  final List<ContentItem> truths;
  final List<ContentItem> neverHaveIEver;
  final List<ContentItem> mostLikely;
  final List<ContentItem> fiveSeconds;
  final List<ImpostorWord> impostorWords;
  final List<ContentItem> groupChallenges;
  final List<String> bombPrompts;
  final List<DuelRiddle> duelRiddles;

  const ContentDatabase({
    required this.dares,
    required this.truths,
    required this.neverHaveIEver,
    required this.mostLikely,
    required this.fiveSeconds,
    required this.impostorWords,
    required this.groupChallenges,
    required this.bombPrompts,
    required this.duelRiddles,
  });

  factory ContentDatabase.fromJson(Map<String, dynamic> json) {
    List<ContentItem> parseItems(String key) => (json[key] as List<dynamic>)
        .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ContentDatabase(
      dares: parseItems('dares'),
      truths: parseItems('truths'),
      neverHaveIEver: parseItems('neverHaveIEver'),
      mostLikely: parseItems('mostLikely'),
      fiveSeconds: parseItems('fiveSeconds'),
      impostorWords: (json['impostorWords'] as List<dynamic>)
          .map((e) => ImpostorWord.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupChallenges: parseItems('groupChallenges'),
      bombPrompts: (json['bombPrompts'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['text'] as String)
          .toList(),
      duelRiddles: (json['duelRiddles'] as List<dynamic>)
          .map((e) => DuelRiddle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ContentRepository {
  ContentDatabase? _db;
  final Set<String> _usedIds = {};
  final Random _random = Random();

  Future<ContentDatabase> load() async {
    if (_db != null) return _db!;
    final raw = await rootBundle.loadString('assets/data/content_db.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _db = ContentDatabase.fromJson(map);
    return _db!;
  }

  /// Permite inyectar una base de datos directamente (útil en pruebas unitarias).
  void setDatabaseForTest(ContentDatabase db) {
    _db = db;
  }

  void resetUsedInSession() {
    _usedIds.clear();
  }

  ContentItem nextItem({
    required List<ContentItem> source,
    List<CustomChallenge> customItems = const [],
    String? customType,
    required IntensityLevel intensity,
    required Set<ContentCategory> enabledCategories,
  }) {
    final combined = <ContentItem>[
      ...source,
      if (customType != null)
        ...customItems
            .where((c) => c.type == customType)
            .map(
              (c) => ContentItem(
                id: c.id,
                text: c.text,
                category: c.category,
                intensity: c.intensity,
                isCustom: true,
              ),
            ),
    ];

    if (combined.isEmpty) {
      return const ContentItem(
        id: 'fallback_0',
        text: '¡Inventa un reto divertido y seguro para el grupo!',
        category: ContentCategory.creatividad,
        intensity: IntensityLevel.party,
      );
    }

    // 1. Filtrar por categorías habilitadas, intensidad y no usados
    List<ContentItem> pool = combined
        .where((item) =>
            !_usedIds.contains(item.id) &&
            enabledCategories.contains(item.category) &&
            (intensity == IntensityLevel.waska || item.intensity == intensity))
        .toList();

    // 2. Fallback: cualquier intensidad dentro de categorías habilitadas no usadas
    if (pool.isEmpty) {
      pool = combined
          .where((item) =>
              !_usedIds.contains(item.id) &&
              enabledCategories.contains(item.category))
          .toList();
    }

    // 3. Fallback: cualquier ítem no usado
    if (pool.isEmpty) {
      pool = combined.where((item) => !_usedIds.contains(item.id)).toList();
    }

    // 4. Si se agotó todo el pool en la partida, reiniciar solo los IDs de esta lista
    if (pool.isEmpty) {
      for (final item in combined) {
        _usedIds.remove(item.id);
      }
      pool = List<ContentItem>.from(combined);
    }

    final chosen = pool[_random.nextInt(pool.length)];
    _usedIds.add(chosen.id);
    return chosen;
  }

  ImpostorWord nextImpostorWord(ContentDatabase db) {
    var pool = db.impostorWords
        .where((w) => !_usedIds.contains(w.id))
        .toList();
    if (pool.isEmpty) {
      for (final w in db.impostorWords) {
        _usedIds.remove(w.id);
      }
      pool = List<ImpostorWord>.from(db.impostorWords);
    }
    final chosen = pool[_random.nextInt(pool.length)];
    _usedIds.add(chosen.id);
    return chosen;
  }

  String nextBombPrompt(ContentDatabase db) {
    final pool = db.bombPrompts
        .where((p) => !_usedIds.contains('bomb_$p'))
        .toList();
    if (pool.isEmpty) {
      return db.bombPrompts[_random.nextInt(db.bombPrompts.length)];
    }
    final chosen = pool[_random.nextInt(pool.length)];
    _usedIds.add('bomb_$chosen');
    return chosen;
  }

  DuelRiddle nextDuelRiddle(ContentDatabase db) {
    var pool =
        db.duelRiddles.where((r) => !_usedIds.contains(r.id)).toList();
    if (pool.isEmpty) {
      for (final r in db.duelRiddles) {
        _usedIds.remove(r.id);
      }
      pool = List<DuelRiddle>.from(db.duelRiddles);
    }
    final chosen = pool[_random.nextInt(pool.length)];
    _usedIds.add(chosen.id);
    return chosen;
  }
}
