import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zeus_waska/core/theme/app_theme.dart';
import 'package:zeus_waska/providers/app_providers.dart';
import 'package:zeus_waska/screens/home/home_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: ZeusWaskaApp()));
}

class ZeusWaskaApp extends ConsumerWidget {
  const ZeusWaskaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Precarga de base de datos offline en segundo plano
    ref.watch(contentDatabaseProvider);

    return MaterialApp(
      title: 'ZEUS WASKA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(settings.visualTheme),
      home: const HomeShellScreen(),
    );
  }
}
