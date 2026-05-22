---
name: recurring-issues
description: Accessibility and UX issues found during reviews — watch for these in new components
metadata:
  type: feedback
---

## Issues found so far

### Missing aria-label on icon-only action menus

Pattern to watch: any `<Button size="icon">` with only an icon child needs explicit `aria-label`.
**Why:** lucide icons are aria-hidden; icon-only buttons with no label are WCAG 4.1.2 violations.
**How to apply:** Flag every `size="icon"` Button that lacks aria-label, aria-labelledby, or sr-only text.
**Status in items-card-view:** Fixed in HEAD 40aa772 — `aria-label={`Actions for ${item.title}`}`.
**New pattern found:** template literal labels can carry trailing whitespace from data; add `.trim()` defensively.

### CopyId button invisible on touch (opacity-0 group-hover only)

`CopyId.tsx`: `opacity-0 group-hover:opacity-100`. On touch devices hover never fires.
**Partial fix applied:** `group-focus-within:opacity-100` added — keyboard now works.
**Remaining:** `@media (hover: none)` rule still needed for pointer-coarse (touch) devices.
**Fix pattern:** `opacity-0 group-hover:opacity-100 group-focus-within:opacity-100` + CSS `@media (hover: none) { opacity: 1 }` or Tailwind `[@media(hover:none)]:opacity-100`.

### CardTitle is a div, not a heading

shadcn `CardTitle` defaults to `div`. Cards representing named entities should use `h3`/`h4`. Use `asChild` pattern: `<CardTitle asChild><h3 ...>`.
**Status in items-card-view:** Still open (minor, no blocker).

### Card grid — use native ul/li, not role="list"

Resolved pattern: `<ul aria-label="Items" className="grid ... list-none p-0 m-0">` with `<li>` per card. Prefer native elements over ARIA roles for list semantics.
**Status in items-card-view:** Fixed in HEAD 40aa772.

### View state persistence — project-scoped non-goal

In this project, view toggle state (table/cards) resetting on navigation is an **explicit non-goal** agreed with the client. Do not re-flag in future reviews of this feature.
**Why:** Scoping decision made during design phase.

### Suspense + wrapper div layout bug (stale build artefact)

In `items.tsx`, what appeared to be a Suspense boundary stripping a flex wrapper was a stale Docker image — not a code bug. The v2 build confirmed correct rendering. Lesson: always verify with a fresh build before attributing layout issues to Suspense behaviour.
