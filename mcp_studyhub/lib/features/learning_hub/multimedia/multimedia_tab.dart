import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/mcp/client_service.dart';
import '../../../core/models/learning_content.dart';
import '../../../features/onboarding/student_profile_provider.dart';

final resourcesProvider =
    FutureProvider.family<List<MultimediaResource>, String>(
        (ref, chapterId) async {
  final service = ref.watch(mcpClientServiceProvider);
  final profile = ref.watch(studentProfileProvider).value;
  if (profile == null) return [];
  return service.fetchResources(chapterId, profile: profile);
});

class MultimediaTab extends ConsumerWidget {
  final String chapterId;
  const MultimediaTab({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider(chapterId));

    return resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
      data: (resources) {
        if (resources.isEmpty) {
          return const Center(child: Text('No resources found.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final res = resources[index];
            return _ResourceCard(resource: res);
          },
        );
      },
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final MultimediaResource resource;
  const _ResourceCard({required this.resource});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(resource.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: ${resource.url}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black12),
          Center(
            child: Icon(
              resource.type == 'video'
                  ? Icons.play_circle_fill
                  : Icons.article,
              size: 64,
              color: Colors.white70,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    resource.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _open(context),
            ),
          ),
        ],
      ),
    );
  }
}
