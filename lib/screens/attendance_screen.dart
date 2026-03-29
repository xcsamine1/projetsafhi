import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/seance.dart';
import '../providers/auth_provider.dart';
import '../providers/presence_provider.dart';
import '../widgets/student_attendance_tile.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_error_widget.dart';
import 'stats_screen.dart';

/// Attendance screen — core screen of the app.
///
/// Displays all students in the session's filière, allows the professor
/// to set each student's statut and optional comment, then submit.
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
    // Load students + existing presence records after first frame
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Présences enregistrées avec succès ✓'
              : context.read<PresenceProvider>().error ?? 'Erreur de sauvegarde',
        ),
        backgroundColor: success
            ? Colors.green.shade700
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<PresenceProvider>();
    final seance = widget.seance;

    return Scaffold(
      appBar: AppBar(
        title: Text(seance.nomModule ?? 'Appel'),
        actions: [
          // Statistics button
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistiques',
            onPressed: provider.students.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatsScreen(seance: seance),
                      ),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Session info banner ──────────────────────────────────────────
          _SessionInfoBanner(seance: seance),

          // ── Status summary bar ───────────────────────────────────────────
          if (!provider.isLoading && provider.students.isNotEmpty)
            _StatutSummaryBar(provider: provider),

          // ── Student list ─────────────────────────────────────────────────
          Expanded(child: _buildBody(provider, cs, theme)),
        ],
      ),

      // ── Submit FAB ────────────────────────────────────────────────────────
      floatingActionButton: provider.students.isEmpty || provider.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: provider.isSaving ? null : _submit,
              icon: provider.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(provider.submitted ? Icons.edit : Icons.save),
              label: Text(
                provider.isSaving
                    ? 'Enregistrement...'
                    : provider.submitted
                        ? 'Mettre à jour'
                        : 'Enregistrer l\'appel',
              ),
            ),
    );
  }

  Widget _buildBody(PresenceProvider provider, ColorScheme cs, ThemeData theme) {
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
            Icon(Icons.people_outline, size: 72, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Aucun étudiant dans cette filière',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96), // space for FAB
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

// ─── Session Info Banner ──────────────────────────────────────────────────────

class _SessionInfoBanner extends StatelessWidget {
  final Seance seance;
  const _SessionInfoBanner({required this.seance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${seance.nomFiliere ?? 'Filière'} • '
              '${DateFormat('dd/MM/yyyy').format(seance.dateSeance)} • '
              '${seance.heureDebut}–${seance.heureFin}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Statut Summary Bar ───────────────────────────────────────────────────────

/// Shows how many students are in each statut.
class _StatutSummaryBar extends StatelessWidget {
  final PresenceProvider provider;
  const _StatutSummaryBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.students.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
            label: 'Présents',
            count: provider.countByStatut(Statut.present),
            total: total,
            color: Colors.green,
          ),
          _SummaryChip(
            label: 'Absents',
            count: provider.countByStatut(Statut.absent),
            total: total,
            color: Colors.red,
          ),
          _SummaryChip(
            label: 'Retards',
            count: provider.countByStatut(Statut.retard),
            total: total,
            color: Colors.orange,
          ),
          _SummaryChip(
            label: 'Justifiés',
            count: provider.countByStatut(Statut.justifie),
            total: total,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SummaryChip(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count/$total',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
