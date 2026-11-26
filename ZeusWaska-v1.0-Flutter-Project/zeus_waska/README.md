# ZEUS WASKA — Aplicación Android de Juegos de Fiesta (Flutter)

**ZEUS WASKA** es una aplicación Android 100% offline desarrollada en **Flutter y Dart** para reuniones y fiestas entre amigos. Cuenta con estética nocturna neón (`#0A0A12`, `#8B3DFF`, `#FF2D95`, `#00D9FF`, `#00E676`), mecánica principal de **Doble Ruleta** con selección equilibrada, **10 modos de juego**, **9 cartas especiales animadas**, **1,445 elementos de contenido offline**, efectos de sonido originales sin copyright y guardado automático de partidas.

---

## Características principales

1. **Doble Ruleta (Mecánica central)**:
   - Dos ruletas animadas lado a lado con `CustomPainter` y `AnimationController`.
   - Giran simultáneamente y se detienen en tiempos distintos para generar suspenso.
   - Garantiza matemáticamente que nunca seleccione a la misma persona en ambas ruletas y balancea las apariciones para evitar repeticiones excesivas.
2. **Sistema de Jugadores (2 a 30 personas)**:
   - Nombre/apodo, 24 avatares, 12 colores neón, puntaje, retos completados/omitidos y victorias en minijuegos.
   - Edición, incorporación y eliminación de jugadores en medio de la partida.
   - Guardado automático de grupos para futuras reuniones.
3. **10 Modos de Juego Completos**:
   - `1. Doble Ruleta` · `2. Verdad o Reto` · `3. Yo Nunca Nunca` · `4. ¿Quién es más probable?` · `5. La Bomba` · `6. Confesiones Anónimas` (efímeras, jamás se guardan al cerrar) · `7. Duelo` (Reflejos, Memoria y Adivinanzas) · `8. Ruleta Misteriosa` (8 eventos) · `9. Cinco Segundos` · `10. Impostor`.
4. **Base de Datos Offline (1,445 elementos únicos en español)**:
   - 265 retos divertidos · 255 preguntas de verdad · 205 frases de Yo nunca nunca · 155 preguntas de ¿Quién es más probable? · 155 preguntas de Cinco segundos · 205 palabras para Impostor · 105 retos grupales · 55 categorías de La Bomba · 45 adivinanzas para Duelo.
   - 8 categorías + 4 niveles de intensidad (`CHILL`, `PARTY`, `CAOS`, `WASKA`) + editor CRUD de retos personalizados.
5. **Estadísticas, Ranking y Compartir Imagen**:
   - Resumen animado al cierre de partida con Ganador de la noche, Más competitivo, Maestro de retos, Rey de minijuegos y exportación PNG compartible.
6. **Audio y Gráficos Originales**:
   - Logotipo neón original, iconos adaptativos Android (`mipmap-mdpi` a `xxxhdpi` + `anydpi-v26`), pantalla de carga nativa y 11 efectos de sonido `.wav` sintetizados libres de derechos.

---

## Cómo generar el archivo `ZeusWaska-v1.0.apk`

### Opción A — Automática en la nube con GitHub Actions (sin instalar nada)

1. Crea un repositorio en GitHub y sube el contenido descomprimido de este proyecto.
2. Ve a la pestaña **Actions** → selecciona **Build ZEUS WASKA Android APK**.
3. Ejecuta el flujo (o se ejecutará automáticamente al hacer `push` a `main`).
4. Al finalizar (`flutter pub get`, `flutter analyze`, `flutter test` y `flutter build apk --release`), descarga el artefacto **`ZeusWaska-v1.0`** que contiene el archivo **`ZeusWaska-v1.0.apk`**.

### Opción B — Compilación local (Windows / macOS / Linux)

Requisitos: Flutter SDK `3.24+` (recomendado `3.27.4`), Java 17 y Android SDK (API 35).

```bash
cd zeus_waska
flutter pub get
flutter analyze
flutter test
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ZeusWaska-v1.0.apk
```

---

## Instalación en Android (8.0 o superior)

1. Copia **`ZeusWaska-v1.0.apk`** a tu teléfono Android.
2. Ábrelo desde tu gestor de archivos.
3. Si Android lo solicita, habilita **"Instalar aplicaciones desconocidas"** para tu gestor de archivos.
4. Pulsa **Instalar** y disfruta sin necesidad de conexión a Internet ni cuentas.

---

## Instrucciones para futuras actualizaciones

- **Agregar contenido**: Edita `assets/data/content_db.json` manteniendo la estructura JSON (`id`, `text`, `category`, `intensity`).
- **Subir versión**: Actualiza `version: 1.0.0+1` en `pubspec.yaml` y `versionCode` / `versionName` en `android/app/build.gradle.kts`.
- **Publicar en Google Play**: Genera una llave `keystore.jks` con `keytool`, configúrala en `android/app/build.gradle.kts` (`signingConfigs.release`) y compila con `flutter build appbundle --release`.
