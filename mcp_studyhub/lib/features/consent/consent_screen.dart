import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../onboarding/student_profile_provider.dart';

/// FERPA-Style Consent Screen — Objective 4 (Ethics & Privacy)
///
/// Implements informed consent before any data collection, addressing:
/// - Student data privacy (FERPA compliance concept)
/// - Transparency about data collection, storage, and usage
/// - User control and right to informed consent
/// - Algorithmic transparency (AI content disclosure)
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _privacyAccepted = false;
  bool _aiContentAccepted = false;
  bool _dataUsageAccepted = false;

  bool get _allAccepted =>
      _privacyAccepted && _aiContentAccepted && _dataUsageAccepted;

  Future<void> _proceed() async {
    // Check if a profile already exists — just update consent flag
    final profile = ref.read(studentProfileProvider).value;
    if (profile != null) {
      await ref
          .read(studentProfileProvider.notifier)
          .saveProfile(profile.copyWith(consentGiven: true));
      if (mounted) context.go('/dashboard');
    } else {
      // New user — proceed to onboarding with consent flag
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          // Left branding panel
          Expanded(
            flex: 2,
            child: Container(
              color: scheme.primaryContainer,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 80, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Your Privacy Matters',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MCP StudyHub is designed with privacy-first principles aligned with FERPA guidelines.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _PolicyBadge(
                      icon: Icons.lock_outline, label: 'Data stored locally only'),
                  const SizedBox(height: 12),
                  _PolicyBadge(
                      icon: Icons.visibility_off_outlined,
                      label: 'No third-party sharing'),
                  const SizedBox(height: 12),
                  _PolicyBadge(
                      icon: Icons.delete_outline, label: 'Right to erasure'),
                  const SizedBox(height: 12),
                  _PolicyBadge(
                      icon: Icons.smart_toy_outlined,
                      label: 'AI content clearly disclosed'),
                ],
              ),
            ),
          ),

          // Right consent form
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informed Consent & Privacy Notice',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please read and accept the following before using MCP StudyHub.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Section 1 — Data Privacy
                  _ConsentCard(
                    title: '1. Data Collection & Privacy (FERPA-Aligned)',
                    icon: Icons.folder_outlined,
                    color: Colors.blue,
                    content:
                        'MCP StudyHub collects the following data to personalise your learning experience:\n\n'
                        '• Grade level and subject preferences\n'
                        '• Learning style preference (visual, auditory, kinesthetic, read/write)\n'
                        '• Quiz scores and chapter completion status\n'
                        '• xAPI learning event statements (session logs)\n\n'
                        'ALL data is stored exclusively on your local device. No data is transmitted to external servers, third parties, or cloud services without your explicit additional consent.\n\n'
                        'You have the right to view, export, and permanently delete all your data at any time from the Settings screen.',
                    accepted: _privacyAccepted,
                    onAccepted: (v) => setState(() => _privacyAccepted = v!),
                  ),
                  const SizedBox(height: 20),

                  // Section 2 — AI Content
                  _ConsentCard(
                    title: '2. AI-Generated Content Disclosure',
                    icon: Icons.smart_toy_outlined,
                    color: Colors.purple,
                    content:
                        'MCP StudyHub uses the Model Context Protocol (MCP) to generate personalised educational content through AI:\n\n'
                        '• Study synthesis reports are generated by AI (Claude by Anthropic or rule-based fallback)\n'
                        '• Quiz questions are AI-generated or drawn from a curated question bank\n'
                        '• Content is tailored to your learning style and performance history\n\n'
                        'AI-generated content may contain errors. Always verify important information with your teacher or authoritative textbooks. '
                        'Academic work must reflect your own understanding — do not submit AI-generated content as your own.',
                    accepted: _aiContentAccepted,
                    onAccepted: (v) => setState(() => _aiContentAccepted = v!),
                  ),
                  const SizedBox(height: 20),

                  // Section 3 — Algorithmic Transparency
                  _ConsentCard(
                    title: '3. Algorithmic Fairness & Bias Disclosure',
                    icon: Icons.balance_outlined,
                    color: Colors.orange,
                    content:
                        'The adaptive learning algorithms in MCP StudyHub work as follows:\n\n'
                        '• Difficulty adapts based on your quiz scores: score < 50% → basic, 50–79% → standard, ≥ 80% → advanced\n'
                        '• Content is personalised based on your stated learning style\n'
                        '• Chapter recommendations are based on your completion and score history\n\n'
                        'We acknowledge that AI systems may carry biases from training data. '
                        'If you feel any content is inaccurate, inappropriate, or unfair, please flag it to your educator. '
                        'Human oversight by teachers is always recommended alongside AI-assisted learning.',
                    accepted: _dataUsageAccepted,
                    onAccepted: (v) => setState(() => _dataUsageAccepted = v!),
                  ),
                  const SizedBox(height: 40),

                  if (!_allAccepted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Please accept all three sections to continue.',
                        style: TextStyle(
                          color: scheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _allAccepted ? _proceed : null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'I Understand & Agree — Continue',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Aligned with FERPA guidelines, xAPI standards, and Anthropic\'s usage policies.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PolicyBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final bool accepted;
  final ValueChanged<bool?> onAccepted;

  const _ConsentCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    required this.accepted,
    required this.onAccepted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: accepted ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accepted ? color : Theme.of(context).colorScheme.outline,
          width: accepted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.6)),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: accepted,
              onChanged: onAccepted,
              title: Text(
                'I have read and accept this section.',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: accepted ? color : null),
              ),
              activeColor: color,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
