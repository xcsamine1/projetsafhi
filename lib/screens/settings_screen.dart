import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Settings screen — allows the professor to change:
///   • The API base URL (when in real-API mode)
///   • Toggle between dummy data mode and real API mode
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late bool _useDummy;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppConfig.baseUrl);
    _useDummy = AppConfig.useDummyData;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      AppConfig.baseUrl = url;
    }
    AppConfig.useDummyData = _useDummy;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres sauvegardés. Redémarrez l\'app si nécessaire.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Sauvegarder',
                style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── API section ────────────────────────────────────────────────
          const _SectionHeader(title: 'API & Connexion'),
          const SizedBox(height: 12),

          // Dummy data toggle
          Card(
            child: SwitchListTile(
              secondary: Icon(Icons.data_object, color: cs.primary),
              title: const Text('Mode démonstration'),
              subtitle: const Text(
                'Utilise des données locales intégrées.\nDésactivez pour vous connecter à un vrai serveur.',
              ),
              value: _useDummy,
              onChanged: (v) => setState(() => _useDummy = v),
            ),
          ),
          const SizedBox(height: 12),

          // Base URL
          AnimatedOpacity(
            opacity: _useDummy ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text('URL du serveur',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      enabled: !_useDummy,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.1.x:8080/api',
                        prefixIcon: Icon(Icons.http),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exemple: http://10.0.2.2:8080/api (émulateur Android)\n'
                      'ou http://192.168.x.x:8080/api (appareil physique)',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Info section ───────────────────────────────────────────────
          const _SectionHeader(title: 'Informations'),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                const _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Version',
                  value: AppConfig.appVersion,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.storage_outlined,
                  label: 'Source de données',
                  value: AppConfig.useDummyData
                      ? 'Données locales (Démo)'
                      : AppConfig.baseUrl,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_alt),
              label: const Text('Sauvegarder les paramètres'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label),
      trailing: Text(value,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
    );
  }
}
