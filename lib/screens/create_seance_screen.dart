import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  String _formatTime(TimeOfDay time) {
    final hr = time.hour.toString().padLeft(2, '0');
    final mn = time.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir la date et les heures.')),
      );
      return;
    }

    // Verify time validity
    final startMins = _startTime!.hour * 60 + _startTime!.minute;
    final endMins = _endTime!.hour * 60 + _endTime!.minute;
    if (endMins <= startMins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'heure de fin doit être après le début.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final seanceProv = context.read<SeanceProvider>();

    try {
      final newSeance = Seance(
        idSeance: 0, // Ignored by server
        dateSeance: _date!,
        heureDebut: '${_formatTime(_startTime!)}:00',
        heureFin: '${_formatTime(_endTime!)}:00',
        idProf: auth.professor!.idProf,
        idModule: _selectedModule!,
        idFiliere: _selectedFiliere!,
        // We can pass names locally or let the server return them, 
        // passing them locally helps UI render immediately
        nomModule: _metadata?.modules.firstWhere((m) => m.idModule == _selectedModule).nomModule,
        nomFiliere: _metadata?.filieres.firstWhere((f) => f.idFiliere == _selectedFiliere).nomFiliere,
        nomProf: '${auth.professor!.prenom} ${auth.professor!.nom}',
      );

      await seanceProv.addSeance(newSeance, token: auth.token);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance créée avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de création: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMeta) {
      return const Scaffold(body: LoadingOverlay(message: 'Chargement...'));
    }

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
                  // --- Date Selection ---
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date de la séance'),
                    subtitle: Text(_date == null
                        ? 'Sélectionnez une date'
                        : DateFormat('dd/MM/yyyy').format(_date!)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000), // Allowing past entries per user approval
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Time Selection ---
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          leading: const Icon(Icons.access_time),
                          title: const Text('Début', style: TextStyle(fontSize: 14)),
                          subtitle: Text(_startTime?.format(context) ?? '--:--'),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _startTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          leading: const Icon(Icons.access_time_filled),
                          title: const Text('Fin', style: TextStyle(fontSize: 14)),
                          subtitle: Text(_endTime?.format(context) ?? '--:--'),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _endTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Module Dropdown ---
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Module',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    items: _metadata?.modules.map((m) {
                      return DropdownMenuItem(
                        value: m.idModule,
                        child: Text(m.nomModule),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedModule = val),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Filiere Dropdown ---
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Filière',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: _metadata?.filieres.map((f) {
                      return DropdownMenuItem(
                        value: f.idFiliere,
                        child: Text(f.nomFiliere),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedFiliere = val),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 32),

                  // --- Submit Button ---
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Créer la Séance', style: TextStyle(fontSize: 16)),
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
