import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../widgets/seance_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'attendance_screen.dart';

/// Shows all sessions for the professor with optional date filtering.
class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  DateTime? _selectedDate;

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (!mounted) return;
    setState(() => _selectedDate = picked);
    context.read<SeanceProvider>().setDateFilter(picked);
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
    context.read<SeanceProvider>().setDateFilter(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seanceProvider = context.watch<SeanceProvider>();
    final auth = context.watch<AuthProvider>();

    if (seanceProvider.isLoading) {
      return const LoadingOverlay(message: 'Chargement...');
    }
    if (seanceProvider.error != null) {
      return AppErrorWidget(
        message: seanceProvider.error!,
        onRetry: () => seanceProvider.loadSeances(
          profId: auth.professor?.idProf ?? 1,
        ),
      );
    }

    final seances = _selectedDate != null
        ? seanceProvider.filteredSeances
        : seanceProvider.allSeances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Date filter bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                        : 'Filtrer par date',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Effacer le filtre',
                  icon: const Icon(Icons.close),
                  onPressed: _clearDate,
                ),
              ],
            ],
          ),
        ),

        // ── Count ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${seances.length} séance(s)',
            style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: seances.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 56,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      const Text('Aucune séance trouvée'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: seances.length,
                  itemBuilder: (ctx, i) {
                    final seance = seances[i];
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
                ),
        ),
      ],
    );
  }
}
