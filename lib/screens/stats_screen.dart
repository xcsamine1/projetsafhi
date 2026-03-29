import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/seance.dart';
import '../providers/presence_provider.dart';

/// Shows attendance statistics for a specific session.
class StatsScreen extends StatelessWidget {
  final Seance seance;

  const StatsScreen({super.key, required this.seance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PresenceProvider>();
    final total = provider.students.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques — ${seance.nomModule ?? 'Séance'}'),
      ),
      body: total == 0
          ? const Center(child: Text('Aucune donnée disponible'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Big stat cards ─────────────────────────────────────
                  _BigStatCard(
                    statut: Statut.present,
                    count: provider.countByStatut(Statut.present),
                    total: total,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(height: 12),
                  _BigStatCard(
                    statut: Statut.absent,
                    count: provider.countByStatut(Statut.absent),
                    total: total,
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                  const SizedBox(height: 12),
                  _BigStatCard(
                    statut: Statut.retard,
                    count: provider.countByStatut(Statut.retard),
                    total: total,
                    color: Colors.orange,
                    icon: Icons.watch_later,
                  ),
                  const SizedBox(height: 12),
                  _BigStatCard(
                    statut: Statut.justifie,
                    count: provider.countByStatut(Statut.justifie),
                    total: total,
                    color: Colors.blue,
                    icon: Icons.info,
                  ),
                  const SizedBox(height: 32),

                  // ── Progress bars ──────────────────────────────────────
                  Text('Répartition',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...Statut.values.map((s) {
                    final count = provider.countByStatut(s);
                    final pct = total == 0 ? 0.0 : count / total;
                    return _ProgressRow(
                      label: s.label,
                      value: pct,
                      color: _colorForStatut(s),
                      count: count,
                      total: total,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Color _colorForStatut(Statut s) {
    switch (s) {
      case Statut.present:
        return Colors.green;
      case Statut.absent:
        return Colors.red;
      case Statut.retard:
        return Colors.orange;
      case Statut.justifie:
        return Colors.blue;
    }
  }
}

class _BigStatCard extends StatelessWidget {
  final Statut statut;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _BigStatCard({
    required this.statut,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count * 100 ~/ total);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statut.label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                Text('$count étudiant(s) sur $total',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Text(
            '$pct%',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final int count;
  final int total;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text('$count / $total',
                  style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
