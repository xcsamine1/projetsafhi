import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _AdminDataScreenState extends State<AdminDataScreen> {
  // Service instance
  final _etudiantService = EtudiantService(ApiService());

  // Form Keys
  final _filiereFormKey = GlobalKey<FormState>();
  final _etudiantFormKey = GlobalKey<FormState>();

  // State
  bool _isLoadingMeta = true;
  bool _isSaving = false;
  SeanceMetadata? _metadata;

  // Inputs
  String _nomFiliere = '';
  String _nomEtudiant = '';
  String _prenomEtudiant = '';
  int? _selectedFiliere;

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
      if (mounted) {
        setState(() {
          _metadata = meta;
          _isLoadingMeta = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoadingMeta = false);
      }
    }
  }

  Future<void> _submitFiliere() async {
    if (!_filiereFormKey.currentState!.validate()) return;
    _filiereFormKey.currentState!.save();
    
    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;

    try {
      await _etudiantService.createFiliere(_nomFiliere, token: token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filière créée avec succès !')),
        );
        _filiereFormKey.currentState!.reset();
        await _loadMetadata(); // Refresh the list for the other form
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitEtudiant() async {
    if (!_etudiantFormKey.currentState!.validate()) return;
    _etudiantFormKey.currentState!.save();
    
    if (_selectedFiliere == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une filière.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final token = context.read<AuthProvider>().token;

    try {
      await _etudiantService.createEtudiant(
        _nomEtudiant,
        _prenomEtudiant,
        _selectedFiliere!,
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant inscrit avec succès !')),
        );
        _etudiantFormKey.currentState!.reset();
        setState(() => _selectedFiliere = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMeta) {
      return const Scaffold(body: LoadingOverlay(message: 'Chargement...'));
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des données')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- Create Filière Card ---
              Card(
                elevation: 4,
                shadowColor: cs.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _filiereFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, color: cs.primary),
                            const SizedBox(width: 8),
                            Text('Nouvelle Filière', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nom de la filière',
                            border: OutlineInputBorder(),
                            hintText: 'Ex: Informatique L3',
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                          onSaved: (v) => _nomFiliere = v!,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitFiliere,
                          child: const Text('Créer Filière'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Create Etudiant Card ---
              Card(
                elevation: 4,
                shadowColor: cs.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _etudiantFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_add, color: cs.primary),
                            const SizedBox(width: 8),
                            Text('Nouvel Étudiant', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Prénom',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                                onSaved: (v) => _prenomEtudiant = v!,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Nom',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                                onSaved: (v) => _nomEtudiant = v!,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Filière',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedFiliere,
                          items: _metadata?.filieres.map((f) {
                            return DropdownMenuItem(
                              value: f.idFiliere,
                              child: Text(f.nomFiliere),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedFiliere = val),
                          validator: (v) => v == null ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitEtudiant,
                          child: const Text('Inscrire Étudiant'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isSaving) const LoadingOverlay(message: 'Enregistrement...'),
        ],
      ),
    );
  }
}
