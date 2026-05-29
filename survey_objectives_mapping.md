# Survey Questionnaire — Objectives Mapping

**Project:** Using Model Context Protocol (MCP) in Educational Curriculum Design for Students  
**Survey Sample:** 1,000 students · Karad, Maharashtra · Grade 10 & Grade 12  
**Total Questions:** 15 (Q1–Q7 original · Q8–Q15 extended)

---

## Research Objectives at a Glance

| # | Objective | Questions Used |
|---|-----------|---------------|
| 1 | MCP Technical Foundations — validate AI integration in education | Q5, Q9, Q10, Q15 |
| 2 | Personalised & Adaptive Learning — VARK model, difficulty tiers | Q1, Q2, Q3, Q4, Q6, Q8, Q14, Q15 |
| 3 | LMS Integration via xAPI — progress tracking, teacher visibility | Q7, Q11, Q12 |
| 4 | Ethics & Privacy — FERPA consent, data rights, AI transparency | Q10, Q12, Q13 |
| 5 | Responsible Implementation & Governance — teacher oversight | Q7, Q12, Q15 |

---

## Question-by-Question Breakdown

---

### Q1 — Academic Confidence Score
**Question:** *"How confident are you in explaining [Specific Topic] to a classmate right now?"*  
**Response Type:** Numeric scale 1–10

**Data Collected:**
Self-reported topic confidence across all levels of the student population.

**Finding:**
Confidence distributed almost evenly — 17.1% very low (1–2), 20.7% low (3–4), 21.2% moderate (5–6), 21.2% good (7–8), 19.8% high (9–10). No clustering at either extreme.

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
A uniform confidence spread proves that a single content difficulty level fails the majority of students. This is the primary evidence that justifies building three distinct difficulty tiers (`basic`, `standard`, `advanced`) rather than one-size-fits-all curriculum delivery. The three profile types — at_risk (26.3%), average (42.3%), high_performer (31.4%) — were calibrated directly from this distribution.

---

### Q2 — Focus Loss During Study
**Question:** *"How many times do you check your phone during a 2-hour study session?"*  
**Response Type:** Categorical — 0 / 1–3 / 4–6 / 7+

**Data Collected:**
Frequency of digital distraction during self-directed study sessions.

**Finding:**
67% of students lose focus at least once. Only 33% report zero phone checks during a 2-hour session.

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
Passive textbook reading cannot sustain engagement for this population. The 3-tab chapter structure (Synthesis → Quiz → Multimedia) replaces passive reading with active, varied interactions. Short, estimated chapter times (40–90 minutes) prevent attention fatigue. The app's interactive quiz forces active recall rather than passive scrolling.

---

### Q3 — Primary Study Inhibitor
**Question:** *"What most often stops you from studying?"*  
**Response Type:** Categorical — Digital distractions / Noise / Tiredness / Lack of understanding / Chores

**Data Collected:**
Root cause of study session abandonment.

**Finding:**
Digital distractions top the list at 28.4%. Critically, **17.7% stop studying specifically because they do not understand the material** — they hit a wall and quit.

**Objectives Satisfied:** Objective 2, Objective 3

**How it satisfies the objectives:**
The 17.7% "lack of understanding" figure is the core problem statement for Objective 2. Adaptive difficulty directly addresses this — when a student scores below 50%, the system automatically simplifies content on the next visit. The student does not need to ask for help; the algorithm detects the gap and adjusts. This ties directly to xAPI (Objective 3): every quiz attempt is logged so teachers can identify which chapters are causing students to disengage.

---

### Q4 — Pedagogical Preference
**Question:** *"After getting a question wrong, which resource helps you understand it fastest?"*  
**Response Type:** Categorical — Video / 1-on-1 Chat / Solved Example / Textbook

**Data Collected:**
Preferred learning format for remedial understanding.

**Finding:**
Only 16.4% reach for a textbook. 83.6% prefer interactive formats: Video (28.7%), 1-on-1 Chat (27.8%), Solved Example (27.1%).

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
Three tabs in the Learning Hub map directly to these three preferences:
- **Synthesis tab** → AI-generated explanation = analog of 1-on-1 Chat (27.8%)
- **Active Learning tab** → Worked examples and quiz = Solved Example (27.1%)
- **Multimedia tab** → Curated YouTube videos = Video (28.7%)

The textbook (16.4%) is the only format *not* replicated as a primary tab — it is referenced through NCERT article links in the multimedia tab as a supplementary resource.

---

### Q5 — Academic Goal Orientation
**Question:** *"What is your primary academic goal?"*  
**Response Type:** Categorical — 90%+ in Board exams / Clearing JEE/NEET/CET / Just passing

**Data Collected:**
Student motivation and academic aspiration level.

**Finding:**
52.7% target 90%+ in Board exams. 41.8% target JEE/NEET/CET. Only 5.5% aim to just pass.

**Objective Satisfied:** Objective 1, Objective 2

**How it satisfies the objectives:**
94.5% of students have high academic aspirations tied specifically to the Indian national curriculum. This confirms that the MCP server must serve curriculum-aligned, exam-focused content — not casual learning. All 22 chapters in the server database are sourced from NCERT textbooks (the syllabus used for both CBSE boards and JEE/NEET preparation), directly justified by this finding. The MCP content delivery is validated as the right mechanism because the content itself must be authoritative and exam-ready.

---

### Q6 — Persistence on Hard Problems
**Question:** *"How many minutes do you spend on a single hard Math/Physics problem before giving up?"*  
**Response Type:** Numeric (minutes)

**Data Collected:**
Problem-solving persistence before abandonment.

**Finding:**
Most students give up between 5 and 20 minutes. The median is approximately 15 minutes. Very few persist beyond 30 minutes.

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
When a student reaches a `basic` difficulty chapter and still cannot progress, the 15-minute median represents the window before disengagement. The adaptive difficulty system provides a safety net before that window closes — after a sub-50% quiz score, the next session automatically reduces cognitive load. Students are not left alone with content that is too hard for longer than one session cycle.

---

### Q7 — Teacher and Peer Discussion Frequency
**Question:** *"How often do you discuss difficult topics with a teacher or peer outside class?"*  
**Response Type:** Categorical — Daily / Weekly / Rarely / Never

**Data Collected:**
Frequency of external academic support access.

**Finding:**
30.9% discuss weekly, 25.6% daily. But 28.9% rarely discuss and **14.6% never discuss difficult topics with a teacher or peer**.

**Objectives Satisfied:** Objective 3, Objective 5

**How it satisfies the objectives:**
43.5% of students rarely or never access a teacher when stuck. Two design decisions follow directly:

- **Objective 3 (xAPI):** Since struggling students do not come to teachers, teachers need a system that surfaces gaps automatically. The xAPI event log gives teachers chapter-by-chapter quiz scores without students needing to initiate contact.
- **Objective 5 (Governance):** The Teacher Dashboard was designed so teachers can be proactive. The Learning Gaps section automatically classifies chapters below 40% as "Critical" and 40–59% as "Moderate", surfacing at-risk students before they disengage completely.

---

### Q8 — Learning Style (VARK)
**Question:** *"When studying a new concept, which helps you understand it fastest?"*  
**Response Type:** Categorical — Visual (diagrams) / Auditory (video/listen) / Kinesthetic (practice) / Read-Write (notes/text)

**Data Collected:**
Self-identified VARK learning modality.

**Finding:**
No single style dominates. Distribution across all four VARK styles is relatively even, confirming that a single presentation format cannot serve the whole student population. High performers lean Kinesthetic (30.2%), at-risk students lean Auditory/Visual (31.1% / 30.7%).

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
The VARK model (Fleming, 1987) is the theoretical basis of Objective 2's personalisation layer. Without survey evidence, using VARK as the personalisation axis is an assumption. Q8 provides the empirical validation: students self-identify with different learning styles, confirming that the four-mode synthesis prompt — visual (diagrams), auditory (narrative), kinesthetic (step-by-step), read-write (formal prose) — addresses a real and measurable difference in the student population.

---

### Q9 — Current AI Tool Usage
**Question:** *"Do you currently use any AI tool (ChatGPT, Gemini, Copilot, etc.) for studies?"*  
**Response Type:** Categorical — Never / Occasionally / Regularly / Daily

**Data Collected:**
Baseline AI adoption rate and frequency among secondary students.

**Finding:**
High performers are already frequent AI users: 38.4% use AI regularly, 26.6% daily. At-risk students are the opposite: 36.5% never use AI, 41.1% only occasionally. Across grades, Grade 12 uses AI slightly more than Grade 10 (41.6% Regularly/Daily vs 35.6%).

**Objective Satisfied:** Objective 1

**How it satisfies the objective:**
Objective 1 argues that MCP-based AI integration is appropriate for educational delivery. Q9 confirms that the population who would benefit most from AI-powered content (high performers) is already receptive to it, and that at-risk students — who need it most — have the lowest adoption, suggesting the barrier is access and framing rather than refusal. This justifies building AI synthesis as the primary tab (not a hidden feature) and motivates the AI Transparency Banner to ease first-time users into AI-generated content.

---

### Q10 — Trust in AI-Generated Explanations
**Question:** *"How comfortable are you receiving explanations generated by an AI, tailored to your learning style and grade?"*  
**Response Type:** Numeric scale 1–5

**Data Collected:**
Student trust level toward AI-generated academic content.

**Finding:**
High performers: mean 3.86 (scale 1–5). At-risk students: mean 2.80. Daily AI users score 3.86 mean trust; non-users score 2.81. Trust is directly correlated with AI usage frequency (correlation validated: PASS).

**Objectives Satisfied:** Objective 1, Objective 4

**How it satisfies the objectives:**
- **Objective 1:** Mean trust of 3.86 among regular users confirms the population is ready for AI content delivery via MCP. The 65%+ adoption rate among high performers (Q9) is reinforced by trust scores above the midpoint.
- **Objective 4 (Ethics):** At-risk students score only 2.80 — below neutral. This low trust is the direct evidence for the AI Transparency Banner in the Synthesis tab, which discloses whether content is Claude-generated or static. Building trust incrementally through transparent disclosure (rather than hiding the AI) is the design response to this finding.

---

### Q11 — Progress Dashboard Motivation
**Question:** *"Would seeing a visual dashboard of your completed chapters and quiz scores motivate you to study more?"*  
**Response Type:** Categorical — Yes / No / Doesn't matter

**Data Collected:**
Whether progress visualisation is a meaningful motivator for students.

**Finding:**
Across all three profiles, 60–72% say Yes. High performers: 71.8%. At-risk: 60.2%. Average: 64.5%.

**Objective Satisfied:** Objective 3

**How it satisfies the objective:**
Objective 3 implements xAPI-based progress tracking. Q11 validates that this tracking is not only technically useful for teachers but also motivationally relevant to students themselves. The Progress tab in the Student Dashboard (overall mastery bar, per-chapter score colours, learning gaps list) is not a reporting afterthought — it is a motivational feature wanted by 60–72% of the student population, across all performance profiles.

---

### Q12 — Teacher Visibility of Scores
**Question:** *"Would you be comfortable if your teacher could see your chapter-by-chapter quiz scores automatically?"*  
**Response Type:** Categorical — Yes I'd want that / No I prefer privacy / Only if I choose

**Data Collected:**
Student attitude toward automated academic monitoring by teachers.

**Finding:**
High performers are mostly comfortable: 50.8% want automatic sharing, 34.4% want control. At-risk students are the most resistant: **43.2% say "No I prefer privacy"**, 30.3% want control, only 26.6% want automatic sharing.

**Objectives Satisfied:** Objective 3, Objective 4, Objective 5

**How it satisfies the objectives:**
- **Objective 3:** The Teacher Dashboard displays the xAPI log — but Q12 shows that a significant minority of at-risk students (43.2%) do not want automatic sharing. This validates the opt-in model where data is stored locally and teachers access it only through the school's deployment context.
- **Objective 4 (Privacy):** The consent gate's third section ("Learning Analytics") and the opt-in xAPI model directly address the 43.2% who value privacy. Students are informed before any data is logged.
- **Objective 5 (Governance):** Teacher access to student data is the governance question. Q12 shows it is not uniformly welcomed — especially among the at-risk students who need monitoring most. This tension (students who need teacher intervention least want it) is explicitly surfaced in the Teacher Dashboard's "Adaptive Algorithm Rationale" card.

---

### Q13 — Data Storage Preference
**Question:** *"When using a study app, where do you prefer your learning data to be stored?"*  
**Response Type:** Categorical — Device only (no cloud) / School servers only / I don't mind

**Data Collected:**
Student preference for data locality and storage model.

**Finding:**
At-risk students strongly prefer local storage: **57.7% want device-only**. High performers are more relaxed: 40.3% don't mind. Average students lean toward school servers (39.9%).

**Objective Satisfied:** Objective 4

**How it satisfies the objective:**
Objective 4 is the privacy and ethics objective. Q13 provides direct student-reported justification for the local-first architecture chosen for MCP StudyHub. The app stores all data (student profile, quiz scores, xAPI statements, teacher curriculum additions) exclusively in the app's local documents directory via `path_provider`. No data leaves the device. The 57.7% at-risk preference for device-only storage is not just a design preference — it is the evidence that the most vulnerable students (who most need the tool) would be least likely to trust a cloud-based system.

---

### Q14 — Hardest Subject
**Question:** *"Which subject do you find hardest to study on your own?"*  
**Response Type:** Categorical — Physics / Mathematics / Chemistry / Biology / Computer Science

**Data Collected:**
Self-reported subject difficulty across grade levels and performance profiles.

**Finding:**
Physics (29.3%) and Mathematics (25.0%) are universally the hardest subjects across all profiles and grades. At-risk students skew even higher: Physics 34.4%, Mathematics 28.6%. Grade 10 students find Chemistry and Biology more challenging; Grade 12 students identify Computer Science as a significant difficulty (20.0%).

**Objective Satisfied:** Objective 2

**How it satisfies the objective:**
The MCP server's `CHAPTER_DB` prioritises Physics and Mathematics with the most curated resources — each has 3 chapters with hand-selected YouTube videos and worked examples, compared to 2 chapters each for Chemistry and Biology. This was not arbitrary. Q14 validates that Physics and Mathematics require the deepest content investment because they are the subjects where students most often get stuck and need adaptive support. For Grade 12, the Computer Science chapters (Python, Data Structures) were included precisely because 20% of Grade 12 students identify CS as their hardest subject.

---

### Q15 — Help-Seeking Behaviour
**Question:** *"When you can't understand a topic from the textbook, what do you do?"*  
**Response Type:** Categorical — Search YouTube / Ask a friend / Ask a teacher / Give up / Use ChatGPT/AI

**Data Collected:**
Actual behaviour when facing comprehension failure.

**Finding:**
At-risk students exhibit the most concerning pattern: **31.1% give up**, 39.0% search YouTube, only 6.6% ask a teacher. High performers use AI heavily: 45.9% use ChatGPT/AI. Non-AI users almost never use ChatGPT/AI (1.5%), confirming Q9 correlation (validated: PASS).

**Objectives Satisfied:** Objective 1, Objective 2, Objective 5

**How it satisfies the objectives:**
- **Objective 1:** 45.9% of high performers already turn to ChatGPT/AI when stuck. MCP StudyHub's AI synthesis tab is the structured, curriculum-aligned version of this behaviour — it delivers the same kind of on-demand explanation but grounded in NCERT content rather than a general-purpose chatbot.
- **Objective 2:** 31.1% of at-risk students simply give up. This is the exact problem adaptive difficulty is designed to prevent. When a student scores below 50%, the next session automatically serves simpler content — closing the loop before the student reaches the point of giving up.
- **Objective 5 (Governance):** Only 6.6% of at-risk students ask a teacher when stuck. Combined with Q7 (43.5% rarely/never discuss with teachers), this confirms that teachers are not currently in the feedback loop when at-risk students struggle. The xAPI log and Teacher Dashboard exist to close this gap without requiring the student to initiate contact.

---

## Objective Coverage Matrix

| Question | Obj 1 (MCP/AI) | Obj 2 (Adaptive) | Obj 3 (xAPI) | Obj 4 (Privacy) | Obj 5 (Governance) |
|----------|:--------------:|:----------------:|:------------:|:---------------:|:------------------:|
| Q1 Confidence | | ✓ | | | |
| Q2 Focus Loss | | ✓ | | | |
| Q3 Study Inhibitor | | ✓ | ✓ | | |
| Q4 Pedagogy Pref | | ✓ | | | |
| Q5 Goal Orientation | ✓ | ✓ | | | |
| Q6 Persistence | | ✓ | | | |
| Q7 Discussion Freq | | | ✓ | | ✓ |
| Q8 VARK Style | | ✓ | | | |
| Q9 AI Tool Usage | ✓ | | | | |
| Q10 AI Trust Score | ✓ | | | ✓ | |
| Q11 Dashboard Motivation | | | ✓ | | |
| Q12 Teacher Visibility | | | ✓ | ✓ | ✓ |
| Q13 Data Privacy Pref | | | | ✓ | |
| Q14 Hardest Subject | | ✓ | | | |
| Q15 Help Seeking | ✓ | ✓ | | | ✓ |
| **Coverage** | **4 Q** | **8 Q** | **3 Q** | **3 Q** | **3 Q** |

Every PhD objective is covered by at least 3 questions. Objective 2 (Personalised & Adaptive Learning) has the deepest empirical foundation with 8 questions providing evidence.

---

## Key Numbers for the Research Paper

| Statistic | Value | Used To Justify |
|-----------|-------|----------------|
| Students with non-uniform confidence (Q1) | 100% spread across 1–10 | Three-tier adaptive difficulty |
| Students losing focus during study (Q2) | 67% | Active learning over passive reading |
| Students stopping due to lack of understanding (Q3) | 17.7% | Adaptive difficulty prevents wall-hitting |
| Students preferring interactive over textbook (Q4) | 83.6% | Three-tab Learning Hub |
| Students with high academic goals (Q5) | 94.5% | NCERT exam-aligned content |
| Students rarely/never accessing teachers (Q7) | 43.5% | xAPI + Teacher Dashboard |
| High performers using AI regularly/daily (Q9) | 65.0% | AI synthesis as primary feature |
| At-risk AI trust score mean (Q10) | 2.80 / 5 | AI Transparency Banner |
| Students wanting progress dashboard (Q11) | 60–72% | Student Progress tab |
| At-risk students resisting teacher visibility (Q12) | 43.2% | Opt-in xAPI consent model |
| At-risk students wanting device-only storage (Q13) | 57.7% | Local-first architecture |
| Physics + Math as hardest subjects (Q14) | 54.3% | Prioritised MCP content |
| At-risk students who give up when stuck (Q15) | 31.1% | AI synthesis + adaptive difficulty |

---

*MCP StudyHub · Survey Questionnaire Objectives Mapping*  
*Archana Gundawade · July 2025*
