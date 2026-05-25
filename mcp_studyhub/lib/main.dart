import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/role_selection/role_selection_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/consent/consent_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/chapter_index/chapter_index_screen.dart';
import 'features/learning_hub/learning_hub_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/teacher/teacher_dashboard.dart';
import 'features/teacher/curriculum_editor_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/subject/:subjectId',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        return ChapterIndexScreen(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/learn/:chapterId',
      builder: (context, state) {
        final chapterId = state.pathParameters['chapterId']!;
        return LearningHubScreen(chapterId: chapterId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/teacher',
      builder: (context, state) => const TeacherDashboard(),
    ),
    GoRoute(
      path: '/teacher/curriculum',
      builder: (context, state) => const CurriculumEditorScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MCP StudyHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
