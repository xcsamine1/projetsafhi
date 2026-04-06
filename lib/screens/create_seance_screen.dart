import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/metadata.dart';
import '../models/seance.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../widgets/loading_overlay.dart';

class CreateSeanceScreen extends StatefulWidget {
  const CreateSeanceScreen({super.key});

  @override
  State<CreateSeanceScreen> createState() => _CreateSeanceScreenState();
}

class _CreateSeanceScreenState extends State<CreateSeanceScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _selectedModule;
  int? _selectedFiliere;

  bool _isLoadingMeta = true;
  bool _isSaving = false;
  SeanceMetadata? _metadata;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final auth = context.read<AuthProvider>();
    final seanceProv = context.read<SeanceProvider>();
    try {
      final meta = await seanceProv.fetchMetadata(token: auth.token);
      if (mounted) setState(() { _metadata = meta; _isLoadingMeta = false; });
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e', isError: true);
        setState(() => _isLoadingMeta = false);
      }
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      _showSnack('Veuillez remplir la date et les heures.', isError: true);
      return;
    }
    final startMins = _startTime!.hour * 60 + _startTime!.minute;
    final endMins   = _endTime!.hour * 60 + _endTime!.minute;
    if (endMins <= startMins) {
      _showSnack("L'heure de fin doit être après le début.", isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final seanceProv = context.read<SeanceProvider>();

    try {
      final newSeance = Seance(
        idSeance: 0,
        dateSeance: _date!,
        heureDebut: '${_formatTime(_startTime!)}:00',
        heureFin:   '${_formatTime(_endTime!)}:00',
        idProf:    auth.professor!.idProf,
        idModule:  _selectedModule!,
        idFiliere: _selectedFiliere!,
        nomModule:  _metadata?.modules.firstWhere((m) => m.idModule == _selectedModule).nomModule,
        nomFiliere: _metadata?.filieres.firstWhere((f) => f.idFiliere == _selectedFiliere).nomFiliere,
        nomProf: '${auth.professor!.prenom} ${auth.professor!.nom}',
      );
      await seanceProv.addSeance(newSeance, token: auth.token);
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Séance créée avec succès !');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e', isError: true);
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? AppColors.absent : AppColors.present,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMeta) {
      return const Scaffold(body: LoadingOverlay(message: 'Chargement...'));
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Séance')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_rounded, size: 36, color: AppColors.seed),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Planifier une séance',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Remplissez les informations ci-dessous',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 32),

                  // ── Date ────────────────────────────────────────────────
                  _SectionLabel(label: 'Date de la séance'),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: _date == null
                        ? 'Sélectionner une date'
                        : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date!),
                    hasValue: _date != null,
                    isDark: isDark,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Time ────────────────────────────────────────────────
                  _SectionLabel(label: 'Horaire'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.schedule_rounded,
                          label: _startTime == null ? 'Début' : _formatTime(_startTime!),
                          hasValue: _startTime != null,
                          isDark: isDark,
                          onTap: () async {
                            final p = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (p != null) setState(() => _startTime = p);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: cs.onSurface.withValues(alpha: 0.3), size: 18),
                      ),
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.schedule_rounded,
                          label: _endTime == null ? 'Fin' : _formatTime(_endTime!),
                          hasValue: _endTime != null,
                          isDark: isDark,
                          onTap: () async {
                            final p = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (p != null) setState(() => _endTime = p);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Module ──────────────────────────────────────────────
                  _SectionLabel(label: 'Module'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      hintText: 'Choisir un module',
                      prefixIcon: Icon(Icons.book_outlined, size: 20),
                    ),
                    items: _metadata?.modules.map((m) => DropdownMenuItem(
                          value: m.idModule, child: Text(m.nomModule))).toList(),
                    onChanged: (v) => setState(() => _selectedModule = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Filière ─────────────────────────────────────────────
                  _SectionLabel(label: 'Filière'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      hintText: 'Choisir une filière',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: _metadata?.filieres.map((f) => DropdownMenuItem(
                          value: f.idFiliere, child: Text(f.nomFiliere))).toList(),
                    onChanged: (v) => setState(() => _selectedFiliere = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 40),

                  // ── Submit ───────────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.seed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: AppColors.seed.withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Créer la séance',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Annuler',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving) const LoadingOverlay(message: 'Enregistrement...'),
        ],
      ),
    );
  }
}

// ─── Picker Tile (replaces the old ListTile with grey border) ─────────────────

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.seed.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: hasValue ? AppColors.seed : cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? cs.onSurface : cs.onSurface.withValues(alpha: 0.45),
                  fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ));
  }
}
