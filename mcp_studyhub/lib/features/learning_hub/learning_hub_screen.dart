import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/xapi_service.dart';
import '../onboarding/student_profile_provider.dart';
import 'synthesis/synthesis_tab.dart';
import 'active_learning/active_learning_tab.dart';
import 'multimedia/multimedia_tab.dart';

class LearningHubScreen extends ConsumerStatefulWidget {
  final String chapterId;
  const LearningHubScreen({super.key, required this.chapterId});

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen> {
  bool _markingComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logLaunch());
  }

  Future<void> _logLaunch() async {
    final profile = ref.read(studentProfileProvider).value;
    if (profile == null) return;
    final name = profile.studentName ?? profile.interests.firstOrNull ?? 'Student';
    await XApiService.logChapterLaunched(
      chapterId: widget.chapterId,
      chapterTitle: _chapterTitle(widget.chapterId),
      studentName: name,
    );
  }

  Future<void> _markComplete() async {
    final profile = ref.read(studentProfileProvider).value;
    if (profile == null || _markingComplete) return;
    setState(() => _markingComplete = true);

    final subject = _inferSubject(widget.chapterId);
    final name = profile.studentName ?? profile.interests.firstOrNull ?? 'Student';

    // Update progress tracking
    await ref
        .read(studentProfileProvider.notifier)
        .updateProgress(subject, widget.chapterId, true);

    // Log xAPI completion
    await XApiService.logChapterCompleted(
      chapterId: widget.chapterId,
      chapterTitle: _chapterTitle(widget.chapterId),
      studentName: name,
    );

    setState(() => _markingComplete = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_chapterTitle(widget.chapterId)} marked complete!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _inferSubject(String chapterId) {
    if (chapterId.startsWith('phys')) return 'Physics';
    if (chapterId.startsWith('math')) return 'Mathematics';
    if (chapterId.startsWith('chem')) return 'Chemistry';
    if (chapterId.startsWith('bio')) return 'Biology';
    if (chapterId.startsWith('cs')) return 'Computer Science';
    return 'General';
  }

  String _chapterTitle(String chapterId) {
    const titles = {
      'phys_10_01': 'Light – Reflection and Refraction',
      'phys_10_02': 'The Human Eye and the Colourful World',
      'phys_10_03': 'Electricity',
      'math_10_01': 'Real Numbers',
      'math_10_02': 'Polynomials',
      'math_10_03': 'Quadratic Equations',
      'chem_10_01': 'Chemical Reactions and Equations',
      'chem_10_02': 'Acids, Bases and Salts',
      'bio_10_01': 'Life Processes',
      'bio_10_02': 'Control and Coordination',
      'phys_12_01': 'Electric Charges and Fields',
      'phys_12_02': 'Electrostatic Potential and Capacitance',
      'phys_12_03': 'Current Electricity',
      'math_12_01': 'Relations and Functions',
      'math_12_02': 'Calculus – Derivatives',
      'math_12_03': 'Integrals',
      'cs_12_01': 'Python Revision Tour',
      'cs_12_02': 'Data Structures in Python',
      'chem_12_01': 'Electrochemistry',
      'chem_12_02': 'Chemical Kinetics',
    };
    return titles[chapterId] ?? chapterId.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(studentProfileProvider).value;
    final subject = _inferSubject(widget.chapterId);
    final isCompleted =
        profile?.progressTracking[subject]?[widget.chapterId] == true;

    const tabs = [
      Tab(text: 'Synthesis', icon: Icon(Icons.auto_awesome)),
      Tab(text: 'Active Learning', icon: Icon(Icons.school)),
      Tab(text: 'Multimedia', icon: Icon(Icons.video_library)),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_chapterTitle(widget.chapterId)),
          bottom: const TabBar(tabs: tabs),
          actions: [
            if (_markingComplete)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: isCompleted
                    ? const Chip(
                        avatar: Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        label: Text('Completed'),
                      )
                    : FilledButton.icon(
                        onPressed: _markComplete,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Complete'),
                      ),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            SynthesisTab(chapterId: widget.chapterId),
            ActiveLearningTab(chapterId: widget.chapterId),
            MultimediaTab(chapterId: widget.chapterId),
          ],
        ),
      ),
    );
  }
}
