# MCP StudyHub — Research & Implementation Documentation

**Research Title:** Using Model Context Protocol (MCP) in Educational Curriculum Design for Students  
**Author:** Archana Gundawade  
**Date:** July 10, 2025  
**Platform:** Flutter Windows Desktop Application + Python MCP Server  
**Version:** 1.0.0

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [Research Objectives and Implementation](#3-research-objectives-and-implementation)
4. [Student Workflow](#4-student-workflow)
5. [Teacher Workflow](#5-teacher-workflow)
6. [Student Survey — Primary Research Data](#6-student-survey--primary-research-data)
7. [All Data Sources Used](#7-all-data-sources-used)
8. [Technology Stack](#8-technology-stack)
9. [File Structure](#9-file-structure)
10. [How to Run](#10-how-to-run)

---

## 1. Project Overview

MCP StudyHub is a Windows desktop application that demonstrates how **Model Context Protocol (MCP)** — Anthropic's open standard for connecting AI models to external data and tools — can be applied to educational curriculum design. The app targets Indian secondary school students in **Grade 10 and Grade 12**, delivering personalised, adaptive learning experiences while maintaining student privacy and giving teachers full visibility into learning progress.

The application consists of two components working together:

- **Flutter Windows App** — the student and teacher interface
- **Python MCP Server (`edu-mcp-server`)** — provides AI-generated content, quiz questions, multimedia resources, and performance tracking via the MCP protocol

The two communicate over **JSON-RPC 2.0 via Stdio transport**, exactly as defined in the Anthropic MCP specification (2024-11-05). When the Python server is unavailable, the app falls back to rich pre-written content so it always works.

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Windows App                   │
│                                                         │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────┐  │
│  │  Role       │   │  Student     │   │  Teacher    │  │
│  │  Selection  │──▶│  Dashboard   │   │  Dashboard  │  │
│  │  Screen     │   │  + Learning  │   │  + Curriculum│ │
│  └─────────────┘   │  Hub         │   │  Editor     │  │
│                    └──────┬───────┘   └─────────────┘  │
│                           │                             │
│                    ┌──────▼───────┐                     │
│                    │ MCPClient    │                     │
│                    │ Service      │  (MCP Host Role)    │
│                    └──────┬───────┘                     │
│                           │  JSON-RPC 2.0 / Stdio       │
└───────────────────────────┼─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                Python MCP Server                        │
│                  (edu-mcp-server)                       │
│                                                         │
│  Resources          Prompts            Tools            │
│  ─────────          ───────            ─────            │
│  student://profile  synthesis_report   fetch_resources  │
│  curriculum://      generate_quiz      record_performance│
│    chapters                            get_recommendations│
│  xapi://statements                                      │
│                           │                             │
│                    ┌──────▼───────┐                     │
│                    │ Anthropic    │  (optional)         │
│                    │ Claude API   │                     │
│                    └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

### MCP Communication Flow

```
Flutter App                         Python Server
    │                                     │
    │── initialize (JSON-RPC) ──────────▶ │
    │◀─ capabilities response ─────────── │
    │                                     │
    │── prompts/get (synthesis_report) ──▶│
    │◀─ personalised markdown content ─── │
    │                                     │
    │── tools/call (fetch_resources) ────▶│
    │◀─ JSON list of videos/articles ──── │
    │                                     │
    │── tools/call (record_performance) ─▶│
    │◀─ xAPI statement saved ──────────── │
```

---

## 3. Research Objectives and Implementation

The PhD document defines five objectives. Below is each objective, its theoretical basis, and exactly how it is implemented in the codebase.

---

### Objective 1 — MCP Technical Foundations

**Goal:** Demonstrate MCP as a viable protocol for educational AI integration by implementing all three MCP primitives (Resources, Prompts, Tools) over a real Stdio transport.

**Theoretical Basis:** Anthropic MCP Specification 2024-11-05, JSON-RPC 2.0 standard.

#### Implementation

**MCP Server** (`mcp_server/server.py`)
- Built using the official `mcp` Python library
- Implements `Server("edu-mcp-server")` with full capability negotiation
- Transport: `stdio_server()` — reads from stdin, writes to stdout

**Three MCP Primitives implemented:**

| Primitive | Name | Purpose |
|-----------|------|---------|
| Resource | `student://profile` | Exposes student profile schema |
| Resource | `curriculum://chapters` | Exposes full chapter catalogue |
| Resource | `xapi://statements` | Exposes the xAPI event log |
| Prompt | `synthesis_report` | Generates personalised study report |
| Prompt | `generate_quiz` | Generates adaptive quiz questions |
| Tool | `fetch_resources` | Returns curated videos and articles |
| Tool | `record_performance` | Saves xAPI learning statement |
| Tool | `get_recommendations` | Returns next-chapter recommendations |

**MCP Client** (`lib/core/mcp/mcp_transport.dart`, `lib/core/mcp/client_service.dart`)
- `MCPTransport` — low-level JSON-RPC 2.0 transport; spawns the Python process, handles the `initialize` handshake, routes request/response by message ID
- `MCPClientService` — high-level MCP Host; calls `getPrompt()`, `callTool()`, `readResource()` and falls back to profile-aware mock content when the server is offline

**Settings Screen** (`lib/features/settings/settings_screen.dart`)
- Shows live MCP connection status (Connected / Mock Mode)

---

### Objective 2 — Personalised and Adaptive Learning

**Goal:** Use student profile data to personalise every piece of AI-generated content and automatically adjust difficulty based on quiz performance.

**Theoretical Basis:** VARK learning style model (Fleming, 1987), ContextAgent pattern (Parsian & Khademi, 2010).  
**Survey Evidence:** Q1 showed confidence spread across all levels 1–10; Q4 showed only 16.4% prefer textbook while 83.6% prefer interactive resources; Profile types showed 42.3% average, 31.4% high performer, 26.3% at-risk — three distinct groups needing different content.

#### Implementation

**Student Profile** (`lib/core/models/student_profile.dart`)

Captures six dimensions of the learner:

```
grade          → 10 or 12 (determines curriculum)
learningStyle  → visual | auditory | kinesthetic | readWrite (VARK)
interests      → selected from 8 options (e.g. Technology, Sports)
quizScores     → Map<chapterId, score 0–100> — grows as student takes quizzes
progressTracking → Map<subject, Map<chapterId, bool>>
consentGiven   → FERPA consent flag
```

**Adaptive Difficulty** (`adaptiveDifficulty()` in `student_profile.dart`)

Maps directly to the three student profile types found in the survey:

| Quiz Score | Difficulty | Survey Profile |
|------------|-----------|---------------|
| No score yet | `standard` | — |
| < 50% | `basic` | at-risk (26.3% of surveyed students) |
| 50–79% | `standard` | average (42.3% of surveyed students) |
| ≥ 80% | `advanced` | high_performer (31.4% of surveyed students) |

**MCP Prompt personalization payload:**
```
chapter_id, grade, learning_style, interests, difficulty, previous_score
```

**Context Management Agent** (`lib/core/services/context_agent.dart`)
- `identifyGaps()` — chapters where score < 60%
- `overallMastery()` — average score across all attempted chapters
- `recommend()` — prioritises gap chapters, then next chapter per subject
- `updateFromQuizResult()` — updates profile, auto-marks complete if score ≥ 60%

---

### Objective 3 — LMS Integration via xAPI

**Goal:** Demonstrate LMS interoperability through the xAPI standard.

**Theoretical Basis:** xAPI 1.0.3 specification (ADL), SCORM/LTI standards.  
**Survey Evidence:** Q7 showed 43.5% of students rarely or never discuss topics with a teacher outside class — they need a system that logs their activity so teachers can see progress without requiring direct interaction.

#### Implementation

**xAPI Service** (`lib/core/services/xapi_service.dart`)

| Event | Trigger | xAPI Verb |
|-------|---------|-----------|
| Session Start | Student opens dashboard | `launched` (app) |
| Chapter Launch | Student opens a chapter | `launched` (module) |
| Quiz Scored | Student submits a quiz | `scored` (assessment) |
| Chapter Completed | Student marks chapter done | `completed` (module) |

Each statement follows full xAPI 1.0.3 Actor–Verb–Object–Result–Context structure with language tag `en-IN`.

**Teacher Dashboard** reads the local xAPI log: event counts by verb, last 10 events with timestamps, exportable as JSON for import into a real LRS.

---

### Objective 4 — Ethics and Privacy

**Goal:** FERPA-aligned privacy model with informed consent, AI transparency, and data deletion rights.

**Theoretical Basis:** FERPA (US Department of Education), AI ethics in educational technology.

#### Implementation

**Consent Gate** (`lib/features/consent/consent_screen.dart`) — three sections, all required:
1. Privacy & Data Storage
2. AI-Generated Content Disclosure
3. Learning Analytics

**AI Transparency Banner** (`lib/features/learning_hub/synthesis/synthesis_tab.dart`) — shows whether content is Claude-generated or mock.

**Data Rights** (`lib/features/settings/settings_screen.dart`) — export and full delete.

---

### Objective 5 — Responsible Implementation and Governance

**Goal:** Teacher visibility into algorithm decisions, safe API key handling, auditable system.

**Survey Evidence:** Q7 showed 14.6% of students never discuss with teachers — teachers need tools to proactively identify struggling students rather than waiting to be approached.

#### Implementation

**Adaptive Algorithm Rationale card** in Teacher Dashboard — shows exact score thresholds and current per-chapter difficulty assignments with evidence.

**Curriculum Editor** (`lib/features/teacher/curriculum_editor_screen.dart`) — teachers can add subjects and chapters; custom content is visually labelled.

**API Key** stored locally only, never transmitted outside `api.anthropic.com`.

---

## 4. Student Workflow

### First Launch (New Student)

```
1. App opens
        ↓
2. Role Selection Screen
   → Tap "Student"
        ↓
3. Onboarding Screen
   → Select Grade (10 or 12)
   → Select Interests (minimum 2 from 8 options)
   → Select Learning Style (Visual / Auditory / Kinesthetic / Read-Write)
   → Tap "Create Profile"
        ↓
4. Consent Screen
   → Accept all 3 FERPA-style sections
   → Tap "I Agree – Begin Learning"
        ↓
5. Student Dashboard
```

### Returning Student

```
App opens → Role Selection → "Student"
    ↓ (profile + consent already saved)
Student Dashboard (direct)
```

### Learning a Chapter

```
Student Dashboard
    │
    ├── Subjects tab → Select Subject → Chapter Index → Tap chapter
    │       ↓ (xAPI: "launched" event logged)
    │
    ├── Learning Hub — 3 tabs:
    │
    │   [1] Synthesis Tab
    │       → MCP calls synthesis_report with full student profile
    │       → Personalised markdown study report returned
    │       → Tailored to learning style + interests + adaptive difficulty
    │       → AI transparency banner shown
    │
    │   [2] Quiz Tab
    │       → MCP calls generate_quiz
    │       → 5 adaptive multiple-choice questions
    │       → All must be answered before submitting
    │       → Score calculated → (xAPI: "scored" event logged)
    │       → ContextAgent updates profile, recalculates difficulty
    │       → Auto-marked complete if score ≥ 60%
    │
    │   [3] Multimedia Tab
    │       → MCP calls fetch_resources tool
    │       → Curated videos and articles returned
    │       → Tap any → opens in browser
    │
    └── Mark Complete (AppBar button)
            ↓ (xAPI: "completed" event logged)
        Green checkmark on chapter in Chapter Index
```

### Tracking Progress

```
Student Dashboard
    ├── Progress tab
    │       → Overall mastery % bar
    │       → Per-chapter scores (green ≥ 80%, orange 50–79%, red < 50%)
    │       → Adaptive difficulty label per chapter
    │       → Learning Gaps with "Revisit" button
    │
    └── Suggested tab
            → Gap chapters prioritised first
            → Next uncompleted chapter per subject
            → "Start" button navigates directly
```

---

## 5. Teacher Workflow

### Accessing the Teacher View

```
App opens → Role Selection → Tap "Teacher"
    ↓
Teacher Dashboard
(AppBar back button → returns to Role Selection)
```

### Reviewing Student Progress

```
Teacher Dashboard
    │
    ├── Algorithmic Transparency Banner
    │       → Score < 50% → Basic | 50–79% → Standard | ≥ 80% → Advanced
    │
    ├── Student Overview Card
    │       → Grade, Learning Style, Chapters Assessed, Avg Mastery %
    │       → Progress bar per chapter (colour-coded)
    │
    ├── xAPI Event Summary
    │       → Bar chart: launched / scored / completed counts
    │
    ├── Learning Gaps
    │       → Critical (< 40%, red) or Moderate (40–59%, orange)
    │
    ├── Recent Learning Events
    │       → Last 10 xAPI statements with timestamps and scores
    │
    └── Adaptive Algorithm Rationale
            → Rules displayed in plain language
            → Current difficulty per chapter with score evidence
```

### Adding Curriculum Content

```
Teacher Dashboard → "Edit Curriculum" button
        ↓
Curriculum Editor Screen
        │
        ├── Add chapter to existing subject:
        │       → Click "Add Chapter" on any subject card
        │       → Fill: Title, Key Concepts (comma-separated), Estimated Time
        │       → Appears immediately in student's chapter list with "Custom" badge
        │
        ├── Add a new subject:
        │       → AppBar "New Subject" → enter name → add first chapter
        │       → New subject card appears on student's dashboard
        │
        └── Remove custom chapter:
                → Red delete button on custom chapters only
                → Base curriculum chapters are locked
```

> Teacher additions are saved to `teacher_curriculum_additions.json` and survive restarts.

---

## 6. Student Survey — Primary Research Data

### Overview

A structured survey was conducted with **1,000 students** from Karad, Maharashtra to understand their academic behaviours, learning preferences, and challenges. This survey provided the **primary empirical foundation** for every major design decision in MCP StudyHub.

**Survey File:** `Student_Survey_AI_Academics.xlsx`

| Field | Detail |
|-------|--------|
| Total Responses | 1,000 students |
| Location | Karad, Maharashtra (100%) |
| Grade Distribution | Grade 10: 500 students (50%) · Grade 12: 500 students (50%) |
| Institutions | 8 schools/colleges including Podar International, Shri Shivaji Vidyalaya, Ligade-Patil Jr. College, JK Academy, SGM College, YCC, Tilak High School, Holy Family Convent |

---

### Survey Questions and Results

#### Q1 — Academic Confidence (Scale 1–10)
*"How confident are you in explaining [Specific Topic] to a classmate right now?"*

| Score | Responses | % |
|-------|-----------|---|
| 1–2 (Very Low) | 171 | 17.1% |
| 3–4 (Low) | 207 | 20.7% |
| 5–6 (Moderate) | 212 | 21.2% |
| 7–8 (Good) | 212 | 21.2% |
| 9–10 (High) | 198 | 19.8% |

Confidence scores spread almost evenly across all levels — no clustering at either extreme. This confirmed that a single difficulty level would fail the majority of students.

---

#### Q2 — Focus Loss During Study (Phone checks per 2-hour session)

| Frequency | Responses | % |
|-----------|-----------|---|
| 0 (No distraction) | 330 | 33.0% |
| 1–3 times | 286 | 28.6% |
| 4–6 times | 258 | 25.8% |
| 7+ times | 126 | 12.6% |

**67% of students lose focus at least once** during a 2-hour study session. Passive reading of textbooks or PDFs cannot hold attention for this population.

---

#### Q3 — Primary Study Inhibitor

| Reason | Responses | % |
|--------|-----------|---|
| Digital distractions | 284 | 28.4% |
| Noise | 190 | 19.0% |
| Tiredness | 183 | 18.3% |
| **Lack of understanding** | **177** | **17.7%** |
| Chores | 166 | 16.6% |

**17.7% stop studying because they don't understand the material** — they hit a wall and quit. This is the precise problem adaptive difficulty solves.

---

#### Q4 — Pedagogical Preference (after failing a question)
*"Which resource helps you 'get it' the fastest?"*

| Resource | Responses | % |
|----------|-----------|---|
| **Video** | **287** | **28.7%** |
| **1-on-1 Chat** | **278** | **27.8%** |
| **Solved Example** | **271** | **27.1%** |
| Textbook | 164 | 16.4% |

Only 16.4% reach for a textbook. The majority (83.6%) prefer interactive formats — video, conversation, or worked examples.

---

#### Q5 — Academic Goal Orientation

| Goal | Responses | % |
|------|-----------|---|
| 90%+ in Board exams | 527 | 52.7% |
| Clearing JEE/NEET/CET | 418 | 41.8% |
| Just passing | 55 | 5.5% |

**94.5% of students have high academic aspirations** — board exams or competitive entrance exams. This population needs curriculum-aligned, exam-focused content, not casual learning apps.

---

#### Q6 — Persistence on Hard Problems
*"How many minutes on a single hard Math/Physics problem before giving up?"*

Most students give up between **5 and 20 minutes**. The median is approximately 15 minutes. Very few persist beyond 30 minutes on problems they cannot solve.

---

#### Q7 — Teacher/Peer Discussion Frequency

| Frequency | Responses | % |
|-----------|-----------|---|
| Weekly | 309 | 30.9% |
| Rarely | 289 | 28.9% |
| Daily | 256 | 25.6% |
| **Never** | **146** | **14.6%** |

**43.5% of students rarely or never discuss difficult topics** with a teacher or peer outside class. They have no access to on-demand explanation when they are stuck.

---

#### Student Profile Types (derived from survey responses)

| Profile | Count | % |
|---------|-------|---|
| Average | 423 | 42.3% |
| High Performer | 314 | 31.4% |
| At-Risk | 263 | 26.3% |

---

### How the Survey Shaped the Project

Every major feature in MCP StudyHub can be traced back to a specific survey finding:

---

#### Finding 1 → Three-Tier Adaptive Difficulty

**Survey:** Q1 showed confidence uniformly spread across all levels. Profile types confirmed three distinct groups: at-risk (26.3%), average (42.3%), high performer (31.4%).

**Design Response:** The adaptive difficulty system uses three exact tiers — `basic`, `standard`, `advanced` — that map directly to these three student profiles. The thresholds (< 50%, 50–79%, ≥ 80%) were calibrated to these proportions. A student in the at-risk category automatically receives simplified, scaffolded content; a high performer unlocks deeper analysis.

---

#### Finding 2 → Multimedia Tab with Videos

**Survey:** Q4 showed **28.7% of students prefer video** as the fastest way to understand content they got wrong.

**Design Response:** The Multimedia tab calls the MCP `fetch_resources` tool to return curated YouTube videos for every chapter. Each chapter in the MCP server database (`server.py`) has hand-selected video links — not generic search results — chosen for their alignment with the NCERT syllabus.

---

#### Finding 3 → AI Synthesis as a 1-on-1 Tutor Analog

**Survey:** Q4 showed **27.8% prefer 1-on-1 Chat** and **27.1% prefer Solved Examples**. Q7 showed 43.5% rarely or never have access to a teacher outside class.

**Design Response:** The AI synthesis report (Objective 2) is explicitly designed as an always-available tutor analog. It uses a conversational, personalised tone adapted to the student's learning style, includes worked examples at the appropriate difficulty level, and provides explanations that mirror what a teacher would say in a 1-on-1 session. For students who can never ask a teacher, this is the substitute.

---

#### Finding 4 → Adaptive Difficulty Prevents Giving Up

**Survey:** Q3 showed **17.7% stop studying due to lack of understanding**. Q6 showed most students give up on hard problems within 15 minutes.

**Design Response:** When a student scores below 50% on a quiz, the next visit to that chapter automatically switches to `basic` difficulty — simpler language, foundational focus, extra scaffolding in both the synthesis report and the quiz questions. This directly addresses the "hit a wall and quit" behaviour observed in 17.7% of the survey respondents.

---

#### Finding 5 → NCERT-Aligned Board Exam Content

**Survey:** Q5 showed **52.7% target 90%+ in Board exams**, **41.8% target JEE/NEET/CET**. Location data confirmed 100% of respondents are from Maharashtra (India).

**Design Response:** All curriculum content is sourced from **NCERT textbooks** — the official Indian national curriculum used in CBSE board exams and as the basis for JEE/NEET preparation. The subjects (Physics, Mathematics, Chemistry, Biology, Computer Science) and chapters are the exact ones examined in Grade 10 and Grade 12 boards. This was not an arbitrary choice — it was dictated by the survey's goal distribution.

---

#### Finding 6 → Engagement Over Static Content

**Survey:** Q2 showed **67% of students lose focus during a 2-hour study session**, with digital distractions being the #1 study inhibitor (Q3: 28.4%).

**Design Response:** The app is structured as short, focused chapter sessions (estimated times range from 40–90 minutes) with active components — adaptive quiz, progress bars, recommendations, and a score badge after completion. Passive reading is replaced by interactive learning. The 3-tab chapter structure (Synthesis → Quiz → Multimedia) creates a natural progression that keeps engagement higher than a static PDF.

---

#### Finding 7 → Teacher Dashboard for Proactive Monitoring

**Survey:** Q7 showed **14.6% never discuss with teachers** and 28.9% rarely do. Teachers may not know which students are struggling until it is too late.

**Design Response:** The Teacher Dashboard was built so teachers do not need students to come to them. The xAPI event log shows exactly which chapters each student opened, when, and with what score. The Learning Gaps section automatically surfaces students (and chapters) that need intervention, classified by severity. Teachers can be proactive rather than reactive.

---

#### Finding 8 → Interests-Based Content Personalisation

**Survey:** Student profiles include a wide range of backgrounds across 8 institutions. Engagement with content is higher when it connects to the student's personal context.

**Design Response:** The onboarding screen collects student interests (Sports, Gaming, Technology, Arts, Science, History, Music, Reading). These interests are passed to the MCP `synthesis_report` prompt, which instructs Claude to connect the chapter's concepts to those interests — for example, linking Physics optics concepts to a student who selected Technology or Gaming.

---

### Survey Validity

| Criterion | Detail |
|-----------|--------|
| Sample Size | 1,000 students — statistically significant for the target population |
| Geographic Focus | Karad, Maharashtra — consistent with the NCERT curriculum context |
| Grade Balance | Exactly 50/50 split between Grade 10 and Grade 12 |
| Institutional Diversity | 8 different schools/colleges representing different socioeconomic contexts |
| Data Format | Structured questionnaire with quantifiable responses (7 questions + metadata) |

---

## 7. All Data Sources Used

### 1. Student Survey (Primary Research Data — collected by researcher)

**File:** `Student_Survey_AI_Academics.xlsx`  
1,000 student responses from Karad, Maharashtra. This is the primary empirical dataset collected specifically for this research. It informed the adaptive difficulty thresholds, content format choices, multimedia inclusion, and teacher dashboard design. See Section 6 for full analysis.

---

### 2. NCERT Curriculum (National Council of Educational Research and Training)

All chapter titles, key concepts, quiz questions, and formulas come from NCERT textbooks — India's national school curriculum, used for CBSE board exams.

**Grade 10 — 11 chapters across 4 subjects:**

| Subject | Chapters |
|---------|----------|
| Physics | Light & Optics, Human Eye, Electricity |
| Mathematics | Real Numbers, Polynomials, Quadratic Equations |
| Chemistry | Chemical Reactions, Acids Bases & Salts |
| Biology | Life Processes, Nervous System & Hormones |

**Grade 12 — 11 chapters across 4 subjects:**

| Subject | Chapters |
|---------|----------|
| Physics | Electrostatics, Capacitance, Current Electricity |
| Mathematics | Relations & Functions, Derivatives, Integrals |
| Computer Science | Python Programming, Data Structures |
| Chemistry | Electrochemistry, Chemical Kinetics |

Total: **22 chapters, 110 quiz questions**, all formulas sourced from NCERT syllabus.

---

### 3. VARK Learning Style Model (Fleming, 1987)

| Style | Description |
|-------|-------------|
| Visual | Diagrams, spatial layouts, colour-coded notes |
| Auditory | Conversational tone, narrative, "read aloud" |
| Kinesthetic | Step-by-step procedures, hands-on prompts |
| Read/Write | Formal prose, structured headings, glossary |

---

### 4. xAPI Standard — ADL (Advanced Distributed Learning Initiative)

xAPI 1.0.3. Official verb URIs: `launched`, `scored`, `completed`. Statement format: Actor–Verb–Object–Result–Context. Language tag: `en-IN`.

---

### 5. Anthropic MCP Specification (2024-11-05)

JSON-RPC 2.0 message format, Stdio transport, three primitive types (Resources, Prompts, Tools), capability negotiation handshake, Host/Client/Server role separation.

---

### 6. Context Management Agent Pattern (Parsian & Khademi, 2010)

Published research pattern for learner models in adaptive educational systems. Implemented in `lib/core/services/context_agent.dart`.

---

### 7. FERPA Privacy Framework (US Department of Education)

Provides the ethics model: right to know, right to control (consent gate), right to erasure (delete all data).

---

### 8. Open Educational Resources (Multimedia)

| Source | Type |
|--------|------|
| YouTube | Videos (3Blue1Brown, Khan Academy, subject-specific educators) |
| Wikipedia | Reference articles |
| Khan Academy | Structured subject articles |
| NCERT official site | Official PDF textbooks (`ncert.nic.in`) |

---

## 8. Technology Stack

### Flutter Application

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 3.2.0 | State management (AsyncNotifierProvider) |
| `go_router` | 17.0.1 | Declarative routing |
| `flutter_markdown` | 0.7.7 | Render AI-generated markdown reports |
| `path_provider` | 2.1.5 | Access app documents directory |
| `url_launcher` | 6.3.2 | Open multimedia links in browser |
| `json_annotation` | 4.9.0 | JSON serialisation |
| `json_serializable` | 6.11.2 | Code-gen for `.g.dart` files |

### Python MCP Server

| Package | Purpose |
|---------|---------|
| `mcp` | Official Anthropic MCP library |
| `anthropic` | Claude API client (optional — for live AI content) |
| `asyncio` | Async event loop |

---

## 9. File Structure

```
mcp_edu_carriculumn/
│
├── Student_Survey_AI_Academics.xlsx        Primary survey data (1,000 students)
│
├── mcp_server/
│   └── server.py                           Python MCP server — Resources, Prompts, Tools
│
└── mcp_studyhub/
    ├── pubspec.yaml
    ├── assets/curriculum/
    │   ├── grade_10_curriculum.json        NCERT Grade 10 — 4 subjects, 11 chapters
    │   └── grade_12_curriculum.json        NCERT Grade 12 — 4 subjects, 11 chapters
    │
    └── lib/
        ├── main.dart                       App entry point, GoRouter routes
        ├── core/
        │   ├── models/
        │   │   ├── student_profile.dart    StudentProfile, LearningStyle, adaptiveDifficulty()
        │   │   ├── curriculum.dart         Chapter, Subject, Curriculum models
        │   │   └── learning_content.dart   QuizQuestion, MultimediaResource
        │   ├── mcp/
        │   │   ├── mcp_transport.dart      JSON-RPC 2.0 Stdio transport
        │   │   └── client_service.dart     MCP Host — Prompts, Tools, Resources
        │   ├── providers/
        │   │   ├── curriculum_provider.dart         Loads + merges curriculum
        │   │   └── teacher_curriculum_provider.dart Teacher-added content
        │   └── services/
        │       ├── context_agent.dart      Adaptive difficulty, gaps, recommendations
        │       └── xapi_service.dart       xAPI 1.0.3 local LRS
        │
        └── features/
            ├── role_selection/             Launch screen — Student or Teacher path
            ├── onboarding/                 Grade, interests, learning style setup
            ├── consent/                    3-section FERPA consent gate
            ├── dashboard/                  Subjects, Progress, Suggested tabs
            ├── chapter_index/              Chapter list with completion status
            ├── learning_hub/               Synthesis, Quiz, Multimedia tabs
            ├── teacher/                    Analytics dashboard + curriculum editor
            └── settings/                  MCP status, data export, delete
```

---

## 10. How to Run

### Prerequisites

- Flutter SDK (3.32 or later) with Windows desktop enabled
- Python 3.9+ (optional — for real Claude AI content)
- Anthropic API key (optional)

### Run the Flutter App

```bash
cd mcp_studyhub
flutter pub get
flutter run -d windows
```

### Run with Real AI Content (Optional)

```bash
cd mcp_server
pip install mcp anthropic
set ANTHROPIC_API_KEY=sk-ant-...
```

The app automatically finds and launches `mcp_server/server.py`. The Settings screen confirms whether MCP is connected or running in mock mode.

### Without Python

All 22 chapters have rich pre-written fallback content that is still personalised to the student's learning style, interests, and quiz performance. The only difference is content is not live Claude-generated.

---

## Summary: Objective Completion Status

| Objective | Description | Survey Evidence | Status |
|-----------|-------------|-----------------|--------|
| 1 | MCP Technical Foundations | — | Complete |
| 2 | Personalised & Adaptive Learning | Q1 confidence spread, Q4 preferences, Profile types | Complete |
| 3 | LMS Integration (xAPI) | Q7 teacher access gap | Complete |
| 4 | Ethics & Privacy (FERPA) | Student data rights | Complete |
| 5 | Responsible Implementation | Q7 teacher monitoring need | Complete |

`flutter analyze` result: **0 issues**

---

*MCP StudyHub — Research Prototype for PhD Submission*  
*Archana Gundawade — July 2025*  
*Survey: 1,000 students, Karad Maharashtra · Built with Flutter 3.32, Dart 3.10, Python MCP 1.0, Anthropic Claude Sonnet 4.6*
