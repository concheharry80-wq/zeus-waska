import 'package:flutter/material.dart';

enum AppVisualTheme {
  neonNight('Noche Neón', 'Morado eléctrico + Rosa neón'),
  cyberCyan('Ciber Azul', 'Azul eléctrico + Morado'),
  magentaPulse('Pulso Magenta', 'Rosa neón + Azul eléctrico');

  final String label;
  final String subtitle;
  const AppVisualTheme(this.label, this.subtitle);
}

enum IntensityLevel {
  chill(
    'chill',
    'CHILL',
    'Preguntas sencillas y rompehielos',
    Color(0xFF00D9FF),
    Icons.ac_unit_rounded,
  ),
  party(
    'party',
    'PARTY',
    'Retos graciosos y dinámicos',
    Color(0xFF8B3DFF),
    Icons.celebration_rounded,
  ),
  caos(
    'caos',
    'CAOS',
    'Desafíos creativos y situaciones absurdas',
    Color(0xFFFF2D95),
    Icons.auto_awesome_rounded,
  ),
  waska(
    'waska',
    'WASKA',
    'Minijuegos, retos grupales y eventos sorpresa',
    Color(0xFF00E676),
    Icons.bolt_rounded,
  );

  final String key;
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const IntensityLevel(
    this.key,
    this.label,
    this.description,
    this.color,
    this.icon,
  );

  static IntensityLevel fromKey(String k) {
    return IntensityLevel.values.firstWhere(
      (e) => e.key == k,
      orElse: () => IntensityLevel.party,
    );
  }
}

enum ContentCategory {
  rompehielos('rompehielos', 'Rompehielos', '🧊'),
  humor('humor', 'Humor', '😂'),
  confesiones('confesiones', 'Confesiones', '🤫'),
  amistad('amistad', 'Amistad', '🤝'),
  creatividad('creatividad', 'Creatividad', '🎨'),
  competitivo('competitivo', 'Competitivo', '🏆'),
  absurdo('absurdo', 'Absurdo', '🤪'),
  caosDivertido('caos_divertido', 'Caos divertido', '🎉');

  final String key;
  final String label;
  final String emoji;

  const ContentCategory(this.key, this.label, this.emoji);

  static ContentCategory fromKey(String k) {
    return ContentCategory.values.firstWhere(
      (e) => e.key == k,
      orElse: () => ContentCategory.humor,
    );
  }
}

enum GameMode {
  doubleRoulette(
    'double_roulette',
    'Doble Ruleta',
    'Dos ruletas eligen quién cumple y quién propone el reto',
    Icons.track_changes_rounded,
    Color(0xFF8B3DFF),
    2,
  ),
  truthOrDare(
    'truth_or_dare',
    'Verdad o Reto',
    'Elige responder una pregunta divertida o cumplir un reto',
    Icons.psychology_alt_rounded,
    Color(0xFFFF2D95),
    2,
  ),
  neverHaveIEver(
    'never_have_i_ever',
    'Yo Nunca Nunca',
    'Frases cotidianas y graciosas con registro voluntario',
    Icons.pan_tool_alt_rounded,
    Color(0xFF00D9FF),
    2,
  ),
  mostLikely(
    'most_likely',
    '¿Quién es más probable?',
    'Todos votan quién encaja mejor con cada pregunta',
    Icons.how_to_vote_rounded,
    Color(0xFF00E676),
    2,
  ),
  theBomb(
    'the_bomb',
    'La Bomba',
    'Responde rápido y pasa el teléfono antes de que explote',
    Icons.timer_rounded,
    Color(0xFFFF5E3A),
    2,
  ),
  anonymousConfessions(
    'anonymous_confessions',
    'Confesiones Anónimas',
    'Escribe confesiones temporales y adivinen el autor',
    Icons.masks_rounded,
    Color(0xFFE040FB),
    2,
  ),
  duel(
    'duel',
    'Duelo',
    'Dos jugadores compiten en reflejos, memoria y acertijos',
    Icons.sports_esports_rounded,
    Color(0xFFFFB300),
    2,
  ),
  mysteryRoulette(
    'mystery_roulette',
    'Ruleta Misteriosa',
    'Gira para activar uno de 8 eventos sorpresa en la partida',
    Icons.casino_rounded,
    Color(0xFF00D9FF),
    2,
  ),
  fiveSeconds(
    'five_seconds',
    'Cinco Segundos',
    'Menciona 3 cosas de una categoría en solo 5 segundos',
    Icons.speed_rounded,
    Color(0xFFFF2D95),
    2,
  ),
  impostor(
    'impostor',
    'Impostor',
    'Todos conocen la palabra secreta menos uno. ¡Descúbranlo!',
    Icons.visibility_off_rounded,
    Color(0xFF8B3DFF),
    3,
  );

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final int minPlayers;

  const GameMode(
    this.key,
    this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.minPlayers,
  );

  static GameMode fromKey(String k) {
    return GameMode.values.firstWhere(
      (e) => e.key == k,
      orElse: () => GameMode.doubleRoulette,
    );
  }
}

enum SpecialCardType {
  shield(
    'Escudo',
    'Te permite omitir una ronda sin perder puntos.',
    Icons.shield_rounded,
    Color(0xFF00D9FF),
  ),
  doublePoints(
    'Doble Puntuación',
    'El próximo reto completado vale el doble de puntos (+20).',
    Icons.looks_two_rounded,
    Color(0xFF00E676),
  ),
  swapPlayer(
    'Cambio de Jugador',
    'Pasa tu reto actual a otro jugador al azar.',
    Icons.swap_horiz_rounded,
    Color(0xFF8B3DFF),
  ),
  groupChallenge(
    'Reto Grupal',
    '¡Todos los jugadores participan juntos en esta ronda!',
    Icons.groups_rounded,
    Color(0xFFFF2D95),
  ),
  surpriseDuel(
    'Duelo Sorpresa',
    'Desafía inmediatamente a otro jugador por +15 puntos.',
    Icons.flash_on_rounded,
    Color(0xFFFFB300),
  ),
  stealPoints(
    'Robo de Puntos',
    'Toma 10 puntos virtuales del líder actual.',
    Icons.auto_fix_high_rounded,
    Color(0xFFFF5E3A),
  ),
  wildcard(
    'Comodín',
    'Elige libremente a quién asignarle un reto o suma +10 puntos.',
    Icons.star_rounded,
    Color(0xFFE040FB),
  ),
  mysteryRound(
    'Ronda Misteriosa',
    'El premio y la intensidad de esta ronda son aleatorios.',
    Icons.help_center_rounded,
    Color(0xFF00D9FF),
  ),
  freeForAll(
    'Todos Contra Todos',
    '¡Batalla relámpago! Quien responda o cumpla primero suma +15.',
    Icons.local_fire_department_rounded,
    Color(0xFFFF2D95),
  );

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const SpecialCardType(this.title, this.description, this.icon, this.color);
}
