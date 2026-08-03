import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_container.dart';
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
      child: CallMatrixApp(),
    ),
  );
}

class CallMatrixApp extends ConsumerStatefulWidget {
  const CallMatrixApp({super.key});

  @override
  ConsumerState<CallMatrixApp> createState() => _CallMatrixAppState();
}

class _CallMatrixAppState extends ConsumerState<CallMatrixApp> {
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

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C111D),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF465FFF),
        secondary: Color(0xFF10B981),
        surface: Color(0xFF1D2939),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1D2939),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: Color(0xFF1D2939),
      ),
    );

    return MaterialApp(
      title: 'CallMatrix Mobile',
      debugShowCheckedModeBanner: false,
      theme: darkTheme, // Standardized dark executive slate theme
      themeMode: ThemeMode.dark,
      home: authState.isInitializing
          ? const Scaffold(
              backgroundColor: Color(0xFF0C111D),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF465FFF)),
              ),
            )
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
