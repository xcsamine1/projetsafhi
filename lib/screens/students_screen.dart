import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/etudiant.dart';
import '../models/metadata.dart';
import '../providers/auth_provider.dart';
import '../providers/seance_provider.dart';
import '../services/api_service.dart';
import '../services/etudiant_service.dart';
import '../widgets/loading_overlay.dart';
import 'add_student_screen.dart';

/// Displays all students, filterable by filière, with search and swipe-to-delete.
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _etudiantService = EtudiantService(ApiService());

  List<Etudiant> _allStudents = [];
  List<Filiere> _filieres = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedFiliere;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    final token = context.read<AuthProvider>().token;
    final seanceProv = context.read<SeanceProvider>();
    try {
      final meta = await seanceProv.fetchMetadata(token: token);
      _filieres = meta?.filieres ?? [];
      final data = await _etudiantService.getAll(token: token);
      if (mounted) setState(() { _allStudents = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<Etudiant> get _filtered => _allStudents.where((e) {
    final matchFiliere = _selectedFiliere == null || e.idFiliere == _selectedFiliere;
    final q = _searchQuery.toLowerCase();
    final matchSearch = q.isEmpty ||
        e.nom.toLowerCase().contains(q) || e.prenom.toLowerCase().contains(q);
    return matchFiliere && matchSearch;
  }).toList();

  String _filiereName(int id) => _filieres
      .firstWhere((f) => f.idFiliere == id,
          orElse: () => Filiere(idFiliere: id, nomFiliere: 'Filière $id'))
      .nomFiliere;

  Color _filiereColor(int id) {
    const colors = [AppColors.infoBlue, AppColors.geiiPurple, AppColors.dataTeal, AppColors.sidebarAccent];
    return colors[id % colors.length];
  }

  Future<void> _deleteStudent(Etudiant e) async {
    final confirmed = await _confirmDelete(
      title: 'Supprimer l\'étudiant',
      body: 'Voulez-vous vraiment supprimer "${e.prenom} ${e.nom}" ?\nCette action est irréversible.',
    );
    if (!confirmed || !mounted) return;

    final token = context.read<AuthProvider>().token;
    try {
      await _etudiantService.deleteEtudiant(e.idEtudiant, token: token);
      setState(() => _allStudents.removeWhere((s) => s.idEtudiant == e.idEtudiant));
      _showSnack('${e.prenom} ${e.nom} supprimé(e).', isError: false);
    } catch (err) {
      _showSnack(err.toString(), isError: true);
    }
  }

  Future<bool> _confirmDelete({required String title, required String body}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.absent, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            content: Text(body, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.absent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {required bool isError}) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ── Custom AppBar ─────────────────────────────────────────────
        Container(
          color: isDark ? cs.surfaceContainer : Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      if (Scaffold.maybeOf(context)?.hasDrawer ?? false)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      Text('Étudiants',
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Actualiser',
                          onPressed: _loadData),
                    ],
                  ),
                ),
                // ── Search + Filter bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un étudiant...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''))
                              : null,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FiliereChip(
                              label: 'Tous',
                              selected: _selectedFiliere == null,
                              color: AppColors.seed,
                              onTap: () => setState(() => _selectedFiliere = null),
                            ),
                            ..._filieres.map((f) => _FiliereChip(
                                  label: f.nomFiliere,
                                  selected: _selectedFiliere == f.idFiliere,
                                  color: _filiereColor(f.idFiliere),
                                  onTap: () => setState(() => _selectedFiliere = f.idFiliere),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ],
            ),
          ),
        ),

        // ── List ───────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const LoadingOverlay(message: 'Chargement...')
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _loadData)
                  : _filtered.isEmpty
                      ? _EmptyView(query: _searchQuery, hasFilter: _selectedFiliere != null)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final e = _filtered[i];
                              final color = _filiereColor(e.idFiliere);
                              return _DismissibleStudentCard(
                                etudiant: e,
                                filiereName: _filiereName(e.idFiliere),
                                filiereColor: color,
                                isDark: isDark,
                                onDelete: () => _deleteStudent(e),
                              );
                            },
                          ),
                        ),
        ),

        // ── Count footer ───────────────────────────────────────────────
        if (!_isLoading && _error == null)
          Container(
            width: double.infinity,
            color: isDark ? cs.surfaceContainer : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '${_filtered.length} étudiant${_filtered.length != 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
      ],
    );
  }
}

// ─── Dismissible student card ─────────────────────────────────────────────────

class _DismissibleStudentCard extends StatelessWidget {
  final Etudiant etudiant;
  final String filiereName;
  final Color filiereColor;
  final bool isDark;
  final VoidCallback onDelete;

  const _DismissibleStudentCard({
    required this.etudiant,
    required this.filiereName,
    required this.filiereColor,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        '${etudiant.prenom.isNotEmpty ? etudiant.prenom[0] : ''}${etudiant.nom.isNotEmpty ? etudiant.nom[0] : ''}'
            .toUpperCase();

    return Dismissible(
      key: ValueKey(etudiant.idEtudiant),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // we handle removal ourselves in onDelete
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.absent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.absent, size: 24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: filiereColor.withValues(alpha: 0.15),
            child: Text(initials,
                style: TextStyle(
                    color: filiereColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          title: Text(
            '${etudiant.prenom} ${etudiant.nom}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: filiereColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(filiereName,
                  style: TextStyle(
                      fontSize: 11, color: filiereColor, fontWeight: FontWeight.w500)),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#${etudiant.idEtudiant}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.absent, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filière Filter Chip ──────────────────────────────────────────────────────

class _FiliereChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FiliereChip({
    required this.label, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : color,
            )),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: color.withValues(alpha: 0.08),
        selectedColor: color,
        checkmarkColor: Colors.white,
        showCheckmark: selected,
        side: BorderSide(color: selected ? color : color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String query;
  final bool hasFilter;

  const _EmptyView({required this.query, required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 72, color: color),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? 'Aucun résultat pour "$query"'
                  : hasFilter
                      ? 'Aucun étudiant dans cette filière'
                      : 'Aucun étudiant enregistré',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.absent),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
