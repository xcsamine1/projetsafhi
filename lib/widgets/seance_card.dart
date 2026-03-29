import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/seance.dart';

/// Card widget matching the ESTC 2025 Séances screen design.
class SeanceCard extends StatelessWidget {
  final Seance seance;
  final VoidCallback onTap;

  const SeanceCard({super.key, required this.seance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isToday = seance.isToday;

    final filiereColor = _filiereColor(seance.nomFiliere ?? '');

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              // ── Main row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Time badge
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            seance.heureDebut.substring(0, 5),
                            style: TextStyle(
                              color: AppColors.seed,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Module + filière
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seance.nomModule ?? 'Module #${seance.idModule}',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Filière chip
                              _FiliereChip(
                                  label: seance.nomFiliere ?? 'Filière',
                                  color: filiereColor),
                              const SizedBox(width: 8),
                              // Time range
                              Icon(Icons.schedule,
                                  size: 12,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 3),
                              Text(
                                '${seance.heureDebut.substring(0, 5)}–${seance.heureFin.substring(0, 5)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(Icons.chevron_right,
                        color: cs.onSurface.withValues(alpha: 0.3), size: 20),
                  ],
                ),
              ),

              // ── Status strip ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      isToday
                          ? 'Aucun pointage enregistré'
                          : DateFormat('dd/MM/yyyy').format(seance.dateSeance),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                    const Spacer(),
                    _StatusBadge(isToday: isToday),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _filiereColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('info')) return AppColors.infoBlue;
    if (lower.contains('gei') || lower.contains('gii')) return AppColors.geiiPurple;
    if (lower.contains('data') || lower.contains('science')) return AppColors.dataTeal;
    if (lower.contains('math')) return const Color(0xFFF59E0B);
    return AppColors.sidebarAccent;
  }
}

class _FiliereChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FiliereChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isToday;

  const _StatusBadge({required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
            : AppColors.present.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : AppColors.present.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isToday ? Icons.schedule : Icons.check_circle,
            size: 11,
            color: isToday ? const Color(0xFFF59E0B) : AppColors.present,
          ),
          const SizedBox(width: 4),
          Text(
            isToday ? 'En attente' : 'Complétée',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday ? const Color(0xFFF59E0B) : AppColors.present,
            ),
          ),
        ],
      ),
    );
  }
}
