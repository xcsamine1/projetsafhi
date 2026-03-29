import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../widgets/seance_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'attendance_screen.dart';
import 'session_list_screen.dart';
import 'create_seance_screen.dart';
import 'admin_data_screen.dart';
import 'login_screen.dart';

/// Main shell with side navigation rail matching the ESTC 2025 dashboard design.
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
    final auth = context.read<AuthProvider>();
    await context.read<SeanceProvider>().loadSeances(
          profId: auth.professor?.idProf ?? 1,
          token: auth.token,
        );
  }

  final _labels = ['Tableau de bord', 'Séances'];
  final _icons = [Icons.dashboard_outlined, Icons.calendar_month_outlined];
  final _selectedIcons = [Icons.dashboard_rounded, Icons.calendar_month_rounded];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prof = auth.professor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final initials = prof != null
        ? '${prof.prenom[0]}${prof.nom[0]}'.toUpperCase()
        : 'AS';
    final fullName = prof != null ? '${prof.prenom} ${prof.nom}' : '';
    final email = prof?.email ?? '';

    return Scaffold(
      body: Row(
        children: [
          // ── Dark Sidebar ────────────────────────────────────────────────
          _Sidebar(
            navIndex: _navIndex,
            labels: _labels,
            icons: _icons,
            selectedIcons: _selectedIcons,
            initials: initials,
            fullName: fullName,
            email: email,
            isDark: isDark,
            onToggleTheme: widget.onToggleTheme,
            onNavChanged: (i) => setState(() => _navIndex = i),
            onAdminData: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminDataScreen())),
            onLogout: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          // ── Main Content ────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                _DashboardBody(onRefresh: _loadData),
                const SessionListScreen(),
              ],
            ),
          ),
        ],
      ),
      // FAB for creating new session
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSeanceScreen()),
        ),
        backgroundColor: AppColors.seed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Séance'),
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int navIndex;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final String initials;
  final String fullName;
  final String email;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<int> onNavChanged;
  final VoidCallback onAdminData;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.navIndex,
    required this.labels,
    required this.icons,
    required this.selectedIcons,
    required this.initials,
    required this.fullName,
    required this.email,
    required this.isDark,
    required this.onToggleTheme,
    required this.onNavChanged,
    required this.onAdminData,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sidebarAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTC 2025',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Gestion des présences',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),

            // ── Nav Items ─────────────────────────────────────────────────
            ...List.generate(labels.length, (i) {
              final selected = navIndex == i;
              return _NavItem(
                icon: selected ? selectedIcons[i] : icons[i],
                label: labels[i],
                selected: selected,
                onTap: () => onNavChanged(i),
              );
            }),

            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // ── Theme toggle ─────────────────────────────────────────────
            _SidebarAction(
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              label: isDark ? 'Mode clair' : 'Mode sombre',
              onTap: onToggleTheme ?? () {},
            ),
            _SidebarAction(
              icon: Icons.storage_rounded,
              label: 'Gestion données',
              onTap: onAdminData,
            ),

            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),

            // ── User chip ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.sidebarAccent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onLogout,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.logout_rounded,
                          color: Colors.white54, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.sidebarSelected
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: selected ? Colors.white : Colors.white54, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.white54, size: 16),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Body ───────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _DashboardBody({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final seanceProv = context.watch<SeanceProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;

    if (seanceProv.isLoading) {
      return const LoadingOverlay(message: 'Chargement des séances...');
    }
    if (seanceProv.error != null) {
      return AppErrorWidget(message: seanceProv.error!, onRetry: onRefresh);
    }

    final todaySeances = seanceProv.todaySeances;
    final allSeances = seanceProv.allSeances;
    final today = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final todayCapitalized =
        today[0].toUpperCase() + today.substring(1);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tableau de bord',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text(
                  todayCapitalized,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sidebarAccent.withValues(alpha: 0.15),
                  child: Text(
                    auth.professor != null
                        ? '${auth.professor!.prenom[0]}${auth.professor!.nom[0]}'.toUpperCase()
                        : 'AS',
                    style: TextStyle(
                        color: AppColors.seed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),

          // ── Stat Cards ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.sidebarAccent,
                      value: '${allSeances.length}',
                      label: 'Séances totales',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      value: '${todaySeances.length}',
                      label: "Séances auj.",
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Today's Sessions Header ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    "Séances d'aujourd'hui",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (todaySeances.isNotEmpty)
                    TextButton(
                      onPressed: () {},
                      child: const Text('Voir tout →'),
                    ),
                ],
              ),
            ),
          ),

          // ── Session list or empty ──────────────────────────────────────
          if (todaySeances.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.event_busy_rounded,
                text: "Aucune séance aujourd'hui",
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final s = todaySeances[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SeanceCard(
                        seance: s,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => AttendanceScreen(seance: s)),
                        ),
                      ),
                    );
                  },
                  childCount: todaySeances.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 26),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      child: Column(children: [
        Icon(icon, size: 64, color: color.withValues(alpha: 0.3)),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 14)),
      ]),
    );
  }
}
