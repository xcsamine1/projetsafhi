import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/seance_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/etudiant_service.dart';
import 'services/presence_service.dart';
import 'services/seance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize French locale data for date formatting
  await initializeDateFormatting('fr_FR', null);
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  /// Tracks dark/light mode toggle — persisted per session.
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Shared service singletons ─────────────────────────────────────────────
    final apiService = ApiService();
    final authService = AuthService(apiService);
    final seanceService = SeanceService(apiService);
    final etudiantService = EtudiantService(apiService);
    final presenceService = PresenceService(apiService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => SeanceProvider(seanceService)),
        ChangeNotifierProvider(
          create: (_) => PresenceProvider(etudiantService, presenceService),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: _AppRoot(
          onToggleTheme: toggleTheme,
          themeMode: _themeMode,
        ),
      ),
    );
  }
}

/// Root widget that decides whether to show [LoginScreen] or [DashboardScreen].
/// Passes [onToggleTheme] down so the Dashboard can surface the toggle button.
class _AppRoot extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const _AppRoot({required this.onToggleTheme, required this.themeMode});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    // Try auto-login from persisted token
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!AppConfig.useDummyData) {
        await context.read<AuthProvider>().tryRestoreSession();
      }
      if (mounted) setState(() => _restoringSession = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restoringSession) {
      // Splash while restoring session
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    if (isAuthenticated) {
      return DashboardScreen(
        onToggleTheme: widget.onToggleTheme,
        themeMode: widget.themeMode,
      );
    }
    return const LoginScreen();
  }
}
