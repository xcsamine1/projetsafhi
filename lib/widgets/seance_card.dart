import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/seance.dart';

/// Card widget displaying a session's module, filière, time, and date.
class SeanceCard extends StatelessWidget {
  final Seance seance;
  final VoidCallback onTap;

  const SeanceCard({super.key, required this.seance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isToday = seance.isToday;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.class_,
                        color: color.onPrimaryContainer, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seance.nomModule ?? 'Module #${seance.idModule}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          seance.nomFiliere ?? 'Filière #${seance.idFiliere}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // "Aujourd'hui" badge
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Aujourd'hui",
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: color.onTertiaryContainer),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Info row ─────────────────────────────────────────────────
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.schedule,
                    label: '${seance.heureDebut} – ${seance.heureFin}',
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: DateFormat('dd/MM/yyyy').format(seance.dateSeance),
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
      ],
    );
  }
}
