import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeus_waska/core/services/roulette_engine.dart';
import 'package:zeus_waska/core/services/storage_service.dart';
import 'package:zeus_waska/data/content_repository.dart';
import 'package:zeus_waska/main.dart';
import 'package:zeus_waska/models/content_item.dart';
import 'package:zeus_waska/models/enums.dart';
import 'package:zeus_waska/models/player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DualRouletteEngine', () {
    test('nunca selecciona al mismo jugador en ambas ruletas (2 a 30 jugadores)',
        () {
      final engine = DualRouletteEngine();
      for (final count in [2, 5, 12, 30]) {
        final players = List.generate(
          count,
          (i) => Player(
            id: 'p_$i',
            name: 'Jugador $i',
            avatar: '🎧',
            colorValue: 0xFF8B3DFF,
          ),
        );

        for (int spin = 0; spin < 200; spin++) {
          final result = engine.selectBalancedPair(players);
          expect(result.doer.id, isNot(equals(result.proposer.id)));
          expect(result.doerIndex, isNot(equals(result.proposerIndex)));
        }
      }
    });

    test('lanza error si hay menos de 2 jugadores', () {
      final engine = DualRouletteEngine();
      expect(
        () => engine.selectBalancedPair([
          const Player(
            id: 'solo',
            name: 'Alex',
            avatar: '🎧',
            colorValue: 0xFF8B3DFF,
          ),
        ]),
        throwsStateError,
      );
    });
  });

  group('Base de datos de contenido offline', () {
    test('cumple con los mínimos obligatorios de contenido único', () {
      final file = File('assets/data/content_db.json');
      expect(file.existsSync(), isTrue);
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final db = ContentDatabase.fromJson(map);

      expect(db.dares.length, greaterThanOrEqualTo(250));
      expect(db.truths.length, greaterThanOrEqualTo(250));
      expect(db.neverHaveIEver.length, greaterThanOrEqualTo(200));
      expect(db.mostLikely.length, greaterThanOrEqualTo(150));
      expect(db.fiveSeconds.length, greaterThanOrEqualTo(150));
      expect(db.impostorWords.length, greaterThanOrEqualTo(200));
      expect(db.groupChallenges.length, greaterThanOrEqualTo(100));
    });

    test('ContentRepository evita repeticiones dentro de la misma partida', () {
      final repo = ContentRepository();
      final sample = List.generate(
        10,
        (i) => ContentItem(
          id: 'item_$i',
          text: 'Reto $i',
          category: ContentCategory.humor,
          intensity: IntensityLevel.party,
        ),
      );
      final seen = <String>{};
      for (int i = 0; i < 10; i++) {
        final item = repo.nextItem(
          source: sample,
          intensity: IntensityLevel.party,
          enabledCategories: ContentCategory.values.toSet(),
        );
        expect(seen.add(item.id), isTrue);
      }
    });
  });

  group('Persistencia local y estructura de modos', () {
    test('StorageService guarda y recupera grupos, retos y configuración',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();

      final group = SavedGroup(
        id: 'g1',
        name: 'Amigos de Viernes',
        players: const [
          Player(id: '1', name: 'Alex', avatar: '🎧', colorValue: 0xFF8B3DFF),
          Player(id: '2', name: 'Lucía', avatar: '🔥', colorValue: 0xFFFF2D95),
        ],
        updatedAt: DateTime.now(),
      );
      await storage.saveGroups([group]);
      final loadedGroups = await storage.loadGroups();
      expect(loadedGroups.length, 1);
      expect(loadedGroups.first.players.length, 2);

      const settings = AppSettings(
        visualTheme: AppVisualTheme.cyberCyan,
        soundEnabled: false,
        rouletteSpeed: 1.4,
      );
      await storage.saveSettings(settings);
      final loadedSettings = await storage.loadSettings();
      expect(loadedSettings.visualTheme, AppVisualTheme.cyberCyan);
      expect(loadedSettings.soundEnabled, isFalse);
      expect(loadedSettings.rouletteSpeed, 1.4);
    });

    test('contiene exactamente 10 modos, 4 intensidades, 8 categorías y 9 cartas',
        () {
      expect(GameMode.values.length, 10);
      expect(IntensityLevel.values.length, 4);
      expect(ContentCategory.values.length, 8);
      expect(SpecialCardType.values.length, 9);
    });
  });

  testWidgets('Pantalla principal se renderiza sin errores en teléfonos pequeños',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: ZeusWaskaApp()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('ZEUS WASKA'), findsOneWidget);
    expect(find.text('INICIAR FIESTA'), findsOneWidget);
  });
}
