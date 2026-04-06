import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/seance.dart';
import '../providers/auth_provider.dart';
import '../providers/presence_provider.dart';
import '../providers/seance_provider.dart';

import '../widgets/student_attendance_tile.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'stats_screen.dart';

/// Attendance screen — polished redesign matching ESTC 2025 style.
class AttendanceScreen extends StatefulWidget {
  final Seance seance;

  const AttendanceScreen({super.key, required this.seance});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    await context.read<PresenceProvider>().loadForSession(
          seanceId: widget.seance.idSeance,
          filiereId: widget.seance.idFiliere,
          token: token,
        );
  }

  Future<void> _submit() async {
    final token = context.read<AuthProvider>().token;
    final success =
        await context.read<PresenceProvider>().submitAll(token: token);

    if (!mounted) return;

    if (success) {
      // Update the card badge on the dashboard / session list instantly.
      context.read<SeanceProvider>().markSubmitted(widget.seance.idSeance);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              success
                  ? 'Présences enregistrées avec succès'
                  : context.read<PresenceProvider>().error ??
                      'Erreur de sauvegarde',
            ),
          ],
        ),
        backgroundColor: success
            ? AppColors.present
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<PresenceProvider>();
    final seance = widget.seance;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(seance.nomModule ?? 'Appel',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              seance.nomFiliere ?? '',
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (provider.students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Statistiques',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => StatsScreen(seance: seance)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Session info banner ───────────────────────────────────────
          _InfoBanner(seance: seance, isDark: isDark),

          // ── Status summary ────────────────────────────────────────────
          if (!provider.isLoading && provider.students.isNotEmpty)
            _SummaryBar(provider: provider, isDark: isDark),

          // ── Student list ──────────────────────────────────────────────
          Expanded(child: _buildBody(provider, cs, theme)),
        ],
      ),
      floatingActionButton: provider.students.isEmpty || provider.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: provider.isSaving ? null : _submit,
              backgroundColor: AppColors.seed,
              foregroundColor: Colors.white,
              icon: provider.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(provider.submitted ? Icons.edit : Icons.save),
              label: Text(
                provider.isSaving
                    ? 'Enregistrement...'
                    : provider.submitted
                        ? 'Mettre à jour'
                        : "Enregistrer l'appel",
              ),
            ),
    );
  }

  Widget _buildBody(
      PresenceProvider provider, ColorScheme cs, ThemeData theme) {
    if (provider.isLoading) {
      return const LoadingOverlay(message: 'Chargement des étudiants...');
    }
    if (provider.error != null) {
      return AppErrorWidget(message: provider.error!, onRetry: _load);
    }
    if (provider.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64,
                color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Aucun étudiant dans cette filière',
                style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: provider.students.length,
      itemBuilder: (ctx, i) {
        final student = provider.students[i];
        return StudentAttendanceTile(
          student: student,
          currentStatut: provider.getStatut(student.idEtudiant),
          hasExistingRecord: provider.hasRecord(student.idEtudiant),
          currentComment: provider.getCommentaire(student.idEtudiant),
          onStatutChanged: (s) {
            if (s != null) provider.updateStatut(student.idEtudiant, s);
          },
          onCommentChanged: (c) =>
              provider.updateCommentaire(student.idEtudiant, c),
        );
      },
    );
  }
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final Seance seance;
  final bool isDark;

  const _InfoBanner({required this.seance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Chip(
            icon: Icons.calendar_today,
            label:
                DateFormat('dd/MM/yyyy').format(seance.dateSeance),
          ),
          const SizedBox(width: 12),
          _Chip(
            icon: Icons.schedule,
            label:
                '${seance.heureDebut.substring(0, 5)}–${seance.heureFin.substring(0, 5)}',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.seed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.seed),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.seed,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Summary Bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final PresenceProvider provider;
  final bool isDark;

  const _SummaryBar({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = provider.students.length;
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _SummaryDot(
              color: AppColors.present,
              count: provider.countByStatut(Statut.present),
              label: 'Présents',
              total: total),
          const SizedBox(width: 16),
          _SummaryDot(
              color: AppColors.absent,
              count: provider.countByStatut(Statut.absent),
              label: 'Absents',
              total: total),
          const SizedBox(width: 16),
          _SummaryDot(
              color: AppColors.retard,
              count: provider.countByStatut(Statut.retard),
              label: 'Retards',
              total: total),
          const SizedBox(width: 16),
          _SummaryDot(
              color: AppColors.justifie,
              count: provider.countByStatut(Statut.justifie),
              label: 'Justifiés',
              total: total),
        ],
      ),
    );
  }
}

class _SummaryDot extends StatelessWidget {
  final Color color;
  final int count;
  final String label;
  final int total;

  const _SummaryDot(
      {required this.color,
      required this.count,
      required this.label,
      required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$count $label',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
