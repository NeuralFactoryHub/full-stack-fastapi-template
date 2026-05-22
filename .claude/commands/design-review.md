---
description: "Review existing UI for issues and improvements"
argument-hint: "[file-path|component-name]"
---

# Design Review

Review existing UI code for design issues, usability problems, and improvement opportunities. Provides actionable recommendations.

## Pre-flight Checks

1. Check if `.ui-design/` directory exists; if not, create it and `.ui-design/reviews/`.
2. Load project context if available (`conductor/product.md`, `conductor/tech-stack.md`, `.ui-design/design-system.json`).

## Target Identification

### If argument provided:
- File path: validate and read the file.
- Component name: search the codebase for matching component files.
- If not found: display error with suggestions.

### If no argument:
Ask the user to specify the target (component / page / whole UI directory / recent changes).

## Interactive Review Configuration

Ask ONE question per turn, waiting for the response:
- **Q1: Review Focus** — visual design / usability / code quality / performance / comprehensive.
- **Q2: Design Context** (if visual/usability) — data display / data entry / navigation / content / e-commerce / other.
- **Q3: Target Platform** — desktop / mobile / responsive / all platforms.

## State Management

Create/update `.ui-design/reviews/review_state.json` with review id, target, focus areas, context, platform, status, issue counts by severity.

## Review Execution

1. **Code Analysis** — parse component structure, styling approach, framework, composition patterns.
2. **Visual Design Review** — spacing & layout, typography, colors (contrast, semantics, dark mode), visual hierarchy.
3. **Usability Review** — interaction patterns (clickable areas, hover/focus, loading/error/empty states), user flow (tab order, CTAs, feedback), cognitive load.
4. **Code Quality Review** — component patterns (single responsibility, prop drilling, reusability), styling patterns, maintainability.
5. **Performance Review** — render optimization (re-renders, memoization), asset optimization (images, icons, fonts, code splitting).

## Output Format

Generate review report in `.ui-design/reviews/{review_id}.md` with: summary, issue counts (critical/major/minor/suggestions), critical issues, major issues, minor issues, suggestions, positive observations, next steps.

Each issue includes: severity, location, category, problem, impact, recommendation, and a before/after code example.

## Completion

Update `review_state.json` to `complete` with issue counts, then display a summary with next-step options (view details, start fixing, export, review another).

If the user chooses to fix issues, guide them through fixes one at a time, updating the review report as issues are resolved.

## Error Handling

- If target file not found: suggest similar files, offer to search.
- If file is not UI code: explain and ask for the correct target.
- If review fails mid-way: save partial results, offer to resume.
