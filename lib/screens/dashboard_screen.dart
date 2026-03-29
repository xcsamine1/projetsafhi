import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../widgets/seance_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'attendance_screen.dart';
import 'session_list_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'create_seance_screen.dart';
import 'admin_data_screen.dart';

/// Main screen after login.
/// Shows today's sessions + bottom navigation bar.
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;

  const DashboardScreen({super.key, this.onToggleTheme, this.themeMode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    await context.read<SeanceProvider>().loadSeances(
          profId: authProvider.professor?.idProf ?? 1,
          token: authProvider.token,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navIndex == 0 ? 'Tableau de bord' : 'Toutes les séances'),
        actions: [
          // Dark / light toggle
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDark ? 'Mode clair' : 'Mode sombre',
              onPressed: widget.onToggleTheme,
            ),
          // Options menu
          PopupMenuButton<String>(
            onSelected: (v) async {

              if (v == 'logout') {
                await auth.logout();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else if (v == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (v == 'admin_data') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDataScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'admin_data',
                child: Row(children: [
                  Icon(Icons.storage_rounded),
                  SizedBox(width: 8),
                  Text('Gestion des données'),
                ]),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Déconnexion'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: _navIndex == 0
          ? _DashboardBody(onRefresh: _loadData)
          : const SessionListScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Séances',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSeanceScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Séance'),
      ),
    );
  }
}

// ─── Dashboard Body ──────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _DashboardBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final seanceProvider = context.watch<SeanceProvider>();
    final auth = context.watch<AuthProvider>();

    if (seanceProvider.isLoading) {
      return const LoadingOverlay(message: 'Chargement des séances...');
    }
    if (seanceProvider.error != null) {
      return AppErrorWidget(
        message: seanceProvider.error!,
        onRetry: onRefresh,
      );
    }

    final todaySeances = seanceProvider.todaySeances;
    final today =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // ── Greeting banner ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${auth.professor?.prenom ?? ''} 👋',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    today,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatBadge(
                        label: '${todaySeances.length}',
                        sub: "Séances\naujourd'hui",
                        color: cs.onPrimary,
                      ),
                      const SizedBox(width: 24),
                      _StatBadge(
                        label: '${seanceProvider.allSeances.length}',
                        sub: 'Total\nséances',
                        color: cs.onPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Section header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                "Séances d'aujourd'hui",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ── List or empty state ─────────────────────────────────────────
          if (todaySeances.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.event_busy_rounded,
                text: "Aucune séance aujourd'hui",
                color: cs.onSurfaceVariant,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final seance = todaySeances[i];
                  return SeanceCard(
                    seance: seance,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScreen(seance: seance),
                      ),
                    ),
                  );
                },
                childCount: todaySeances.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Stat Badge ───────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;

  const _StatBadge(
      {required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 28)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _EmptyState(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(children: [
        Icon(icon, size: 72, color: color.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 15)),
      ]),
    );
  }
}
