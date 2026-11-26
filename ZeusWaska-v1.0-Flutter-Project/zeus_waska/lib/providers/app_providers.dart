import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zeus_waska/core/services/roulette_engine.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/services/storage_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/data/content_repository.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/models/player.dart';

const _uuid = Uuid();

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

final contentDatabaseProvider = FutureProvider<ContentDatabase>((ref) async {
  return ref.read(contentRepositoryProvider).load();
});

final rouletteEngineProvider = Provider<DualRouletteEngine>((ref) {
  return DualRouletteEngine();
});

// ================= SETTINGS =================

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;
  final SoundService _sound;

  SettingsNotifier(this._storage, this._sound) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.loadSettings();
    state = loaded;
    _syncSound();
  }

  void _syncSound() {
    _sound.soundEnabled = state.soundEnabled;
    _sound.vibrationEnabled = state.vibrationEnabled;
    _sound.setMusic(state.musicEnabled);
  }

  Future<void> update(AppSettings next) async {
    state = next;
    _syncSound();
    await _storage.saveSettings(next);
  }

  Future<void> toggleCategory(ContentCategory cat) async {
    final next = Set<ContentCategory>.from(state.enabledCategories);
    if (next.contains(cat) && next.length > 1) {
      next.remove(cat);
    } else {
      next.add(cat);
    }
    await update(state.copyWith(enabledCategories: next));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.read(storageServiceProvider),
    ref.read(soundServiceProvider),
  );
});

// ================= CUSTOM CHALLENGES =================

class CustomChallengesNotifier extends StateNotifier<List<CustomChallenge>> {
  final StorageService _storage;

  CustomChallengesNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadCustomChallenges();
  }

  Future<void> add({
    required String type,
    required String text,
    required ContentCategory category,
    required IntensityLevel intensity,
  }) async {
    final item = CustomChallenge(
      id: 'custom_${_uuid.v4()}',
      type: type,
      text: text.trim(),
      category: category,
      intensity: intensity,
    );
    state = [item, ...state];
    await _storage.saveCustomChallenges(state);
  }

  Future<void> updateItem(CustomChallenge updated) async {
    state = [
      for (final item in state) item.id == updated.id ? updated : item,
    ];
    await _storage.saveCustomChallenges(state);
  }

  Future<void> remove(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage.saveCustomChallenges(state);
  }

  Future<void> clearAll() async {
    state = [];
    await _storage.saveCustomChallenges([]);
  }
}

final customChallengesProvider =
    StateNotifierProvider<CustomChallengesNotifier, List<CustomChallenge>>(
        (ref) {
  return CustomChallengesNotifier(ref.read(storageServiceProvider));
});

// ================= SAVED GROUPS =================

class SavedGroupsNotifier extends StateNotifier<List<SavedGroup>> {
  final StorageService _storage;

  SavedGroupsNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadGroups();
  }

  Future<void> saveGroup(String name, List<Player> players) async {
    if (players.length < 2) return;
    final cleanName = name.trim().isEmpty
        ? 'Grupo ${DateTime.now().day}/${DateTime.now().month}'
        : name.trim();
    final existingIdx = state.indexWhere(
      (g) => g.name.toLowerCase() == cleanName.toLowerCase(),
    );
    final resetPlayers = players
        .map((p) => p.copyWith(
              score: 0,
              challengesCompleted: 0,
              challengesSkipped: 0,
              minigameWins: 0,
              hasShield: false,
              timesSelectedAsDoer: 0,
              timesSelectedAsProposer: 0,
            ))
        .toList();

    final group = SavedGroup(
      id: existingIdx >= 0 ? state[existingIdx].id : _uuid.v4(),
      name: cleanName,
      players: resetPlayers,
      updatedAt: DateTime.now(),
    );

    if (existingIdx >= 0) {
      final copy = [...state];
      copy[existingIdx] = group;
      state = copy;
    } else {
      state = [group, ...state];
    }
    await _storage.saveGroups(state);
  }

  Future<void> deleteGroup(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _storage.saveGroups(state);
  }

  Future<void> clearAll() async {
    state = [];
    await _storage.saveGroups([]);
  }
}

final savedGroupsProvider =
    StateNotifierProvider<SavedGroupsNotifier, List<SavedGroup>>((ref) {
  return SavedGroupsNotifier(ref.read(storageServiceProvider));
});

// ================= GAME HISTORY =================

class HistoryNotifier extends StateNotifier<List<GameHistoryEntry>> {
  final StorageService _storage;

  HistoryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadHistory();
  }

  Future<void> addEntry(GameHistoryEntry entry) async {
    state = [entry, ...state];
    await _storage.saveHistory(state);
  }

  Future<void> clearHistory() async {
    state = [];
    await _storage.clearHistoryOnly();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<GameHistoryEntry>>((ref) {
  return HistoryNotifier(ref.read(storageServiceProvider));
});

// ================= ACTIVE GAME SESSION =================

class GameSessionState {
  final bool isActive;
  final String groupName;
  final List<Player> players;
  final IntensityLevel intensity;
  final GameMode currentMode;
  final int roundNumber;
  final DateTime startedAt;
  final bool doublePointsActive;
  final String? lastDoerId;
  final String? lastProposerId;
  final SpecialCardType? activeSpecialCard;

  const GameSessionState({
    this.isActive = false,
    this.groupName = 'Noche ZEUS WASKA',
    this.players = const [],
    this.intensity = IntensityLevel.party,
    this.currentMode = GameMode.doubleRoulette,
    this.roundNumber = 1,
    required this.startedAt,
    this.doublePointsActive = false,
    this.lastDoerId,
    this.lastProposerId,
    this.activeSpecialCard,
  });

  int get durationMinutes {
    final diff = DateTime.now().difference(startedAt).inMinutes;
    return diff < 1 ? 1 : diff;
  }

  List<Player> get sortedByScore {
    final list = [...players];
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  GameSessionState copyWith({
    bool? isActive,
    String? groupName,
    List<Player>? players,
    IntensityLevel? intensity,
    GameMode? currentMode,
    int? roundNumber,
    DateTime? startedAt,
    bool? doublePointsActive,
    String? lastDoerId,
    String? lastProposerId,
    SpecialCardType? activeSpecialCard,
    bool clearSpecialCard = false,
  }) {
    return GameSessionState(
      isActive: isActive ?? this.isActive,
      groupName: groupName ?? this.groupName,
      players: players ?? this.players,
      intensity: intensity ?? this.intensity,
      currentMode: currentMode ?? this.currentMode,
      roundNumber: roundNumber ?? this.roundNumber,
      startedAt: startedAt ?? this.startedAt,
      doublePointsActive: doublePointsActive ?? this.doublePointsActive,
      lastDoerId: lastDoerId ?? this.lastDoerId,
      lastProposerId: lastProposerId ?? this.lastProposerId,
      activeSpecialCard: clearSpecialCard
          ? null
          : (activeSpecialCard ?? this.activeSpecialCard),
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'groupName': groupName,
        'players': players.map((p) => p.toJson()).toList(),
        'intensity': intensity.key,
        'currentMode': currentMode.key,
        'roundNumber': roundNumber,
        'startedAt': startedAt.toIso8601String(),
        'doublePointsActive': doublePointsActive,
        'lastDoerId': lastDoerId,
        'lastProposerId': lastProposerId,
      };

  factory GameSessionState.fromJson(Map<String, dynamic> json) {
    return GameSessionState(
      isActive: (json['isActive'] as bool?) ?? false,
      groupName: (json['groupName'] as String?) ?? 'Noche ZEUS WASKA',
      players: (json['players'] as List<dynamic>? ?? [])
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      intensity:
          IntensityLevel.fromKey((json['intensity'] as String?) ?? 'party'),
      currentMode:
          GameMode.fromKey((json['currentMode'] as String?) ?? 'double_roulette'),
      roundNumber: (json['roundNumber'] as int?) ?? 1,
      startedAt: DateTime.tryParse((json['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      doublePointsActive: (json['doublePointsActive'] as bool?) ?? false,
      lastDoerId: json['lastDoerId'] as String?,
      lastProposerId: json['lastProposerId'] as String?,
    );
  }
}

class GameSessionNotifier extends StateNotifier<GameSessionState> {
  final StorageService _storage;
  final SavedGroupsNotifier _groupsNotifier;
  final HistoryNotifier _historyNotifier;
  final ContentRepository _contentRepo;
  final Random _random = Random();

  GameSessionNotifier(
    this._storage,
    this._groupsNotifier,
    this._historyNotifier,
    this._contentRepo,
  ) : super(GameSessionState(startedAt: DateTime.now())) {
    _recoverSession();
  }

  Future<void> _recoverSession() async {
    final saved = await _storage.loadActiveSession();
    if (saved != null) {
      final parsed = GameSessionState.fromJson(saved);
      if (parsed.isActive && parsed.players.length >= 2) {
        state = parsed;
      }
    }
  }

  Future<void> _persist() async {
    if (state.isActive) {
      await _storage.saveActiveSession(state.toJson());
    } else {
      await _storage.saveActiveSession(null);
    }
  }

  Future<void> startNewParty({
    required List<Player> players,
    required IntensityLevel intensity,
    GameMode initialMode = GameMode.doubleRoulette,
    String groupName = 'Noche ZEUS WASKA',
  }) async {
    _contentRepo.resetUsedInSession();
    final freshPlayers = players
        .map((p) => p.copyWith(
              score: 0,
              challengesCompleted: 0,
              challengesSkipped: 0,
              minigameWins: 0,
              hasShield: false,
              timesSelectedAsDoer: 0,
              timesSelectedAsProposer: 0,
            ))
        .toList();

    state = GameSessionState(
      isActive: true,
      groupName: groupName,
      players: freshPlayers,
      intensity: intensity,
      currentMode: initialMode,
      roundNumber: 1,
      startedAt: DateTime.now(),
      doublePointsActive: false,
    );

    await _groupsNotifier.saveGroup(groupName, freshPlayers);
    await _persist();
  }

  Future<void> setMode(GameMode mode) async {
    state = state.copyWith(currentMode: mode);
    await _persist();
  }

  Future<void> setIntensity(IntensityLevel level) async {
    state = state.copyWith(intensity: level);
    await _persist();
  }

  Future<void> addPlayerMidGame(String name, String avatar, int colorValue) async {
    if (state.players.length >= 30) return;
    final clean = name.trim();
    if (clean.isEmpty) return;
    final player = Player(
      id: _uuid.v4(),
      name: clean,
      avatar: avatar,
      colorValue: colorValue,
    );
    state = state.copyWith(players: [...state.players, player]);
    await _groupsNotifier.saveGroup(state.groupName, state.players);
    await _persist();
  }

  Future<void> editPlayerMidGame(Player updated) async {
    state = state.copyWith(
      players: [
        for (final p in state.players) p.id == updated.id ? updated : p,
      ],
    );
    await _groupsNotifier.saveGroup(state.groupName, state.players);
    await _persist();
  }

  Future<void> removePlayerMidGame(String playerId) async {
    if (state.players.length <= 2) return;
    state = state.copyWith(
      players: state.players.where((p) => p.id != playerId).toList(),
    );
    await _persist();
  }

  Future<void> recordRouletteSelection(String doerId, String proposerId) async {
    state = state.copyWith(
      lastDoerId: doerId,
      lastProposerId: proposerId,
      players: [
        for (final p in state.players)
          if (p.id == doerId)
            p.copyWith(timesSelectedAsDoer: p.timesSelectedAsDoer + 1)
          else if (p.id == proposerId)
            p.copyWith(timesSelectedAsProposer: p.timesSelectedAsProposer + 1)
          else
            p,
      ],
    );
    await _persist();
  }

  Future<void> completeChallenge(String playerId, {int basePoints = 10}) async {
    final pts = state.doublePointsActive ? basePoints * 2 : basePoints;
    state = state.copyWith(
      roundNumber: state.roundNumber + 1,
      doublePointsActive: false,
      clearSpecialCard: true,
      players: [
        for (final p in state.players)
          p.id == playerId
              ? p.copyWith(
                  score: p.score + pts,
                  challengesCompleted: p.challengesCompleted + 1,
                )
              : p,
      ],
    );
    await _persist();
  }

  Future<void> skipChallenge(String playerId, {int penalty = 5}) async {
    state = state.copyWith(
      roundNumber: state.roundNumber + 1,
      doublePointsActive: false,
      clearSpecialCard: true,
      players: [
        for (final p in state.players)
          if (p.id == playerId)
            p.hasShield
                ? p.copyWith(hasShield: false)
                : p.copyWith(
                    score: max(0, p.score - penalty),
                    challengesSkipped: p.challengesSkipped + 1,
                  )
          else
            p,
      ],
    );
    await _persist();
  }

  Future<void> awardPoints(
    String playerId,
    int delta, {
    bool isMinigameWin = false,
    bool advanceRound = true,
  }) async {
    final multiplier = (delta > 0 && state.doublePointsActive) ? 2 : 1;
    final actualDelta = delta * multiplier;
    state = state.copyWith(
      roundNumber: advanceRound ? state.roundNumber + 1 : state.roundNumber,
      doublePointsActive: delta > 0 ? false : state.doublePointsActive,
      clearSpecialCard: advanceRound,
      players: [
        for (final p in state.players)
          p.id == playerId
              ? p.copyWith(
                  score: max(0, p.score + actualDelta),
                  minigameWins:
                      isMinigameWin ? p.minigameWins + 1 : p.minigameWins,
                )
              : p,
      ],
    );
    await _persist();
  }

  Future<void> grantShield(String playerId) async {
    state = state.copyWith(
      players: [
        for (final p in state.players)
          p.id == playerId ? p.copyWith(hasShield: true) : p,
      ],
    );
    await _persist();
  }

  Future<void> activateDoublePoints() async {
    state = state.copyWith(doublePointsActive: true);
    await _persist();
  }

  Future<void> stealPointsFromLeader(String beneficiaryId,
      {int amount = 10}) async {
    final sorted = state.sortedByScore;
    if (sorted.isEmpty) return;
    final leader = sorted.firstWhere(
      (p) => p.id != beneficiaryId,
      orElse: () => sorted.first,
    );
    if (leader.id == beneficiaryId) return;
    final stolen = min(amount, leader.score);
    state = state.copyWith(
      players: [
        for (final p in state.players)
          if (p.id == leader.id)
            p.copyWith(score: max(0, p.score - stolen))
          else if (p.id == beneficiaryId)
            p.copyWith(score: p.score + (stolen == 0 ? 5 : stolen))
          else
            p,
      ],
    );
    await _persist();
  }

  Future<void> swapPointsBetween(String playerAId, String playerBId) async {
    final a = state.players.firstWhere((p) => p.id == playerAId);
    final b = state.players.firstWhere((p) => p.id == playerBId);
    state = state.copyWith(
      players: [
        for (final p in state.players)
          if (p.id == playerAId)
            p.copyWith(score: b.score)
          else if (p.id == playerBId)
            p.copyWith(score: a.score)
          else
            p,
      ],
    );
    await _persist();
  }

  SpecialCardType? rollSpecialCard({bool force = false}) {
    // 25% probabilidad por ronda normal o 40% en modo WASKA
    final chance = state.intensity == IntensityLevel.waska ? 0.40 : 0.24;
    if (!force && _random.nextDouble() > chance) return null;
    final card =
        SpecialCardType.values[_random.nextInt(SpecialCardType.values.length)];
    state = state.copyWith(activeSpecialCard: card);
    return card;
  }

  Future<void> clearSpecialCard() async {
    state = state.copyWith(clearSpecialCard: true);
    await _persist();
  }

  Future<void> advanceRoundOnly() async {
    state = state.copyWith(
      roundNumber: state.roundNumber + 1,
      clearSpecialCard: true,
    );
    await _persist();
  }

  Future<GameHistoryEntry> finishParty() async {
    final standings = state.sortedByScore;
    final winner = standings.isNotEmpty
        ? standings.first
        : Player(
            id: 'none',
            name: 'Empate',
            avatar: '🏆',
            colorValue: AppColors.electricPurple.toARGB32(),
          );
    final entry = GameHistoryEntry(
      id: _uuid.v4(),
      playedAt: DateTime.now(),
      durationMinutes: state.durationMinutes,
      totalRounds: state.roundNumber,
      intensity: state.intensity,
      winnerName: winner.name,
      winnerScore: winner.score,
      finalStandings: standings,
    );

    await _historyNotifier.addEntry(entry);
    state = GameSessionState(startedAt: DateTime.now(), isActive: false);
    await _persist();
    return entry;
  }

  Future<void> abandonSession() async {
    state = GameSessionState(startedAt: DateTime.now(), isActive: false);
    await _persist();
  }
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSessionState>((ref) {
  return GameSessionNotifier(
    ref.read(storageServiceProvider),
    ref.read(savedGroupsProvider.notifier),
    ref.read(historyProvider.notifier),
    ref.read(contentRepositoryProvider),
  );
});
