<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 → 1.0.0
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (3 principles)
  - Technology Constraints
  - Development Workflow
  - Governance
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check section compatible)
  - .specify/templates/spec-template.md ✅ (User Scenarios align with mobile-first)
  - .specify/templates/tasks-template.md ✅ (Phase structure compatible)
Follow-up TODOs: None
-->

# Robin Radio 2.0 Constitution

## Core Principles

### I. Mobile-First PWA

All features MUST be designed and tested for mobile devices first. Desktop is secondary.

- The primary user accesses via smartphone; UI/UX decisions prioritize touch interactions
- Progressive Web App requirements: offline capability, installable, responsive
- Performance budget: First Contentful Paint < 2s on 3G, Time to Interactive < 5s
- All components MUST be tested on mobile viewport before desktop

**Rationale**: The sole user (Robin) primarily uses her phone. Optimizing for desktop first would compromise the experience she actually uses.

### II. Test-First Development

Tests MUST be written and approved before implementation begins. No exceptions.

- Red-Green-Refactor cycle: Write failing test → Implement → Refactor
- Contract tests for Firebase operations (storage reads, queries)
- Integration tests for audio playback flows
- Component tests for all interactive UI elements
- Test coverage MUST include: search functionality, radio shuffle logic, playback controls

**Rationale**: With a single critical user, bugs directly impact her experience. TDD ensures reliability and prevents regressions.

### III. Simplicity Over Scale

Build only what Robin needs. Reject complexity for hypothetical future users.

- No user authentication system (single-user app)
- No admin dashboards or content management beyond Firebase console
- No analytics or tracking
- YAGNI (You Aren't Gonna Need It): If Robin hasn't asked for it, don't build it
- Every feature MUST map to a specific user story from Robin

**Rationale**: This is a personal app for 1-3 users maximum. Enterprise patterns and scalability concerns add unnecessary complexity.

## Technology Constraints

**Stack Requirements**:
- Frontend: PWA (framework TBD in plan phase)
- Backend: Firebase Storage (existing album/track data)
- Audio: Native browser audio APIs
- Deployment: Static hosting with PWA support

**Non-Negotiables**:
- MUST work offline for cached content
- MUST be installable on iOS/Android home screen
- Audio playback MUST continue with screen locked
- Search MUST be fast and forgiving (fuzzy matching)

## Development Workflow

**Before Implementation**:
1. Feature MUST have a spec with user stories from Robin's perspective
2. Plan MUST pass Constitution Check (Mobile-First, Test-First, Simplicity)
3. Tests MUST be written and fail before code

**During Implementation**:
- Commit after each passing test
- Test on mobile device or emulator before PR
- No "TODO: add tests later" comments allowed

**Quality Gates**:
- All tests pass
- Mobile lighthouse score > 90
- No accessibility violations (a11y) on core flows

## Governance

This constitution supersedes all other development practices for Robin Radio 2.0.

**Amendment Process**:
1. Propose change with rationale tied to Robin's actual needs
2. Document impact on existing features
3. Update version following semver rules
4. Propagate changes to all dependent templates

**Compliance**:
- All specs MUST reference which principles they satisfy
- PRs blocked if Constitution Check fails without documented justification
- Complexity additions require written justification in plan.md

**Version**: 1.0.0 | **Ratified**: 2026-01-13 | **Last Amended**: 2026-01-13
