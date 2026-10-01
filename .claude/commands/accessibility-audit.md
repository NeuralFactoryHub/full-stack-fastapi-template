---
description: "Audit UI code for WCAG compliance"
argument-hint: "[file-path|component-name|--level AA|AAA]"
---

# Accessibility Audit

Comprehensive audit of UI code for WCAG 2.1/2.2 compliance. Identifies accessibility issues and provides actionable remediation guidance.

## Pre-flight Checks

1. Check if `.ui-design/` directory exists:
   - If not: Create `.ui-design/` directory
   - Create `.ui-design/audits/` subdirectory for audit results

2. Load project context:
   - Check for `conductor/tech-stack.md` for framework info
   - Check for `.ui-design/design-system.json` for color tokens
   - Detect testing framework for a11y test suggestions

## Target and Level Configuration

### If argument provided:

- Parse for file path or component name
- Parse for `--level` flag (AA or AAA)
- Default to WCAG 2.1 Level AA if not specified

### If no argument:

**Q1: Audit Target** — ask what to audit (component / page / directory / whole app / recent changes).
**Q2: Compliance Level** — Level A, AA (recommended), or AAA.
**Q3: Focus Areas (optional)** — contrast, keyboard, screen reader, forms, dynamic content, or all.

## State Management

Create `.ui-design/audits/audit_state.json` with audit id, target, wcag level, focus areas, status, issue counts.

## Audit Execution

### 1. File Discovery
Identify all files to audit (single file, component + related files, directory recursively, or whole app).

### 2. Static Code Analysis
For each file, check against WCAG criteria:

- **Perceivable (1.x):** text alternatives, time-based media, adaptable (semantic HTML, heading hierarchy, labels, tables), distinguishable (contrast 4.5:1 / 3:1, color not sole means, resize to 200%, focus indicators, reflow at 320px).
- **Operable (2.x):** keyboard accessible (no traps, logical order, ARIA patterns), enough time, seizures (no >3 flashes/s, reduced motion), navigable (skip links, page title, focus visible, link purpose), input modalities (touch targets 44x44px / 24px).
- **Understandable (3.x):** readable (lang attribute, defined terms), predictable (no unexpected changes, consistent navigation), input assistance (descriptive errors, labels, suggestions).
- **Robust (4.x):** compatible (valid HTML, proper ARIA, status messages announced).

### 3. Pattern Detection
Identify common anti-patterns: missing alt text, onClick without keyboard handler, div/span with click handlers, non-semantic buttons, missing form labels, positive tabindex, empty links, missing lang attribute, autofocus.

### 4. Color Contrast Analysis
Extract color combinations and compute WCAG contrast ratios; flag failures (normal text 4.5:1 AA / 7:1 AAA; large text 3:1 AA / 4.5:1 AAA; UI components 3:1 AA).

### 5. ARIA Validation
Verify ARIA roles/attributes/values are valid, check for redundant ARIA, validate references (aria-labelledby, aria-describedby).

## Output Format

Generate audit report in `.ui-design/audits/{audit_id}.md` with: executive summary (compliance status, severity table), critical issues, serious issues, moderate issues, minor issues, passed criteria, recommendations (quick wins / medium / significant effort), testing resources.

Each issue includes: WCAG criterion, severity, location (`file:line`), element snippet, problem, impact, remediation, code fix (before/after), and testing notes.

## Completion

Update `audit_state.json` to `complete` with final issue counts and display a summary with next-step options (view critical issues, guided fix mode, generate tests, export report, audit another component).

## Guided Fix Mode

If user chooses to fix issues, address them one at a time starting with critical, re-validating after each fix.

## Error Handling

- If file not found: suggest alternatives, offer to search.
- If not UI code: explain limitation, suggest correct target.
- If color extraction fails: note in report, suggest manual check.
- If audit incomplete: save partial results, offer to resume.

_WCAG Reference: https://www.w3.org/WAI/WCAG21/quickref/_
