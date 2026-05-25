# MCP StudyHub - Implementation Walkthrough

## Overview
This document outlines the implemented architecture and features of the MCP StudyHub Windows application. The app currently runs as a standalone client with Mock MCP services.

## Project Structure
- `lib/core/`
  - `mcp/`: Contains `ClientService` which mocks the MCP primitives (Prompts, Tools, Resources).
  - `models/`: JSON-serializable models for `StudentProfile`, `Curriculum`, and `LearningContent`.
  - `providers/`: Riverpod providers for accessing Curriculum and Profile data.
- `lib/features/`
  - `onboarding/`: Profile creation logic (Grade, Interests, Learning Style).
  - `dashboard/`: Displays Grade-specific subjects.
  - `chapter_index/`: Lists chapters for a selected subject with progress tracking.
  - `learning_hub/`: The main 3-tab experience (Synthesis, Quiz, Multimedia).

## Features Implemented

### 1. Onboarding
- **User Input**: Grade selector, Interest chips, Learning style cards.
- **Persistence**: Saves `StudentProfile` to `AppData` using `path_provider`.
- **State**: Managed via `AsyncNotifier` (Manual Riverpod Implementation).

### 2. Dashboard
- **Curriculum Loading**: dynamically loads `assets/curriculum/grade_XX_curriculum.json` based on the user's grade.
- **Progress Tracking**: Reads from the `StudentProfile` to show completion bars on subject cards.

### 3. Learning Experience (MCP Integration)
The `LearningHubScreen` uses `MCPClientService` to fetch content:
- **Tab 1: Synthesis**: Calls `synthesizeReport` (simulating `synthesis_prompt`) to generate a Markdown report.
- **Tab 2: Active Learning**: Calls `generateQuiz` (simulating `scaffolding_prompt`) to create interactive quizzes.
- **Tab 3: Multimedia**: Calls `fetchResources` (simulating `fetch_multimedia` tool) to return video/article links.

## How to Run
1. **Prerequisites**: Flutter SDK installed, Visual Studio (C++ Desktop) installed.
2. **Commands**:
   ```bash
   cd mcp_studyhub
   flutter pub get
   flutter run -d windows
   ```
3. **Resetting Data**: To restart onboarding, delete the `student_profile.json` from your User AppData directory (or implement a "Reset Profile" button).

## Next Steps
- Implement real MCP Protocol connection over Stdio/SSE.
- Add "Chat with AI" feature overlay.
- Pollish UI with animations and custom Windows title bar.
