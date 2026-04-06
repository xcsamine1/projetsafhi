import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/metadata.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/etudiant_service.dart';
import '../widgets/loading_overlay.dart';

/// Screen to create a new student (Étudiant).
class AddStudentScreen extends StatefulWidget {
  final List<Filiere> filieres;

  const AddStudentScreen({super.key, required this.filieres});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _etudiantService = EtudiantService(ApiService());

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  int? _selectedFiliereId;
  bool _isSaving = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;

    try {
      await _etudiantService.createEtudiant(
        _nomController.text.trim(),
        _prenomController.text.trim(),
        _selectedFiliereId!,
        token: token,
      );
      if (mounted) {
        // Show success snackbar and pop with result = true
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${_prenomController.text} ${_nomController.text} inscrit(e) avec succès !',
                ),
              ],
            ),
            backgroundColor: AppColors.present,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true); // signal refresh to caller
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.absent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel étudiant')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header illustration ─────────────────────────────────
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.seed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 40,
                        color: AppColors.seed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inscrire un étudiant',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Remplissez les informations ci-dessous',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Prénom ──────────────────────────────────────────────
                  _SectionLabel(label: 'Prénom'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _prenomController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Karim',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Nom ─────────────────────────────────────────────────
                  _SectionLabel(label: 'Nom'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nomController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Bouazza',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Filière ─────────────────────────────────────────────
                  _SectionLabel(label: 'Filière'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: _selectedFiliereId,
                    decoration: const InputDecoration(
                      hintText: 'Choisir une filière',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                    ),
                    items: widget.filieres.map((f) {
                      return DropdownMenuItem(
                        value: f.idFiliere,
                        child: Text(f.nomFiliere),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedFiliereId = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),

                  const SizedBox(height: 40),

                  // ── Filière preview chip ─────────────────────────────────
                  if (_selectedFiliereId != null) ...[
                    _PreviewCard(
                      prenom: _prenomController.text,
                      nom: _nomController.text,
                      filiereName: widget.filieres
                          .firstWhere(
                              (f) => f.idFiliere == _selectedFiliereId)
                          .nomFiliere,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Submit ───────────────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.seed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor:
                          AppColors.seed.withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Inscrire l\'étudiant',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Cancel ───────────────────────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            const LoadingOverlay(message: 'Enregistrement...'),
        ],
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
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final String prenom;
  final String nom;
  final String filiereName;
  final bool isDark;

  const _PreviewCard({
    required this.prenom,
    required this.nom,
    required this.filiereName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = '${prenom.trim()} ${nom.trim()}'.trim();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.seed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.seed.withValues(alpha: 0.15),
            child: Text(
              displayName.isNotEmpty
                  ? displayName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.seed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : 'Nom complet',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.seed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    filiereName,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.seed,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.present, size: 20),
        ],
      ),
    );
  }
}
