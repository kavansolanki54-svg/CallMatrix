import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_container.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'core/storage/preferences_service.dart';

Future<void> _saveCrashLog(String error, String stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/crash_log.txt');
    await file.writeAsString(
      'Time: ${DateTime.now()}\nError: $error\nStack: $stack\n\n',
      mode: FileMode.append,
    );
  } catch (e) {
    // Ignore
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Ignore missing file in release mode
  }

  // Setup crash logging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _saveCrashLog(details.exceptionAsString(), details.stack.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _saveCrashLog(error.toString(), stack.toString());
    return true;
  };

  runApp(
    const ProviderScope(
      child: CallalyzeApp(),
    ),
  );
}

class CallalyzeApp extends ConsumerStatefulWidget {
  const CallalyzeApp({super.key});

  @override
  ConsumerState<CallalyzeApp> createState() => _CallalyzeAppState();
}

class _CallalyzeAppState extends ConsumerState<CallalyzeApp> {
  @override
  void initState() {
    super.initState();
    // Initialize preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(preferencesProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final prefs = ref.watch(preferencesProvider);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0070F3),
        secondary: Color(0xFF10B981),
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0C111D),
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C111D),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0070F3),
        secondary: Color(0xFF10B981),
        surface: Color(0xFF1D2939),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1D2939),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1D2939),
      ),
    );

    return MaterialApp(
      title: 'Callalyze Mobile',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: prefs.themeMode,
      home: authState.isInitializing
          ? const SplashScreen()
          : authState.isAuthenticated
              ? MainContainer(
                  onLogout: () => ref.read(authProvider.notifier).logout(),
                )
              : LoginScreen(
                  onLoginSuccess: () {},
                ),
    );
  }
}
