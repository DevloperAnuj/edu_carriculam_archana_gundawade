import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/student_profile.dart';
import '../../core/services/xapi_service.dart';
import '../../core/mcp/client_service.dart';
import '../onboarding/student_profile_provider.dart';

/// Settings & Governance Screen — Objective 5 (Responsible Implementation)
///
/// Implements the "Transparent Data Governance" layer required for responsible
/// MCP deployment in education:
/// - Data transparency (what is stored, where, how)
/// - API key management (Claude API for real AI content)
/// - Data export and deletion (FERPA right-to-erasure)
/// - MCP server connection status
/// - AI usage policy display
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _nameController = TextEditingController();
  bool _apiKeyVisible = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentProfileProvider).value;
    if (profile != null) {
      _apiKeyController.text = profile.apiKey ?? '';
      _nameController.text = profile.studentName ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    final profile = ref.read(studentProfileProvider).value;
    if (profile != null) {
      await ref.read(studentProfileProvider.notifier).saveProfile(
            profile.copyWith(
              apiKey: _apiKeyController.text.trim().isEmpty
                  ? null
                  : _apiKeyController.text.trim(),
              studentName: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            ),
          );
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    final json = await XApiService.exportStatements();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export xAPI Learning Data'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              json.isEmpty ? '[]' : json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• Your student profile\n'
          '• All quiz scores and progress\n'
          '• All xAPI learning statements\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await XApiService.deleteAllStatements();
    await ref.read(studentProfileProvider.notifier).deleteProfile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider).value;
    final mcp = ref.watch(mcpClientServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Governance'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── MCP Connection Status ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.hub_outlined,
            title: 'MCP Server Connection',
            subtitle: 'Model Context Protocol — Objective 1',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        mcp.isConnected ? Icons.check_circle : Icons.cancel_outlined,
                        color: mcp.isConnected ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        mcp.isConnected
                            ? 'Connected to edu-mcp-server (Python)'
                            : 'Using Enhanced Mock Mode',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mcp.isConnected
                        ? 'Real MCP protocol active: JSON-RPC 2.0 over Stdio transport. '
                            'Prompts, Resources, and Tools primitives operational.'
                        : 'Python server not detected. Content is generated using the '
                            'profile-aware rich mock — all personalisation features remain active.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!mcp.isConnected) ...[
                    const SizedBox(height: 12),
                    Text(
                      'To enable the real MCP server:\n'
                      '1. Install Python: pip install -r mcp_server/requirements.txt\n'
                      '2. Ensure mcp_server/server.py is accessible\n'
                      '3. (Optional) Set ANTHROPIC_API_KEY for Claude AI content',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── AI Configuration ─────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.smart_toy_outlined,
            title: 'AI Configuration',
            subtitle: 'Claude API key for real AI-generated content',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Name (optional)',
                      hintText: 'e.g. Archana',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible,
                    decoration: InputDecoration(
                      labelText: 'Anthropic API Key (optional)',
                      hintText: 'sk-ant-...',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _apiKeyVisible = !_apiKeyVisible),
                      ),
                      helperText:
                          'Optional. When provided, the MCP server uses Claude to generate real personalised content.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API keys are stored only on this device and never transmitted externally.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Profile Summary ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.person_outlined,
            title: 'Your Learning Profile',
            subtitle: 'Data currently stored on this device',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: profile == null
                  ? const Text('No profile found.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileRow('Grade', 'Grade ${profile.grade}'),
                        _ProfileRow('Learning Style', profile.learningStyleLabel),
                        _ProfileRow('Interests', profile.interests.join(', ')),
                        _ProfileRow('Chapters Completed',
                            '${_countCompleted(profile)} chapters'),
                        _ProfileRow('Quiz Scores Recorded',
                            '${profile.quizScores.length} chapters assessed'),
                        _ProfileRow('Consent Given',
                            profile.consentGiven ? 'Yes' : 'Not yet'),
                        _ProfileRow('AI Key Configured',
                            (profile.apiKey?.isNotEmpty ?? false) ? 'Yes' : 'No'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Data Governance ──────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.policy_outlined,
            title: 'Data Governance & Privacy',
            subtitle: 'FERPA-aligned data rights — Objective 4 & 5',
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_outlined, color: Colors.blue),
                  title: const Text('Export My Learning Data'),
                  subtitle: const Text(
                      'Download all xAPI statements as JSON (data portability)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: Colors.red),
                  title: const Text('Delete All My Data'),
                  subtitle: const Text(
                      'Permanently erase profile, scores, and xAPI logs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _deleteAllData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── AI Policy ────────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.gavel_outlined,
            title: 'AI Usage Policy',
            subtitle: 'Responsible AI in education',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PolicyItem(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    text: 'AI content is labelled and disclosed in all screens.',
                  ),
                  _PolicyItem(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    text:
                        'Adaptive algorithms are explainable: difficulty is adjusted based on your quiz scores.',
                  ),
                  _PolicyItem(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    text:
                        'No profiling beyond educational context. Data is not used for advertising.',
                  ),
                  _PolicyItem(
                    icon: Icons.warning_amber_outlined,
                    color: Colors.orange,
                    text:
                        'AI content may contain errors — always verify with authoritative sources.',
                  ),
                  _PolicyItem(
                    icon: Icons.warning_amber_outlined,
                    color: Colors.orange,
                    text:
                        'Academic integrity: do not submit AI-generated text as your own work.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This implementation follows guidance from:\n'
                    '• FERPA (Family Educational Rights and Privacy Act)\n'
                    '• Anthropic Usage Policies\n'
                    '• xAPI / IEEE eLearning Standards\n'
                    '• "MCP in Educational Curriculum Design" — Archana Gundawade (2025)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  int _countCompleted(StudentProfile profile) {
    int count = 0;
    for (final subject in profile.progressTracking.values) {
      count += (subject as Map).values.where((v) => v == true).length;
    }
    return count;
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _PolicyItem(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5))),
        ],
      ),
    );
  }
}
