import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/etudiant.dart';

/// A list tile showing a student's name, status icon, a statut dropdown,
/// and an optional comment field that expands when a non-present statut is chosen.
///
/// Used in [AttendanceScreen].
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
    // Sync external comment changes
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

  /// Returns icon + color for a given statut.
  (IconData, Color) _statutStyle(Statut s) {
    switch (s) {
      case Statut.present:
        return (Icons.check_circle, Colors.green);
      case Statut.absent:
        return (Icons.cancel, Colors.red);
      case Statut.retard:
        return (Icons.watch_later, Colors.orange);
      case Statut.justifie:
        return (Icons.info, Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (icon, iconColor) = _statutStyle(widget.currentStatut);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ─────────────────────────────────────────────────
            Row(
              children: [
                // Initialed avatar
                CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  radius: 22,
                  child: Text(
                    widget.student.prenom[0].toUpperCase(),
                    style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + "Enregistré" label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.fullName,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (widget.hasExistingRecord)
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: Colors.green.shade600),
                            const SizedBox(width: 3),
                            Text(
                              'Enregistré',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: Colors.green.shade600),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Status icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(icon, key: ValueKey(icon), color: iconColor, size: 22),
                ),
                const SizedBox(width: 8),

                // Statut dropdown
                DropdownButton<Statut>(
                  value: widget.currentStatut,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  isDense: true,
                  items: Statut.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onStatutChanged,
                ),
              ],
            ),

            // ── Comment field (animated expand) ───────────────────────────
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 56),
                child: TextField(
                  controller: _commentController,
                  onChanged: widget.onCommentChanged,
                  maxLines: 2,
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Commentaire (optionnel)',
                    hintStyle: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
