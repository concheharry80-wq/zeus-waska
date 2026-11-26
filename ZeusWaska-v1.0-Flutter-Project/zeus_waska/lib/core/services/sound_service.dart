import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum SoundEffect {
  spinTick('audio/spin_tick.wav'),
  playerSelected('audio/player_selected.wav'),
  countdownTick('audio/countdown_tick.wav'),
  buttonTap('audio/button_tap.wav'),
  victory('audio/victory.wav'),
  defeat('audio/defeat.wav'),
  surpriseEvent('audio/surprise_event.wav'),
  confetti('audio/confetti.wav'),
  specialCard('audio/special_card.wav'),
  bombExplosion('audio/bomb_explosion.wav');

  final String assetPath;
  const SoundEffect(this.assetPath);
}

class SoundService {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool soundEnabled = true;
  bool musicEnabled = false;
  bool vibrationEnabled = true;

  Future<void> playSfx(SoundEffect effect) async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(effect.assetPath));
    } catch (_) {
      // Silencio seguro en entornos sin hardware de audio (ej. tests)
    }
  }

  Future<void> setMusic(bool enabled) async {
    musicEnabled = enabled;
    try {
      if (enabled) {
        await _musicPlayer.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer.setVolume(0.35);
        await _musicPlayer.play(AssetSource('audio/ambient_party.wav'));
      } else {
        await _musicPlayer.stop();
      }
    } catch (_) {}
  }

  Future<void> vibrateLight() async {
    if (!vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> vibrateMedium() async {
    if (!vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  Future<void> vibrateHeavy() async {
    if (!vibrationEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _sfxPlayer.dispose();
      await _musicPlayer.dispose();
    } catch (_) {}
  }
}
