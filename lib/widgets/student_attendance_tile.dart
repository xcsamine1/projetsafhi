import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/etudiant.dart';

/// Student attendance tile — redesigned to match ESTC 2025 style.
class StudentAttendanceTile extends StatefulWidget {
  final Etudiant student;
  final Statut currentStatut;
  final bool hasExistingRecord;
  final ValueChanged<Statut?> onStatutChanged;
  final ValueChanged<String>? onCommentChanged;
  final String? currentComment;

  const StudentAttendanceTile({
    super.key,
    required this.student,
    required this.currentStatut,
    required this.hasExistingRecord,
    required this.onStatutChanged,
    this.onCommentChanged,
    this.currentComment,
  });

  @override
  State<StudentAttendanceTile> createState() => _StudentAttendanceTileState();
}

class _StudentAttendanceTileState extends State<StudentAttendanceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;
  late TextEditingController _commentController;
  bool _showComment = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _commentController =
        TextEditingController(text: widget.currentComment ?? '');
    _showComment = widget.currentStatut != Statut.present;
    if (_showComment) _animController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant StudentAttendanceTile old) {
    super.didUpdateWidget(old);
    final shouldShow = widget.currentStatut != Statut.present;
    if (shouldShow != _showComment) {
      setState(() => _showComment = shouldShow);
      shouldShow ? _animController.forward() : _animController.reverse();
    }
    if (widget.currentComment != null &&
        widget.currentComment != _commentController.text) {
      _commentController.text = widget.currentComment!;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Static so the const color list is not rebuilt on every widget build.
  static Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFFF97316),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final avatarColor = _avatarColor(widget.student.nom);
    final initials =
        '${widget.student.prenom[0]}${widget.student.nom[0]}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          // ── Main row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + avatar row
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: avatarColor,
                      child: Text(
                        initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.student.fullName,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (widget.hasExistingRecord)
                            const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 10, color: AppColors.present),
                                SizedBox(width: 3),
                                Text(
                                  'Déjà enregistré',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.present),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Statut selector — full width below name
                _StatutSelector(
                  current: widget.currentStatut,
                  onChanged: widget.onStatutChanged,
                ),
              ],
            ),
          ),

          // ── Comment field ─────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: TextField(
                controller: _commentController,
                onChanged: widget.onCommentChanged,
                maxLines: 2,
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Commentaire (optionnel)',
                  hintStyle: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Statut Selector ─────────────────────────────────────────────────────────

class _StatutSelector extends StatelessWidget {
  final Statut current;
  final ValueChanged<Statut?> onChanged;

  const _StatutSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: Statut.values.map((s) {
        final selected = s == current;
        final color = _color(s);
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.35),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon(s), size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _color(Statut s) {
    switch (s) {
      case Statut.present:  return AppColors.present;
      case Statut.absent:   return AppColors.absent;
      case Statut.retard:   return AppColors.retard;
      case Statut.justifie: return AppColors.justifie;
    }
  }

  IconData _icon(Statut s) {
    switch (s) {
      case Statut.present:  return Icons.check_circle_outline;
      case Statut.absent:   return Icons.cancel_outlined;
      case Statut.retard:   return Icons.schedule_outlined;
      case Statut.justifie: return Icons.info_outline;
    }
  }
}
