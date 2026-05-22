# UX & Accessibility Review — Items Card View

**Reviewer:** Da Vinci (review performed by Orchestrator; sub-agent Task tool unavailable in environment)
**Branch:** `feature/frontend-items-card-view` @ `4bf3a08`
**Environment:** `http://localhost:5173/items`, viewport sweeps via Playwright/Chromium
**Date:** 2026-05-22
**Screenshots:** `/tmp/qa-shots/` — `01-default-table.png`, `02-card-view.png`, `03-card-mobile.png`,
`04-card-lg.png`, `05-card-skeleton.png`, `06-no-description.png`

## VERDICT: PASS — no blocking issues

---

## Visual design

- **Table view (01):** unchanged baseline — toggle sits top-right above the table, visually
  grouped with the content it controls.
- **Card view (02 / 04):** clean 3-column grid; cards have consistent padding, title at
  `font-semibold`, muted description, mono UUID in the content slot. Actions menu (vertical
  ellipsis) anchored top-right of each card via `CardAction`. Spacing (`gap-4`) and card
  borders match the app's shadcn surface treatment.
- **Mobile (03, 375px):** single-column stack; cards go full-width; header, "Add Item", and
  the Table/Cards toggle reflow without overlap or clipping.
- **Skeleton (05):** card-shaped placeholders in the same 3-column grid — title bar + two
  description lines + one content line. Matches the resolved card layout, so no perceptible
  layout shift on data load.
- **No-description (06):** italic, muted "No description" placeholder — consistent with the
  table's description column treatment. Good parity.

Visual quality is consistent with the existing design system; no new colors, no ad-hoc
spacing. The card grid is a faithful, scannable alternative to the table.

## UX flow

- Toggle is a shadcn `Tabs` segmented control with clear active-state contrast (active pill
  has a raised `bg-background` + shadow — visible in every screenshot). Each segment pairs a
  lucide icon (`Table2` / `LayoutGrid`) with a text label — unambiguous.
- Switching is instant (no reload, no flash) and the choice persists across reloads and
  re-navigation via `useLocalStorage`. This matches the user's mental model of a sticky
  preference.
- Empty state and loading state are both view-aware — the user always sees a placeholder
  shaped like the layout they chose.

## Accessibility (WCAG 2.1 AA)

| Area               | Assessment                                                                                                                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Toggle semantics   | PASS — Radix `Tabs` exposes `role="tablist"` / `role="tab"`; both tabs have accessible names ("Table", "Cards"). Verified live via `getByRole`.                                             |
| Keyboard           | PASS — Radix `Tabs` provides arrow-key navigation between tabs and a visible `focus-visible` ring (`focus-visible:ring-[3px]` in `tabs.tsx`).                                               |
| Icon-only controls | PASS — toggle tabs carry visible text beside the icon; the copy-ID button keeps its `sr-only` "Copy ID" label; the actions trigger is the same labeled `ItemActionsMenu` used by the table. |
| Contrast           | PASS (visual) — title text is full-contrast on the dark card surface; muted description / mono ID use `text-muted-foreground`, the same token the table already ships — no regression.      |
| Focus order        | PASS — natural DOM order: toggle → cards (each: actions trigger, then copy-ID). No focus traps; actions menu is a Radix dropdown with managed focus.                                        |
| Loading state      | PASS — skeleton is purely decorative; no spurious focusable nodes.                                                                                                                          |
| No layout shift    | PASS — skeleton grid dimensions mirror the card grid (CLS-friendly).                                                                                                                        |

## Findings

No blocking issues. Two non-blocking observations (no action required for this PR):

1. **Copy-ID affordance is hover-only.** The copy button is `opacity-0` until
   `group-hover:opacity-100`. On touch devices (no hover) the control is not discoverable
   until tapped. This is **inherited verbatim from the existing table `CopyId`** (now the
   shared component) — it is design parity, not a regression. Recommend a separate
   backlog item to make `CopyId` touch-friendly across both views, if desired.
2. **Fixed 6-card skeleton.** `PendingItemsGrid` always shows 6 placeholders regardless of
   the eventual item count. Cosmetic; consistent with `PendingItems`' fixed 5 rows.

## Phase 9 readiness

UX PASS. Visual design, UX flow, and WCAG AA accessibility of the card view and the
Table/Cards toggle all hold up. No blocking issues — only two pre-existing/cosmetic notes
that do not gate this PR. Ready for Phase 9.
