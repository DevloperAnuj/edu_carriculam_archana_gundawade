import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mcp/client_service.dart';
import '../../../features/onboarding/student_profile_provider.dart';

final synthesisReportProvider = FutureProvider.family<String, String>((
  ref,
  chapterId,
) async {
  final service = ref.watch(mcpClientServiceProvider);
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) {
    return '# Profile Required\n\nPlease complete onboarding to receive personalised content.';
  }
  return service.synthesizeReport(chapterId, profile: profile);
});

class SynthesisTab extends ConsumerWidget {
  final String chapterId;

  const SynthesisTab({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(synthesisReportProvider(chapterId));
    final mcp = ref.watch(mcpClientServiceProvider);

    return Row(
      children: [
        // Report Column
        Expanded(
          flex: 2,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                // AI Transparency Banner
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.purple.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined,
                          size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mcp.isConnected
                              ? 'AI-generated via MCP Server (Claude API) — verify with authoritative sources'
                              : 'AI-generated via Enhanced Mock — verify with authoritative sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: reportAsync.when(
                      data: (report) => Markdown(data: report),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, st) =>
                          Center(child: Text('Error: $err')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Mindmap / Actions Column
        Expanded(
          flex: 1,
          child: Card(
            margin: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hub, size: 64),
                const SizedBox(height: 16),
                const Text('Concept Map'),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Expand'),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(synthesisReportProvider(chapterId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Content is personalised to your grade, learning style, and adaptive difficulty level.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
