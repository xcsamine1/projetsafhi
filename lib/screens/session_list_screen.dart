import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../models/seance.dart';
import '../widgets/seance_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'attendance_screen.dart';

/// Session list screen — grouped by date with search bar and filière filter.
class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final seanceProv = context.watch<SeanceProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;

    if (seanceProv.isLoading) {
      return const LoadingOverlay(message: 'Chargement...');
    }
    if (seanceProv.error != null) {
      return AppErrorWidget(
        message: seanceProv.error!,
        onRetry: () => seanceProv.loadSeances(profId: auth.professor?.idProf ?? 1),
      );
    }

    // Filter by search query
    final allSeances = seanceProv.allSeances.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (s.nomModule ?? '').toLowerCase().contains(q) ||
          (s.nomFiliere ?? '').toLowerCase().contains(q);
    }).toList();

    // Group by date
    final Map<String, List<Seance>> grouped = {};
    for (final s in allSeances) {
      final key = DateFormat('yyyy-MM-dd').format(s.dateSeance);
      grouped.putIfAbsent(key, () => []).add(s);
    }
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // most recent first

    return Column(
      children: [
        // ── App Bar area ────────────────────────────────────────────────
        Container(
          color: isDark ? cs.surfaceContainer : Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Title bar
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Séances',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          Text(
                            '${allSeances.length} séance(s)',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un module, une filière...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      prefixIcon:
                          Icon(Icons.search, color: cs.onSurface.withValues(alpha: 0.4)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),

        // ── Grouped list ────────────────────────────────────────────────
        Expanded(
          child: allSeances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Aucune séance trouvée',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedDates.length,
                  itemBuilder: (ctx, i) {
                    final dateKey = sortedDates[i];
                    final date = DateTime.parse(dateKey);
                    final sessions = grouped[dateKey]!;
                    final isToday = _isToday(date);
                    final isTomorrow = _isTomorrow(date);

                    final dayLabel = isToday
                        ? "Aujourd'hui"
                        : isTomorrow
                            ? 'Demain'
                            : null;
                    final dateLabel =
                        DateFormat('EEEE d MMMM', 'fr_FR').format(date);
                    final headerLabel = dayLabel != null
                        ? '$dayLabel — $dateLabel'
                        : dateLabel[0].toUpperCase() + dateLabel.substring(1);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.seed),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  headerLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: cs.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.seed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${sessions.length} séance${sessions.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.seed,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Session cards
                        ...sessions.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: SeanceCard(
                                seance: s,
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceScreen(seance: s),
                                  ),
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isTomorrow(DateTime d) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day;
  }
}
