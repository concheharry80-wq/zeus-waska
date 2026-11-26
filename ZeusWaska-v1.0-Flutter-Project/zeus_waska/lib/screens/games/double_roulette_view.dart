import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/services/roulette_engine.dart';
import 'package:zeus_waska/core/services/sound_service.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/widgets/neon_widgets.dart';
import 'package:zeus_waska/widgets/roulette_wheel.dart';

class DoubleRouletteView extends ConsumerStatefulWidget {
  final VoidCallback onTriggerConfetti;
  const DoubleRouletteView({super.key, required this.onTriggerConfetti});

  @override
  ConsumerState<DoubleRouletteView> createState() => _DoubleRouletteViewState();
}

class _DoubleRouletteViewState extends ConsumerState<DoubleRouletteView>
    with TickerProviderStateMixin {
  late AnimationController _leftController;
  late AnimationController _rightController;

  double _leftAngle = 0;
  double _rightAngle = 0;
  double _leftStart = 0;
  double _leftTarget = 0;
  double _rightStart = 0;
  double _rightTarget = 0;

  int _lastLeftSeg = -1;
  int _lastRightSeg = -1;

  bool _isSpinning = false;
  DualRouletteResult? _result;
  String? _activeChallengeText;
  bool _isCustomInputOpen = false;
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _leftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(_onLeftTick);

    _rightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addListener(_onRightTick);
  }

  void _onLeftTick() {
    final t = Curves.easeOutCubic.transform(_leftController.value);
    final nextAngle = _leftStart + (_leftTarget - _leftStart) * t;
    final players = ref.read(gameSessionProvider).players;
    if (players.isNotEmpty) {
      final seg = ((nextAngle / (2 * pi)) * players.length).floor();
      if (seg != _lastLeftSeg) {
        _lastLeftSeg = seg;
        ref.read(soundServiceProvider).playSfx(SoundEffect.spinTick);
      }
    }
    setState(() => _leftAngle = nextAngle);
  }

  void _onRightTick() {
    final t = Curves.easeOutCubic.transform(_rightController.value);
    final nextAngle = _rightStart + (_rightTarget - _rightStart) * t;
    final players = ref.read(gameSessionProvider).players;
    if (players.isNotEmpty) {
      final seg = ((nextAngle / (2 * pi)) * players.length).floor();
      if (seg != _lastRightSeg) {
        _lastRightSeg = seg;
        if (!_leftController.isAnimating) {
          ref.read(soundServiceProvider).playSfx(SoundEffect.spinTick);
        }
      }
    }
    setState(() => _rightAngle = nextAngle);
  }

  Future<void> _spinBothWheels() async {
    if (_isSpinning) return;
    final session = ref.read(gameSessionProvider);
    if (session.players.length < 2) return;

    final settings = ref.read(settingsProvider);
    final engine = ref.read(rouletteEngineProvider);
    final sound = ref.read(soundServiceProvider);

    final speedFactor = settings.rouletteSpeed.clamp(0.6, 1.6);
    _leftController.duration =
        Duration(milliseconds: (3000 / speedFactor).round());
    _rightController.duration =
        Duration(milliseconds: (4250 / speedFactor).round());

    final pair = engine.selectBalancedPair(
      session.players,
      lastDoerId: session.lastDoerId,
      lastProposerId: session.lastProposerId,
    );

    _leftStart = _leftAngle;
    _rightStart = _rightAngle;
    _leftTarget = engine.computeTargetAngle(
      totalSegments: session.players.length,
      targetIndex: pair.doerIndex,
      currentAngle: _leftStart,
      extraFullSpins: 5,
    );
    _rightTarget = engine.computeTargetAngle(
      totalSegments: session.players.length,
      targetIndex: pair.proposerIndex,
      currentAngle: _rightStart,
      extraFullSpins: 7,
    );

    setState(() {
      _isSpinning = true;
      _result = null;
      _activeChallengeText = null;
      _isCustomInputOpen = false;
      _customCtrl.clear();
    });

    await sound.vibrateLight();

    // Ambas giran simultáneamente pero se detienen en momentos diferentes
    final leftFuture = _leftController.forward(from: 0).then((_) async {
      await sound.vibrateMedium();
      await sound.playSfx(SoundEffect.playerSelected);
    });
    final rightFuture = _rightController.forward(from: 0);

    await Future.wait([leftFuture, rightFuture]);

    if (!mounted) return;
    await sound.vibrateHeavy();
    await sound.playSfx(SoundEffect.playerSelected);
    await ref
        .read(gameSessionProvider.notifier)
        .recordRouletteSelection(pair.doer.id, pair.proposer.id);

    setState(() {
      _isSpinning = false;
      _result = pair;
    });

    // Posible carta especial automática
    if (settings.specialCardsEnabled) {
      final card = ref.read(gameSessionProvider.notifier).rollSpecialCard();
      if (card != null && mounted) {
        await sound.playSfx(SoundEffect.specialCard);
        await _showAndApplySpecialCard(card, pair.doer.id, pair.doer.name);
      }
    }
  }

  Future<void> _showAndApplySpecialCard(
    SpecialCardType card,
    String doerId,
    String doerName,
  ) async {
    final notifier = ref.read(gameSessionProvider.notifier);
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SpecialCardDialog(
        card: card,
        targetPlayerName: doerName,
      ),
    );
    switch (card) {
      case SpecialCardType.shield:
        await notifier.grantShield(doerId);
        break;
      case SpecialCardType.doublePoints:
        await notifier.activateDoublePoints();
        break;
      case SpecialCardType.stealPoints:
        await notifier.stealPointsFromLeader(doerId);
        break;
      case SpecialCardType.groupChallenge:
        final db = await ref.read(contentDatabaseProvider.future);
        final settings = ref.read(settingsProvider);
        final item = ref.read(contentRepositoryProvider).nextItem(
              source: db.groupChallenges,
              customItems: ref.read(customChallengesProvider),
              customType: 'group',
              intensity: ref.read(gameSessionProvider).intensity,
              enabledCategories: settings.enabledCategories,
            );
        if (mounted) {
          setState(() => _activeChallengeText = 'RETO GRUPAL: ${item.text}');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _generateAutoChallenge() async {
    final db = await ref.read(contentDatabaseProvider.future);
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    final custom = ref.read(customChallengesProvider);
    final ContentItem item = ref.read(contentRepositoryProvider).nextItem(
          source: db.dares,
          customItems: custom,
          customType: 'dare',
          intensity: session.intensity,
          enabledCategories: settings.enabledCategories,
        );
    await ref.read(soundServiceProvider).playSfx(SoundEffect.buttonTap);
    setState(() {
      _activeChallengeText = item.text;
      _isCustomInputOpen = false;
    });
  }

  Future<void> _completeChallenge() async {
    if (_result == null) return;
    await ref
        .read(gameSessionProvider.notifier)
        .completeChallenge(_result!.doer.id);
    await ref.read(soundServiceProvider).playSfx(SoundEffect.victory);
    await ref.read(soundServiceProvider).playSfx(SoundEffect.confetti);
    widget.onTriggerConfetti();
    setState(() {
      _result = null;
      _activeChallengeText = null;
    });
  }

  Future<void> _skipChallenge() async {
    if (_result == null) return;
    final usedShield = _result!.doer.hasShield;
    await ref.read(gameSessionProvider.notifier).skipChallenge(_result!.doer.id);
    await ref.read(soundServiceProvider).playSfx(SoundEffect.defeat);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedShield
                ? '${_result!.doer.name} usó su Escudo y evitó la penalización.'
                : '${_result!.doer.name} pasó el reto (-5 pts virtuales o sorbo de bebida sin alcohol).',
          ),
        ),
      );
    }
    setState(() {
      _result = null;
      _activeChallengeText = null;
    });
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameSessionProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = ((screenWidth - 52) / 2).clamp(124.0, 185.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          if (session.doublePointsActive)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonGreen),
              ),
              child: const Text(
                '⚡ DOBLE PUNTUACIÓN ACTIVA (+20 PTS)',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),

          // DOBLE RULETA LADO A LADO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeonRouletteWheel(
                players: session.players,
                angle: _leftAngle,
                title: 'CUMPLE EL RETO',
                accentColor: AppColors.neonPink,
                highlightedIndex: _result?.doerIndex,
                size: wheelSize,
              ),
              NeonRouletteWheel(
                players: session.players,
                angle: _rightAngle,
                title: 'PROPONE EL RETO',
                accentColor: AppColors.electricBlue,
                highlightedIndex: _result?.proposerIndex,
                size: wheelSize,
              ),
            ],
          ),

          const SizedBox(height: 18),

          NeonButton(
            label: _isSpinning ? 'GIRANDO RULETAS...' : 'GIRAR DOBLE RULETA',
            icon: Icons.casino_rounded,
            onPressed: _isSpinning ? null : _spinBothWheels,
          ),

          if (_result != null) ...[
            const SizedBox(height: 18),
            GlassCard(
              borderColor: AppColors.neonPink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SelectedPlayerBadge(
                          role: 'CUMPLE',
                          name: _result!.doer.name,
                          avatar: _result!.doer.avatar,
                          color: AppColors.neonPink,
                          hasShield: _result!.doer.hasShield,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.bolt_rounded,
                          color: AppColors.warningAmber,
                        ),
                      ),
                      Expanded(
                        child: _SelectedPlayerBadge(
                          role: 'PROPONE',
                          name: _result!.proposer.name,
                          avatar: _result!.proposer.avatar,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_result!.doer.name} deberá realizar el reto.\n${_result!.proposer.name} se encarga de proponerlo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_activeChallengeText == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            label: 'Reto Automático',
                            icon: Icons.auto_awesome_rounded,
                            height: 46,
                            colors: const [
                              AppColors.electricPurple,
                              AppColors.electricBlue,
                            ],
                            onPressed: _generateAutoChallenge,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: const BorderSide(color: AppColors.neonPink),
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              setState(() =>
                                  _isCustomInputOpen = !_isCustomInputOpen);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text(
                              'Escribir',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isCustomInputOpen) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              '${_result!.proposer.name}, escribe un reto divertido y seguro...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      NeonButton(
                        label: 'Lanzar reto personalizado',
                        height: 44,
                        onPressed: () {
                          final txt = _customCtrl.text.trim();
                          if (txt.isEmpty) return;
                          setState(() {
                            _activeChallengeText = txt;
                            _isCustomInputOpen = false;
                          });
                        },
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.electricBlue.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        _activeChallengeText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NeonButton(
                      label: '¡Reto Completado! (+10 pts)',
                      icon: Icons.check_circle_rounded,
                      colors: const [AppColors.neonGreen, Color(0xFF00B25A)],
                      onPressed: _completeChallenge,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: const BorderSide(
                                color: AppColors.electricBlue,
                              ),
                              foregroundColor: AppColors.electricBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _generateAutoChallenge,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Otro reto'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: const BorderSide(color: AppColors.dangerRed),
                              foregroundColor: AppColors.dangerRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _skipChallenge,
                            icon: const Icon(Icons.skip_next_rounded, size: 18),
                            label: Text(
                              _result!.doer.hasShield
                                  ? 'Usar Escudo'
                                  : 'Pasar (-5)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedPlayerBadge extends StatelessWidget {
  final String role;
  final String name;
  final String avatar;
  final Color color;
  final bool hasShield;

  const _SelectedPlayerBadge({
    required this.role,
    required this.name,
    required this.avatar,
    required this.color,
    this.hasShield = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Text(
            role,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(avatar, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          if (hasShield)
            const Text(
              '🛡️ Escudo',
              style: TextStyle(color: AppColors.electricBlue, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
