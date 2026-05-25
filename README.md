# MCP StudyHub

**Using Model Context Protocol (MCP) in Educational Curriculum Design for Students**

A research prototype demonstrating how the [Model Context Protocol](https://modelcontextprotocol.io) can power adaptive, personalised learning in secondary education. Built as part of a PhD research submission (Archana Gundawade, July 2025).

---

## Overview

MCP StudyHub is a Windows desktop application that connects a Flutter frontend to a Python MCP server. The server exposes the three MCP primitives — **Resources**, **Prompts**, and **Tools** — to deliver AI-driven, VARK-adaptive learning content aligned with the Indian NCERT curriculum (Grade 10 and Grade 12).

The system was designed based on primary empirical data from a survey of **1,000 students** across Karad, Maharashtra, which informed VARK learning style distribution, preferred study aids, and AI acceptance patterns incorporated into the design.

---

## Architecture

```
┌─────────────────────────────────┐        stdio (JSON-RPC 2.0)        ┌──────────────────────────────┐
│       Flutter Windows App        │ ◄────────────────────────────────► │    Python MCP Server          │
│                                  │         MCP spec 2024-11-05        │                               │
│  Role Selection → Onboarding     │                                    │  Resources                    │
│  Consent Gate (FERPA-aligned)    │                                    │   · student://profile         │
│  Student Dashboard               │                                    │   · curriculum://chapters     │
│  Learning Hub (Synthesis,        │                                    │   · xapi://statements         │
│    Multimedia, Active Learning)  │                                    │                               │
│  Teacher Dashboard               │                                    │  Prompts                      │
│  Curriculum Editor               │                                    │   · synthesis_report          │
│                                  │                                    │   · generate_quiz             │
│  State: Riverpod v3              │                                    │                               │
│  Routing: GoRouter v17           │                                    │  Tools                        │
│  Persistence: path_provider      │                                    │   · fetch_resources           │
└─────────────────────────────────┘                                    │   · record_performance        │
                                                                        │   · get_recommendations       │
                                                                        │                               │
                                                                        │  AI: Anthropic / OpenAI /     │
                                                                        │      Gemini / DeepSeek /      │
                                                                        │      Groq / Ollama / custom   │
                                                                        └──────────────────────────────┘
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.32 |
| Dart SDK | ≥ 3.10 |
| Python | ≥ 3.11 |
| Windows | 10 / 11 (x64) |

---

## Setup

### 1. Python MCP Server

```bash
cd mcp_server
pip install mcp anthropic openai
```

> `openai` is required only if you use Gemini, DeepSeek, Groq, Ollama, or a custom endpoint.
> `anthropic` is required only if you use Claude.

### 2. Flutter App

```bash
cd mcp_studyhub
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

---

## AI Provider Configuration

Set environment variables before launching the app. The server auto-detects the provider from whichever API key is present. Use `AI_PROVIDER` to override.

| Provider | Environment Variables | Default Model |
|----------|-----------------------|---------------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | `claude-sonnet-4-6` |
| OpenAI | `OPENAI_API_KEY` | `gpt-4o` |
| Google Gemini | `GEMINI_API_KEY` | `gemini-2.0-flash` |
| DeepSeek | `DEEPSEEK_API_KEY` | `deepseek-chat` |
| Groq | `GROQ_API_KEY` | `llama-3.1-8b-instant` |
| Ollama (local) | *(no key needed)* | `llama3.2` |
| Custom endpoint | `AI_API_KEY` + `AI_BASE_URL` | set `AI_MODEL` |

**Optional overrides:**

```bash
# Force a specific provider
AI_PROVIDER=gemini

# Override the model for any provider
AI_MODEL=gemini-1.5-pro

# Custom OpenAI-compatible endpoint
AI_PROVIDER=openai_compatible
AI_BASE_URL=https://your-endpoint.com/v1
AI_API_KEY=your-key
AI_MODEL=your-model
```

If no API key is set, the server falls back to high-quality static content generated from the built-in NCERT curriculum database.

---

## Features

### Student Flow

| Feature | Description |
|---------|-------------|
| Role Selection | Launch screen separates student and teacher paths |
| Onboarding | VARK learning style quiz + interests + grade selection |
| Consent Gate | 3-section FERPA-aligned privacy consent |
| Dashboard | Subject cards per grade with progress indicators |
| Learning Hub | Three-tab view per chapter |
| — Synthesis | AI-generated personalised study report (VARK-adapted) |
| — Multimedia | Curated videos and articles from NCERT-aligned sources |
| — Active Learning | Adaptive MCQ quiz with immediate feedback |
| Adaptive Difficulty | Auto-adjusts: basic (<50%), standard (50–79%), advanced (≥80%) |
| xAPI Logging | Every quiz attempt recorded as an ADL xAPI 1.0.3 statement |
| Recommendations | Next-chapter suggestions based on score history |

### Teacher Flow

| Feature | Description |
|---------|-------------|
| Teacher Dashboard | Class overview with student performance summary |
| Curriculum Editor | Add/remove subjects and chapters per grade |
| Custom Chapters | Teacher-added content flagged with "Custom" badge |
| Persistence | Custom curriculum additions saved locally to JSON |
| Live Merge | Student view refreshes immediately after teacher edits |

---

## Curriculum Coverage

**Grade 10** — Physics (3), Mathematics (3), Chemistry (2), Biology (2)

**Grade 12** — Physics (3), Mathematics (3), Chemistry (2), Computer Science (2)

All 22 base chapters include hand-authored quizzes, key formulas, YouTube video links, and Wikipedia/NCERT article links aligned with the Indian NCERT syllabus.

---

## Project Structure

```
mcp_edu_carriculumn/
├── mcp_server/
│   ├── server.py                  # MCP server (Resources, Prompts, Tools)
│   ├── requirements.txt
│   └── xapi_statements.json       # Generated at runtime — xAPI log
│
├── mcp_studyhub/
│   ├── lib/
│   │   ├── main.dart              # App entry, GoRouter config
│   │   ├── core/
│   │   │   ├── models/            # Curriculum, StudentProfile, LearningContent
│   │   │   ├── mcp/               # MCP transport + client service
│   │   │   ├── providers/         # curriculum_provider, teacher_curriculum_provider
│   │   │   └── services/          # context_agent, xapi_service
│   │   └── features/
│   │       ├── role_selection/    # Launch screen
│   │       ├── onboarding/        # VARK quiz + profile setup
│   │       ├── consent/           # Privacy consent gate
│   │       ├── dashboard/         # Subject grid
│   │       ├── chapter_index/     # Chapter list per subject
│   │       ├── learning_hub/      # Synthesis / Multimedia / Active Learning tabs
│   │       ├── settings/          # App settings
│   │       └── teacher/           # Teacher dashboard + curriculum editor
│   ├── assets/
│   │   └── curriculum/
│   │       ├── grade_10_curriculum.json
│   │       └── grade_12_curriculum.json
│   └── pubspec.yaml
│
├── Student_Survey_AI_Academics.xlsx   # Primary research data (1,000 students, Karad)
├── mcp_studyhub_research_and_implementation.md  # Full research documentation
└── README.md
```

---

## Key Dependencies

**Flutter (pubspec.yaml)**

| Package | Purpose |
|---------|---------|
| `flutter_riverpod ^3.2.0` | State management (AsyncNotifierProvider) |
| `go_router ^17.0.1` | Declarative routing |
| `flutter_markdown ^0.7.7` | Render AI synthesis reports |
| `path_provider ^2.1.5` | Local JSON persistence |
| `url_launcher ^6.3.2` | Open video/article links |
| `json_serializable ^6.11.2` | Code-gen model serialization |

**Python (requirements.txt)**

| Package | Purpose |
|---------|---------|
| `mcp ≥ 1.0.0` | MCP server runtime (JSON-RPC 2.0 stdio) |
| `anthropic ≥ 0.34.0` | Claude API client |
| `openai` | OpenAI + compatible providers (Gemini, DeepSeek, Groq, Ollama) |

---

## MCP Primitives Used

| Primitive | Name | Purpose |
|-----------|------|---------|
| Resource | `student://profile` | Student profile schema |
| Resource | `curriculum://chapters` | Full chapter catalogue |
| Resource | `xapi://statements` | xAPI learning event log |
| Prompt | `synthesis_report` | Personalised VARK-adapted study report |
| Prompt | `generate_quiz` | Adaptive MCQ quiz generation |
| Tool | `fetch_resources` | Curated videos and articles per chapter |
| Tool | `record_performance` | Write xAPI 1.0.3 statement to local LRS |
| Tool | `get_recommendations` | Next-chapter recommendations by score |

---

## Research Context

This project was built to demonstrate five PhD research objectives:

1. Implement MCP Resources, Prompts, and Tools for structured educational context
2. Adapt content delivery to individual VARK learning styles
3. Track learning progress using the xAPI standard
4. Apply the ContextAgent pattern for adaptive difficulty
5. Provide a teacher interface for curriculum customisation

**Primary data source:** Student survey (N=1,000, Karad Maharashtra) covering AI tool usage, preferred learning modalities, study aid preferences, and academic performance — directly informing the VARK weighting, adaptive difficulty thresholds, and content type prioritisation in this system.

---

## Running Tests

```bash
# Flutter static analysis
cd mcp_studyhub
flutter analyze

# Flutter widget tests
flutter test

# MCP server smoke test (no API key needed)
cd mcp_server
python -X utf8 server.py
```

---

## License

Research prototype — not licensed for production or commercial use.
