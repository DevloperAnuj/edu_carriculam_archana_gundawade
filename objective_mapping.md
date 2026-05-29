# Project Objective Mapping

**Project:** Using Model Context Protocol (MCP) in Educational Curriculum Design for Students  
**Author:** Archana Gundawade · July 2025  
**Status:** All 5 Objectives — Complete

This document maps every PhD research objective to the exact components built, files written, survey questions that justify them, and the measurable outcomes that prove completion.

---

## Objective 1 — MCP Technical Foundations

> **Goal:** Demonstrate MCP as a viable protocol for educational AI integration by implementing all three MCP primitives — Resources, Prompts, and Tools — over a real JSON-RPC 2.0 Stdio transport.

---

### What Was Required

- A working MCP server using the official `mcp` Python library
- All three primitives implemented and accessible to the Flutter client
- A real transport layer (Stdio, not mocked)
- A Flutter MCP Host that connects, negotiates capabilities, and calls each primitive
- Support for multiple AI providers (not locked to one vendor)

---

### What Was Built

#### Python MCP Server (`mcp_server/server.py`)

| Component | Detail |
|-----------|--------|
| Protocol | MCP Specification 2024-11-05 · JSON-RPC 2.0 |
| Transport | `stdio_server()` — reads from stdin, writes to stdout |
| Library | `mcp >= 1.0.0` (Anthropic official Python SDK) |
| Server name | `edu-mcp-server` v1.0.0 |
| Capability negotiation | Full `InitializationOptions` handshake |

**Three MCP Primitives implemented:**

| Primitive | Name | What it returns |
|-----------|------|----------------|
| Resource | `student://profile` | Student profile schema (JSON) |
| Resource | `curriculum://chapters` | All 22 chapters with titles and concepts (JSON) |
| Resource | `xapi://statements` | Full xAPI event log from local LRS (JSON) |
| Prompt | `synthesis_report` | AI-generated personalised study report (Markdown) |
| Prompt | `generate_quiz` | 5 adaptive MCQ questions (JSON array) |
| Tool | `fetch_resources` | Curated YouTube videos and articles per chapter |
| Tool | `record_performance` | Writes xAPI 1.0.3 statement to local LRS |
| Tool | `get_recommendations` | Next-chapter suggestions ranked by score gaps |

**Multi-provider AI layer:**

| Provider | Key Variable | Default Model |
|----------|-------------|---------------|
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | `claude-sonnet-4-6` |
| OpenAI | `OPENAI_API_KEY` | `gpt-4o` |
| Google Gemini | `GEMINI_API_KEY` | `gemini-2.0-flash` |
| DeepSeek | `DEEPSEEK_API_KEY` | `deepseek-chat` |
| Groq | `GROQ_API_KEY` | `llama-3.1-8b-instant` |
| Ollama (local) | *(none)* | `llama3.2` |
| Custom endpoint | `AI_API_KEY` + `AI_BASE_URL` | set via `AI_MODEL` |

All non-Anthropic providers use the OpenAI-compatible `/v1/chat/completions` endpoint, so the same `openai` Python SDK handles all of them.

#### Flutter MCP Client

| File | Role |
|------|------|
| `lib/core/mcp/mcp_transport.dart` | Low-level JSON-RPC 2.0 transport — spawns the Python process, sends `initialize`, routes messages by ID |
| `lib/core/mcp/client_service.dart` | High-level MCP Host — `getPrompt()`, `callTool()`, `readResource()` with offline fallback |

#### MCP Connection Status

`lib/features/settings/settings_screen.dart` — live indicator showing **Connected** (real MCP) or **Mock Mode** (offline fallback), so the user always knows which mode is active.

---

### Survey Evidence

| Question | Finding | Connection to Objective |
|----------|---------|------------------------|
| Q5 — Goal Orientation | 94.5% target Board exams or JEE/NEET/CET | Content delivered through MCP must be NCERT-aligned and exam-focused |
| Q9 — AI Tool Usage | 65%+ of high performers already use AI regularly/daily | Student population is receptive to AI-delivered content; MCP is the right delivery mechanism |
| Q10 — AI Trust Score | High performers: mean 3.86/5 | Trust levels are above neutral — AI content via MCP will be accepted |

---

### Accomplishment Evidence

- `python mcp_server/server.py` starts without error
- Flutter app launches the Python process, completes `initialize` handshake
- All 8 primitives return valid responses (tested end-to-end)
- Server falls back gracefully to static content when no API key is set
- `flutter analyze` — 0 issues

---

## Objective 2 — Personalised and Adaptive Learning

> **Goal:** Use student profile data to personalise every piece of AI-generated content and automatically adjust difficulty based on quiz performance.

**Theoretical Basis:** VARK learning style model (Fleming, 1987) · ContextAgent pattern (Parsian & Khademi, 2010)

---

### What Was Required

- A student profile capturing learning style, grade, interests, and performance history
- VARK-adaptive content generation via MCP prompts
- Three difficulty tiers calibrated to the survey's three student profile types
- A ContextAgent that detects gaps and updates difficulty automatically
- Interests-based content personalisation

---

### What Was Built

#### Student Profile Model (`lib/core/models/student_profile.dart`)

Six dimensions captured during onboarding:

| Field | Values | Purpose |
|-------|--------|---------|
| `grade` | 10 or 12 | Selects the correct NCERT curriculum |
| `learningStyle` | visual / auditory / kinesthetic / readWrite | VARK personalisation axis |
| `interests` | Up to 8 options (Technology, Sports, Science...) | Content connection examples |
| `quizScores` | Map of chapterId → 0–100 | Drives adaptive difficulty |
| `progressTracking` | Map of subject → chapterId → bool | Completion state |
| `consentGiven` | bool | FERPA gate — no content without this |

#### Adaptive Difficulty (`adaptiveDifficulty()` in `student_profile.dart`)

Maps survey profile types directly to three tiers:

| Quiz Score | Difficulty Tier | Survey Profile | Survey % |
|------------|----------------|----------------|----------|
| No score yet | `standard` | — | — |
| < 50% | `basic` | at_risk | 26.3% |
| 50–79% | `standard` | average | 42.3% |
| ≥ 80% | `advanced` | high_performer | 31.4% |

The thresholds are not arbitrary — they were calibrated to the exact proportions found in the 1,000-student survey.

#### VARK Personalisation in MCP Prompts (`mcp_server/server.py`)

Each `synthesis_report` prompt carries the full student context:

```
chapter_id   → which chapter
grade        → curriculum level
learning_style → visual | auditory | kinesthetic | readWrite
interests    → e.g. "Technology, Sports"
difficulty   → basic | standard | advanced
previous_score → last quiz score for adaptive context
```

The server builds a style-specific prompt instruction for each VARK type:
- **Visual** — diagrams, spatial metaphors, ASCII layouts
- **Auditory** — conversational tone, storytelling, rhythmic phrasing
- **Kinesthetic** — step-by-step procedures, hands-on problems
- **Read-Write** — formal academic prose, structured headings, glossary

#### Context Management Agent (`lib/core/services/context_agent.dart`)

| Method | What it does |
|--------|-------------|
| `identifyGaps()` | Returns chapters where score < 60% — the learning gaps |
| `overallMastery()` | Calculates average score across all attempted chapters |
| `recommend()` | Gap chapters first, then next unstarted chapter per subject |
| `updateFromQuizResult()` | Updates profile, auto-marks complete if score ≥ 60%, recalculates difficulty |

#### Onboarding Screen (`lib/features/onboarding/onboarding_screen.dart`)

Collects grade, interests (minimum 2), and learning style before the student reaches any curriculum content. Profile is persisted locally via `path_provider`.

---

### Survey Evidence

| Question | Finding | Design Decision |
|----------|---------|----------------|
| Q1 — Confidence | Uniform spread 1–10, no clustering | Proves three tiers are needed, not one |
| Q4 — Pedagogy Pref | 83.6% prefer interactive (video, chat, examples) | Three-tab Learning Hub replaces textbook |
| Q6 — Persistence | Median 15 min before giving up | Adaptive difficulty must kick in within one session cycle |
| Q8 — VARK Style | No dominant modality — all four styles present | Validates VARK as the personalisation axis |
| Q14 — Hardest Subject | Physics 29.3% + Math 25.0% universally hardest | MCP server prioritises these subjects with 3 chapters each |
| Q15 — Help Seeking | 31.1% of at-risk students give up when stuck | Adaptive difficulty directly prevents this |

---

### Accomplishment Evidence

- Changing a student's quiz score from 45 → 55 triggers difficulty change from `basic` → `standard` on next synthesis request
- Synthesis report markdown changes visually for each learning style
- `identifyGaps()` returns the correct set of chapters below 60%
- Teacher Dashboard shows per-chapter difficulty labels with score evidence

---

## Objective 3 — LMS Integration via xAPI

> **Goal:** Demonstrate LMS interoperability through the xAPI (Experience API) standard, creating a locally-stored learning record that any compliant LRS can ingest.

**Theoretical Basis:** xAPI 1.0.3 specification (ADL) · SCORM/LTI standards

---

### What Was Required

- xAPI 1.0.3 Actor–Verb–Object–Result–Context statement structure
- At least three distinct xAPI verbs covering the learning lifecycle
- A local LRS (Learning Record Store) that persists statements
- Teacher visibility into the xAPI log
- Statements exportable for import into external LRS systems

---

### What Was Built

#### xAPI Service (`lib/core/services/xapi_service.dart`)

Four learning events, each producing a full xAPI 1.0.3 statement:

| Event | Trigger | xAPI Verb | Object type |
|-------|---------|-----------|-------------|
| App opened | Student reaches Dashboard | `launched` | application |
| Chapter opened | Student taps a chapter | `launched` | module |
| Quiz submitted | Student submits answers | `scored` | assessment |
| Chapter marked done | Student taps "Mark Complete" | `completed` | module |

Every statement includes:
- **Actor** — anonymous student identifier (`mailto:student@mcpstudyhub.local`)
- **Verb** — ADL official URI (`http://adlnet.gov/expapi/verbs/scored` etc.)
- **Object** — chapter URI with NCERT title
- **Result** — scaled score (0–1), raw score, success flag (≥60%), duration
- **Context** — platform ("MCP StudyHub"), language (`en-IN`), MCP protocol version
- **Timestamp** — ISO 8601 UTC
- **Version** — `1.0.3`

#### MCP Tool (`record_performance` in `mcp_server/server.py`)

The Flutter app calls this MCP Tool after every quiz — the server writes the xAPI statement to `xapi_statements.json` and returns a `statement_id` (UUID). This demonstrates that xAPI recording is handled **through the MCP protocol**, not as a separate side channel.

#### MCP Resource (`xapi://statements`)

The full statement log is exposed as a readable MCP Resource, making the learning record accessible to any MCP client (not just this app).

#### Teacher Dashboard (`lib/features/teacher/teacher_dashboard.dart`)

| Section | Data source |
|---------|-------------|
| xAPI Event Summary | Bar chart: launched / scored / completed counts |
| Recent Learning Events | Last 10 statements with timestamp and score |
| Learning Gaps | Chapters flagged Critical (<40%) or Moderate (40–59%) |
| Export | JSON export button for import into external LRS |

---

### Survey Evidence

| Question | Finding | Design Decision |
|----------|---------|----------------|
| Q7 — Discussion Frequency | 43.5% rarely or never discuss with teachers | xAPI log gives teachers visibility without requiring student-initiated contact |
| Q11 — Dashboard Motivation | 60–72% of all profile types want a progress dashboard | Validates both the student Progress tab and the teacher xAPI summary |
| Q12 — Teacher Visibility | 26.6%–50.8% of students welcome automatic score sharing | Confirms teacher xAPI access is wanted by a meaningful proportion |

---

### Accomplishment Evidence

- Taking a quiz writes a valid xAPI 1.0.3 JSON statement to `xapi_statements.json`
- Statement includes all required fields (actor, verb, object, result, context, timestamp, version)
- Teacher Dashboard loads and displays the xAPI log counts correctly
- `xapi://statements` MCP Resource returns the log as valid JSON
- Export produces a file importable into any ADL-compliant LRS

---

## Objective 4 — Ethics and Privacy

> **Goal:** Implement a FERPA-aligned privacy model with informed consent before any data collection, AI transparency disclosure, and the right to export and delete all personal data.

**Theoretical Basis:** FERPA (US Department of Education) · AI ethics in educational technology

---

### What Was Required

- Informed consent before any student data is stored
- Disclosure that content is AI-generated
- Right to access all stored personal data
- Right to delete all stored personal data
- Local-only data storage (no cloud transmission)

---

### What Was Built

#### Consent Gate (`lib/features/consent/consent_screen.dart`)

Three sections — all must be accepted before the student reaches the Dashboard:

| Section | What it discloses |
|---------|------------------|
| 1. Privacy & Data Storage | All data stays on this device only. No external transmission. |
| 2. AI-Generated Content Disclosure | Study reports and quizzes may be generated by an AI model. |
| 3. Learning Analytics | Quiz scores and chapter activity are logged for personalisation and teacher review. |

No content loads, no data is written, and no MCP calls are made until `consentGiven = true` in the student profile.

#### AI Transparency Banner (`lib/features/learning_hub/synthesis/synthesis_tab.dart`)

Every synthesis report displays a persistent banner:
- **"AI-Generated"** — when the MCP server returned live Claude content
- **"Static Content"** — when the server is offline and fallback content is shown

Students always know whether they are reading AI-generated or pre-written material.

#### Data Rights (`lib/features/settings/settings_screen.dart`)

| Right | Implementation |
|-------|---------------|
| Right to access | "Export Data" button — downloads all profile + xAPI data as JSON |
| Right to erasure | "Delete All Data" button — removes all local files and resets to first-launch state |

#### Local-Only Architecture

All data is stored via `path_provider` in the app's local documents directory:
- `student_profile.json` — learning profile
- `xapi_statements.json` — event log (local LRS)
- `teacher_curriculum_additions.json` — teacher content

No file is ever transmitted to a remote server. The MCP server runs locally as a subprocess.

---

### Survey Evidence

| Question | Finding | Design Decision |
|----------|---------|----------------|
| Q10 — AI Trust Score | At-risk students score only 2.80/5 trust | AI Transparency Banner builds trust incrementally rather than hiding AI origin |
| Q12 — Teacher Visibility | 43.2% of at-risk students prefer privacy from teacher | Opt-in consent model for learning analytics — not automatic sharing |
| Q13 — Data Privacy Preference | 57.7% of at-risk students want device-only storage | Validates local-first architecture with no cloud sync |

---

### Accomplishment Evidence

- A student who has not completed consent cannot reach the Dashboard (GoRouter redirect enforces this)
- `consentGiven` field is checked before any MCP call
- Export produces a valid JSON file containing all stored data
- Delete All Data removes all files and navigates back to onboarding
- No network requests are made to any endpoint other than the configured AI provider URL

---

## Objective 5 — Responsible Implementation and Governance

> **Goal:** Give teachers full visibility into algorithm decisions, ensure the AI system is auditable, and provide tools for curriculum governance — so educators remain in control of what students learn.

---

### What Was Required

- Teachers can see exactly how the adaptive algorithm makes decisions
- Teachers can override curriculum content (add/remove subjects and chapters)
- Struggling students are surfaced proactively (not just when they ask for help)
- API key and system credentials are handled safely
- Teacher and student workflows are clearly separated

---

### What Was Built

#### Role Selection Screen (`lib/features/role_selection/role_selection_screen.dart`)

The app's entry point separates the two roles at launch. Teachers and students never see the same starting screen. The Teacher path uses `context.push` so the AppBar back button always returns to Role Selection — teachers cannot accidentally end up in the student flow.

#### Teacher Dashboard (`lib/features/teacher/teacher_dashboard.dart`)

| Section | Governance Purpose |
|---------|-------------------|
| Algorithmic Transparency Banner | Displays exact score thresholds: <50% → Basic, 50–79% → Standard, ≥80% → Advanced |
| Student Overview Card | Grade, learning style, chapters assessed, average mastery % |
| xAPI Event Summary | Total launched / scored / completed counts across all sessions |
| Learning Gaps | Critical (<40%) and Moderate (40–59%) chapters with chapter names |
| Recent Learning Events | Last 10 xAPI statements — chapter, score, timestamp |
| Adaptive Algorithm Rationale | Per-chapter difficulty labels with the score evidence that triggered them |

The "Adaptive Algorithm Rationale" card is the direct implementation of the governance requirement: teachers can see not just *what* difficulty a chapter is set to, but *why* (the exact score that triggered it).

#### Curriculum Editor (`lib/features/teacher/curriculum_editor_screen.dart`)

| Feature | Implementation |
|---------|---------------|
| Add chapter to existing subject | Title, concepts, estimated time — appears immediately for students |
| Add a completely new subject | Name dialog → first chapter dialog |
| Visual labelling | Custom chapters show a teal "Custom" badge; base chapters show a padlock |
| Delete custom chapters | Red delete button with confirmation dialog — only on custom, never on base |
| Persistence | Saved to `teacher_curriculum_additions.json`, survives app restarts |
| Live refresh | `ref.invalidate(curriculumProvider)` — student view updates immediately |

#### Teacher Curriculum Provider (`lib/core/providers/teacher_curriculum_provider.dart`)

Manages teacher additions separately from the base NCERT curriculum. The `_merge()` function in `curriculum_provider.dart` combines base curriculum with teacher additions transparently — students see one unified chapter list without knowing which chapters came from which source.

#### API Key Governance

- API keys are set as environment variables before launching the server — never hard-coded
- Keys are never written to any file in the project
- The MCP server uses them only for outgoing calls to the configured AI provider
- The `.gitignore` excludes `.env` files from version control

---

### Survey Evidence

| Question | Finding | Design Decision |
|----------|---------|----------------|
| Q7 — Discussion Frequency | 14.6% never discuss with teachers; 28.9% rarely do | Teacher Dashboard must surface gaps proactively — teachers cannot wait to be approached |
| Q12 — Teacher Visibility | At-risk students most resistant to teacher monitoring | Algorithm Rationale card shows teachers *why* a student is struggling, not just *that* they are |
| Q15 — Help Seeking | Only 6.6% of at-risk students ask a teacher when stuck | The xAPI log replaces the missing student-initiated conversation |

---

### Accomplishment Evidence

- Teacher can add a new subject and chapter; it appears in the student's chapter list immediately
- Teacher Dashboard displays the correct difficulty label (Basic/Standard/Advanced) per chapter with the score that set it
- Removing a teacher-added chapter restores the original chapter list
- Base NCERT chapters cannot be deleted — the delete button only appears on custom chapters
- Role selection correctly routes Teacher → Teacher Dashboard and Student → onboarding/dashboard depending on profile state

---

## Overall Completion Summary

| Objective | Key Components Built | Survey Questions | Status |
|-----------|---------------------|-----------------|--------|
| 1 — MCP Technical Foundations | `server.py` (8 primitives) · `mcp_transport.dart` · `client_service.dart` · Multi-provider AI | Q5, Q9, Q10 | **Complete** |
| 2 — Personalised & Adaptive Learning | `student_profile.dart` · `context_agent.dart` · VARK prompts · Onboarding · Three difficulty tiers | Q1, Q4, Q6, Q8, Q14, Q15 | **Complete** |
| 3 — LMS Integration via xAPI | `xapi_service.dart` · `record_performance` tool · `xapi://statements` resource · Teacher Dashboard | Q7, Q11, Q12 | **Complete** |
| 4 — Ethics and Privacy | Consent gate · AI Transparency Banner · Export/Delete · Local-only storage | Q10, Q12, Q13 | **Complete** |
| 5 — Responsible Governance | Role selection · Teacher Dashboard · Curriculum Editor · Algorithm Rationale | Q7, Q12, Q15 | **Complete** |

**Total source files:** 26 Dart files · 1 Python server · 2 JSON curriculum assets · 2 Python analysis scripts  
**Survey coverage:** 15 questions across 1,000 students — every objective backed by at least 3 questions  
**Flutter analyze:** 0 issues  
**MCP server:** All 8 primitives tested and functional

---

*MCP StudyHub · Project Objective Mapping*  
*Archana Gundawade · July 2025*
