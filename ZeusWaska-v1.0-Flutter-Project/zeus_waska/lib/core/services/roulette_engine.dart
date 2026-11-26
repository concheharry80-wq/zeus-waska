import 'dart:math';
import 'package:zeus_waska/models/player.dart';

class DualRouletteResult {
  final int doerIndex;
  final int proposerIndex;
  final Player doer;
  final Player proposer;

  const DualRouletteResult({
    required this.doerIndex,
    required this.proposerIndex,
    required this.doer,
    required this.proposer,
  });
}

/// Motor equilibrado de Doble Ruleta para ZEUS WASKA.
/// Garantiza matemáticamente que:
/// 1) Nunca se seleccione a la misma persona en ambas ruletas.
/// 2) Se eviten repeticiones excesivas ponderando inversamente el historial de turnos.
class DualRouletteEngine {
  final Random _random;

  DualRouletteEngine([Random? random]) : _random = random ?? Random();

  DualRouletteResult selectBalancedPair(
    List<Player> players, {
    String? lastDoerId,
    String? lastProposerId,
  }) {
    if (players.length < 2) {
      throw StateError(
        'Se necesitan al menos 2 jugadores para girar la Doble Ruleta.',
      );
    }

    // 1. Selección ponderada para Ruleta Izquierda (quien realiza el reto)
    final doerWeights = <double>[];
    for (final p in players) {
      double weight = 1.0 / (1.0 + p.timesSelectedAsDoer * 1.35);
      if (players.length > 2 && p.id == lastDoerId) {
        weight *= 0.20;
      }
      doerWeights.add(weight);
    }
    final doerIndex = _weightedPick(doerWeights);
    final doer = players[doerIndex];

    // 2. Selección ponderada para Ruleta Derecha (quien propone el reto),
    // excluyendo estrictamente al jugador seleccionado en la izquierda.
    final proposerWeights = <double>[];
    for (int i = 0; i < players.length; i++) {
      if (i == doerIndex) {
        proposerWeights.add(0.0);
        continue;
      }
      final p = players[i];
      double weight = 1.0 / (1.0 + p.timesSelectedAsProposer * 1.35);
      if (players.length > 3 && p.id == lastProposerId) {
        weight *= 0.25;
      }
      proposerWeights.add(weight);
    }

    int proposerIndex = _weightedPick(proposerWeights);
    // Salvaguarda absoluta
    if (proposerIndex == doerIndex) {
      proposerIndex = (doerIndex + 1) % players.length;
    }

    return DualRouletteResult(
      doerIndex: doerIndex,
      proposerIndex: proposerIndex,
      doer: doer,
      proposer: players[proposerIndex],
    );
  }

  /// Calcula el ángulo final exacto (en radianes) para que el segmento [targetIndex]
  /// quede alineado con el puntero superior (-pi / 2).
  double computeTargetAngle({
    required int totalSegments,
    required int targetIndex,
    required double currentAngle,
    required int extraFullSpins,
  }) {
    final segmentAngle = (2 * pi) / totalSegments;
    // El centro del segmento targetIndex está en targetIndex * segmentAngle + segmentAngle / 2
    // Queremos que (center + rotation) mod 2pi == -pi/2 (puntero arriba)
    final segmentCenter = (targetIndex + 0.5) * segmentAngle;
    final jitter = (_random.nextDouble() - 0.5) * segmentAngle * 0.45;
    final desiredMod = ((-pi / 2) - segmentCenter + jitter) % (2 * pi);
    final currentMod = currentAngle % (2 * pi);
    double delta = desiredMod - currentMod;
    if (delta < 0) delta += 2 * pi;
    return currentAngle + (extraFullSpins * 2 * pi) + delta;
  }

  int _weightedPick(List<double> weights) {
    final total = weights.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) {
      return _random.nextInt(weights.length);
    }
    double roll = _random.nextDouble() * total;
    for (int i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll <= 0 && weights[i] > 0) {
        return i;
      }
    }
    for (int i = weights.length - 1; i >= 0; i--) {
      if (weights[i] > 0) return i;
    }
    return 0;
  }
}
