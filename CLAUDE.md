# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Robin Radio 2.0 is a personal music app for a single user (Robin, on an
iPhone 15 Pro). Music albums are stored in Firebase Storage with album covers
and tracks. Core features: album browsing, search, and a "radio" mode that
shuffles all songs.

**Firebase Project**: `robin-radio` (bucket `robin-radio.appspot.com`)

## Active Codebase

- **`robin-radio-expo/`** — the current app: Expo SDK 56 + React Native +
  TypeScript + react-native-track-player. See its README for architecture,
  build, and distribution (EAS internal distribution / ad-hoc, no App Store).
- `robin_radio/` — the previous Flutter implementation, kept for reference
  until the Expo app reaches full parity on device. Do not develop new
  features there.

## Constitution (Non-Negotiable Principles)

See `.specify/memory/constitution.md` for full details. Key rules:

1. **Mobile-First PWA**: Design for phone first. FCP < 2s on 3G, TTI < 5s. Test mobile viewport before desktop.
2. **Test-First Development**: TDD mandatory. Write failing tests before implementation.
3. **Simplicity Over Scale**: No auth, no admin UI, no analytics. Build only what Robin needs.

## Speckit Workflow

This project uses speckit for structured development. Available commands:

- `/speckit.specify` - Create feature specification from description
- `/speckit.clarify` - Ask clarification questions for spec
- `/speckit.plan` - Generate implementation plan from spec
- `/speckit.tasks` - Generate task list from plan
- `/speckit.implement` - Execute tasks from tasks.md
- `/speckit.analyze` - Cross-artifact consistency check
- `/speckit.constitution` - Update project constitution

**Workflow order**: specify → clarify → plan → tasks → implement

## Key Directories

```
.specify/
├── memory/constitution.md    # Project principles (read before any feature work)
├── templates/                # Templates for specs, plans, tasks
└── scripts/bash/             # Setup scripts

specs/[feature-name]/         # Feature artifacts (created per feature)
├── spec.md
├── plan.md
├── tasks.md
└── research.md
```

## PWA Requirements

- Offline capability for cached content
- Installable on iOS/Android home screen
- Audio playback continues with screen locked
- Fuzzy search for song/album matching
