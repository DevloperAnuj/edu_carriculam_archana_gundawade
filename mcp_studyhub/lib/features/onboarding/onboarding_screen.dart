import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/student_profile.dart';
import 'student_profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _selectedGrade = 10;
  final List<String> _selectedInterests = [];
  LearningStyle? _selectedLearningStyle;

  final List<String> _availableInterests = [
    'Sports',
    'Gaming',
    'Technology',
    'Arts',
    'Science',
    'History',
    'Music',
    'Reading',
  ];

  @override
  void initState() {
    super.initState();
    // Check if profile exists and redirect if so
    // Ideally this check happens in a splash screen or route guard,
    // but for MVP doing it here or in the build method is acceptable.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileState = ref.read(studentProfileProvider);
      final profile = profileState.value;
      if (profile == null) return;
      if (profile.consentGiven) {
        context.go('/dashboard');
      } else {
        context.go('/consent');
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Future<void> _submitProfile() async {
    if (_selectedInterests.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 interests')),
      );
      return;
    }
    if (_selectedLearningStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a learning style')),
      );
      return;
    }

    final newProfile = StudentProfile(
      grade: _selectedGrade,
      interests: _selectedInterests,
      learningStyle: _selectedLearningStyle!,
    );

    await ref.read(studentProfileProvider.notifier).saveProfile(newProfile);
    if (mounted) {
      context.go('/consent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(studentProfileProvider);

    // If loading, show spinner
    if (profileState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If we already have data (and didn't redirect quickly enough), show empty or loading
    // In a real app we'd handle the redirect better.

    return Scaffold(
      body: Row(
        children: [
          // Left Side: Hero Image / Branding
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hub,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "MCP StudyHub",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your AI-Powered Learning Companion",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Form
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(40),
              child: ListView(
                children: [
                  Text(
                    "Welcome! Note: This app manages your setup.",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 30),

                  // Grade Selection
                  Text(
                    "Select Grade",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 10, label: Text('Grade 10')),
                      ButtonSegment(value: 12, label: Text('Grade 12')),
                    ],
                    selected: {_selectedGrade},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        _selectedGrade = newSelection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Interests
                  Text(
                    "Select Interests (Min 2)",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableInterests.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (_) => _toggleInterest(interest),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  // Learning Style
                  Text(
                    "Learning Style",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _LearningStyleCard(
                    title: "Visual",
                    description: "I learn best by seeing charts and diagrams.",
                    icon: Icons.visibility,
                    value: LearningStyle.visual,
                    groupValue: _selectedLearningStyle,
                    onChanged: (val) =>
                        setState(() => _selectedLearningStyle = val),
                  ),
                  _LearningStyleCard(
                    title: "Auditory",
                    description: "I learn best by listening to explanations.",
                    icon: Icons.headphones,
                    value: LearningStyle.auditory,
                    groupValue: _selectedLearningStyle,
                    onChanged: (val) =>
                        setState(() => _selectedLearningStyle = val),
                  ),
                  _LearningStyleCard(
                    title: "Kinesthetic",
                    description: "I learn best by doing and practicing.",
                    icon: Icons.build,
                    value: LearningStyle.kinesthetic,
                    groupValue: _selectedLearningStyle,
                    onChanged: (val) =>
                        setState(() => _selectedLearningStyle = val),
                  ),
                  _LearningStyleCard(
                    title: "Read/Write",
                    description:
                        "I learn best by reading text and taking notes.",
                    icon: Icons.book,
                    value: LearningStyle.readWrite,
                    groupValue: _selectedLearningStyle,
                    onChanged: (val) =>
                        setState(() => _selectedLearningStyle = val),
                  ),

                  const SizedBox(height: 40),

                  FilledButton(
                    onPressed: _submitProfile,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text("Create Profile"),
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

class _LearningStyleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LearningStyle value;
  final LearningStyle? groupValue;
  final ValueChanged<LearningStyle?> onChanged;

  const _LearningStyleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RadioGroup<LearningStyle>(
                groupValue: groupValue,
                onChanged: onChanged,
                child: Radio<LearningStyle>(value: value),
              ),
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
