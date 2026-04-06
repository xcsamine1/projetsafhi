import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/metadata.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../services/api_service.dart';
import '../services/etudiant_service.dart';
import '../widgets/loading_overlay.dart';

class AdminDataScreen extends StatefulWidget {
  const AdminDataScreen({super.key});

  @override
  State<AdminDataScreen> createState() => _AdminDataScreenState();
}

class _AdminDataScreenState extends State<AdminDataScreen>
    with SingleTickerProviderStateMixin {
  final _etudiantService = EtudiantService(ApiService());

  late TabController _tabController;

  bool _isLoadingMeta = true;
  bool _isSaving = false;
  SeanceMetadata? _metadata;

  // Filière form
  final _filiereFormKey = GlobalKey<FormState>();
  final _nomFiliereCtrl = TextEditingController();

  // Étudiant form
  final _etudiantFormKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl    = TextEditingController();
  int? _selectedFiliere;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMetadata());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomFiliereCtrl.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingMeta = true);
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

  // ── Create filière ──────────────────────────────────────────────────────────

  Future<void> _submitFiliere() async {
    if (!_filiereFormKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    try {
      await _etudiantService.createFiliere(_nomFiliereCtrl.text.trim(), token: token);
      if (mounted) {
        _showSnack('Filière créée avec succès !');
        _nomFiliereCtrl.clear();
        await _loadMetadata();
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete filière ──────────────────────────────────────────────────────────

  Future<void> _deleteFiliere(Filiere f) async {
    final confirmed = await _confirmDelete(
      title: 'Supprimer la filière',
      body: 'Voulez-vous vraiment supprimer "${f.nomFiliere}" ?\n\nCela échouera s\'il y a des étudiants ou séances liés.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    try {
      await _etudiantService.deleteFiliere(f.idFiliere, token: token);
      if (mounted) {
        _showSnack('Filière supprimée.');
        await _loadMetadata();
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Create étudiant ─────────────────────────────────────────────────────────

  Future<void> _submitEtudiant() async {
    if (!_etudiantFormKey.currentState!.validate()) return;
    if (_selectedFiliere == null) {
      _showSnack('Sélectionnez une filière.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;
    try {
      await _etudiantService.createEtudiant(
        _nomCtrl.text.trim(), _prenomCtrl.text.trim(), _selectedFiliere!, token: token);
      if (mounted) {
        _showSnack('${_prenomCtrl.text} ${_nomCtrl.text} inscrit(e) avec succès !');
        _prenomCtrl.clear();
        _nomCtrl.clear();
        setState(() => _selectedFiliere = null);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<bool> _confirmDelete({required String title, required String body}) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.absent),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ]),
          content: Text(body, style: const TextStyle(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.absent, foregroundColor: Colors.white),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ) ?? false;

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingMeta) {
      return const Scaffold(body: LoadingOverlay(message: 'Chargement...'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des données'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: 'Filières'),
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Étudiants'),
          ],
          labelColor: AppColors.seed,
          unselectedLabelColor: AppColors.seed.withValues(alpha: 0.5),
          indicatorColor: AppColors.seed,
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _FiliereTab(
                filieres: _metadata?.filieres ?? [],
                formKey: _filiereFormKey,
                controller: _nomFiliereCtrl,
                isDark: isDark,
                cs: cs,
                onSubmit: _submitFiliere,
                onDelete: _deleteFiliere,
              ),
              _EtudiantTab(
                filieres: _metadata?.filieres ?? [],
                formKey: _etudiantFormKey,
                prenomCtrl: _prenomCtrl,
                nomCtrl: _nomCtrl,
                selectedFiliere: _selectedFiliere,
                onFiliereChanged: (v) => setState(() => _selectedFiliere = v),
                isDark: isDark,
                cs: cs,
                onSubmit: _submitEtudiant,
              ),
            ],
          ),
          if (_isSaving) const LoadingOverlay(message: 'Enregistrement...'),
        ],
      ),
    );
  }
}

// ─── Tab: Filières ────────────────────────────────────────────────────────────

class _FiliereTab extends StatelessWidget {
  final List<Filiere> filieres;
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onSubmit;
  final Future<void> Function(Filiere) onDelete;

  const _FiliereTab({
    required this.filieres,
    required this.formKey,
    required this.controller,
    required this.isDark,
    required this.cs,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Create form ────────────────────────────────────────────────
        _SectionCard(
          icon: Icons.add_circle_outline_rounded,
          iconColor: AppColors.dataTeal,
          title: 'Nouvelle filière',
          isDark: isDark,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel(label: 'Nom de la filière'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Informatique L3',
                    prefixIcon: Icon(Icons.school_outlined, size: 20),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dataTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Créer la filière',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Existing filières ──────────────────────────────────────────
        if (filieres.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.list_alt_rounded,
            iconColor: AppColors.seed,
            title: 'Filières existantes (${filieres.length})',
            isDark: isDark,
            child: Column(
              children: filieres.asMap().entries.map((entry) {
                final i = entry.key;
                final f = entry.value;
                const colors = [
                  AppColors.infoBlue, AppColors.geiiPurple,
                  AppColors.dataTeal, AppColors.sidebarAccent,
                ];
                final color = colors[f.idFiliere % colors.length];
                return Column(
                  children: [
                    if (i > 0) Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.school_rounded, color: color, size: 18),
                      ),
                      title: Text(f.nomFiliere,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('ID ${f.idFiliere}',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.absent, size: 20),
                        tooltip: 'Supprimer',
                        onPressed: () => onDelete(f),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Tab: Étudiants ───────────────────────────────────────────────────────────

class _EtudiantTab extends StatelessWidget {
  final List<Filiere> filieres;
  final GlobalKey<FormState> formKey;
  final TextEditingController prenomCtrl;
  final TextEditingController nomCtrl;
  final int? selectedFiliere;
  final ValueChanged<int?> onFiliereChanged;
  final bool isDark;
  final ColorScheme cs;
  final VoidCallback onSubmit;

  const _EtudiantTab({
    required this.filieres,
    required this.formKey,
    required this.prenomCtrl,
    required this.nomCtrl,
    required this.selectedFiliere,
    required this.onFiliereChanged,
    required this.isDark,
    required this.cs,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (filieres.isEmpty)
          _InfoBanner(
            icon: Icons.info_outline_rounded,
            message: 'Créez d\'abord une filière dans l\'onglet "Filières".',
            color: AppColors.retard,
          ),
        const SizedBox(height: 8),
        _SectionCard(
          icon: Icons.person_add_outlined,
          iconColor: AppColors.geiiPurple,
          title: 'Inscrire un étudiant',
          isDark: isDark,
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Prénom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: prenomCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Karim',
                              prefixIcon: Icon(Icons.badge_outlined, size: 18),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(label: 'Nom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nomCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Bouazza',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Filière'),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: selectedFiliere,
                  decoration: const InputDecoration(
                    hintText: 'Choisir une filière',
                    prefixIcon: Icon(Icons.school_outlined, size: 20),
                  ),
                  items: filieres.map((f) =>
                      DropdownMenuItem(value: f.idFiliere, child: Text(f.nomFiliere))).toList(),
                  onChanged: onFiliereChanged,
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: filieres.isEmpty ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.geiiPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: AppColors.geiiPurple.withValues(alpha: 0.4),
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Inscrire l\'étudiant',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Info Banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InfoBanner({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: color))),
      ]),
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
          fontSize: 13, fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ));
  }
}
