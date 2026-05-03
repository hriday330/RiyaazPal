# AGENTS.md

## Project

RiyaazPal is a SwiftUI + SwiftData iOS app for Indian classical music practice tracking and insights.

The current priority is adding a quantitative practice-area questionnaire flow:
- Users define practice areas, e.g. Sapat Taans, Bol Taans, Layakari.
- When logging a session, users answer one question per active area.
- Each area can be rated from 1–10 or marked as “I didn’t work on this today.”
- The app should compute deterministic practice metrics over time.
- LLM summaries are optional and should only summarize computed metrics.

## Development Principles

- Prefer small, reviewable diffs.
- Do not perform large rewrites unless explicitly requested.
- Preserve existing behavior unless the task says otherwise.
- Keep UI consistent with existing RiyaazPal styling.
- Prefer simple SwiftUI over complex abstractions.
- Prefer deterministic logic over LLM-generated interpretation.
- Keep analytics logic UI-independent where possible.
- Do not delete existing models or data unless explicitly asked.
- Do not break existing SwiftData persistence.

## Architecture Guidelines

- Use SwiftUI for views.
- Use SwiftData for persistence.
- Keep model changes backward-compatible where possible.
- Store snapshot values when historical stability matters.
  - Example: `areaName` should be saved on a rating so old sessions remain readable if a practice area is renamed.
- Avoid coupling metrics computation directly to SwiftUI views.
- Put reusable metric calculation logic into pure Swift helpers when possible.
- Keep optional notes and tags secondary to practice-area ratings.

## Practice Area Rating Design

A practice area represents a measurable skill dimension, such as:
- Sapat Taans
- Bol Taans
- Layakari
- Alap Clarity
- Intonation
- Jor/Jhala Control

A session may contain multiple practice-area ratings.

Recommended rating fields:
- `id: UUID`
- `areaName: String`
- `score: Int?`
- `didPractice: Bool`
- `createdAt: Date`
- relationship to `PracticeSession`

Rules:
- `score` should only be set when `didPractice == true`.
- Valid scores are 1 through 10.
- If the user selects “I didn’t work on this today,” save `didPractice == false` and `score == nil`.
- Do not require every active area to be rated.
- Historical ratings should still display correctly if a practice area is later renamed or deleted.

## Session Logging UX

The questionnaire should be fast and lightweight.

For each active practice area, show:

> How did you feel about [area name] today?

Controls:
- 1–10 slider
- “I didn’t work on this today” toggle

Avoid making users fill out:
- required notes
- required tags
- required goals
- LLM-generated reflection

After the questionnaire and optional notes, saving the session should be enough.

## Metrics Engine

Create deterministic practice metrics before adding LLM summaries.

Useful metrics:
- 7-day average
- previous 7-day average
- 30-day average
- trend direction
- consistency / volatility
- days since last practiced
- number of rated sessions
- strongest improving area
- weakest recent area
- neglected areas

Metrics code should be:
- pure Swift where possible
- unit-testable
- independent from SwiftUI
- based only on saved ratings and session dates

## LLM Summary Rule

The LLM should not invent insights.

If an LLM summary is added later:
- It should receive only deterministic metrics as input.
- It should summarize at most 3 observations.
- It should not infer musical progress beyond the numbers.
- It should use a supportive but honest teacher-like tone.
- It should clearly distinguish data-backed observations from suggestions.

## Coding Style

- Follow existing project style.
- Prefer clear names over clever abstractions.
- Keep views reasonably small, but do not over-engineer.
- Avoid unnecessary dependencies.
- Avoid premature generalization.
- Use previews where helpful.
- Keep formatting consistent with nearby files.

## Safety Checks Before Finishing

Before completing a task:
- Ensure the app builds.
- Check that existing session logging still works.
- Check that old sessions do not crash.
- Check that ratings save and reload correctly.
- Check that deleting or renaming a practice area does not corrupt old ratings.
- Check edge cases:
  - no practice areas
  - all areas marked not practiced
  - no scores in the last 7 days
  - renamed practice area
  - deleted practice area

## Preferred Implementation Order

1. Add models.
2. Add basic practice-area setup UI.
3. Add questionnaire UI to session logging.
4. Persist ratings with sessions.
5. Add deterministic metrics helpers.
6. Add insights cards.
7. Only then consider optional LLM summary.
