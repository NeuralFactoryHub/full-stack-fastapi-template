# UX/WCAG 2.1 AA review — Items free-text search

**Verdict: PASS** (no Critical/Major findings; 4 Minor, all optional polish).
Method: headless Chromium (playwright-core) against http://localhost:5173, superuser, 1280px and 375px, light and dark. Real data (non-`qa-` item "Walid's First Item" used for hits; "zzzqq" for no-match). Read-only. Not done: real screen reader (VoiceOver/NVDA), axe-core, Safari/Firefox. Live-region wording was verified in the DOM only.
Screenshots: `screens/{light,dark}-{d,m}-N-*.png` (d=1280, m=375; 1 empty, 2 focus, 3 table filtered, 4 dimmed, 5 no results, 6 cards filtered; `light-d-7` × focus, `light-d-8` empty-state button focus).

## Checked and passing
- **Toolbar**: search 320px (`sm:max-w-xs`) left, Table/Cards tabs right, both 36px tall and vertically aligned (y=188). At 375px it stacks (search full width 327px, tabs below, left-aligned), no horizontal overflow (docW = vw). Same shadcn Input/Button/Tabs tokens, dark mode inputs are `dark:bg-input/30` like the rest of the app.
- **Field states**: empty (icon + placeholder), with text (× appears), focus (3px `ring-ring/50` + border, clearly visible in both themes: `*-2-focus`). Input is 16px on mobile (no iOS zoom), 14px on desktop.
- **Contrast**: placeholder/search icon `muted-foreground` oklch(.556) on white ≈ 4.7:1 (light); oklch(.708) on near-black ≈ 6+:1 (dark). Input text and × are foreground colour. Pass 1.4.3 / 1.4.11.
- **Keyboard**: Tab order input → × → active tab → table. × is a real `<button>`, `aria-label="Clear search"`, 32×32px (≥24 for 2.5.8; below the 44px AAA/touch ideal). Enter on × clears and focus returns to the input. Esc in a non-empty field clears it and keeps focus; URL drops `?q`. "Clear search" in the empty state (Enter) clears and moves focus to the input.
- **Landmarks/labels**: exactly one `<search>` landmark (no label needed, single one); input has `aria-label="Search items"`; icon is `aria-hidden`.
- **Live region**: `<output class="sr-only">` (implicit `role=status`) reads `No items match "zzzqq"` / `N item(s) match "…"`; empty when `q` is empty (no noise on load).
- **Results states**: filtered table and cards correct at both sizes; no-match state is centred, readable, text wraps (`break-all`) on mobile (`*-5-noresults`). Copy matches the design: "Search items…", `No items match "…"`, "Try a different search", "Clear search" — plain, English, consistent with "You don't have any items yet".
- **Dimmed refetch** (API delayed 3s): container `aria-busy=true`, opacity 0.6, 150ms transition, previous rows stay (no skeleton flash) (`*-4-dimmed`).

## Findings (all Minor)
1. **Dimmed state lowers text contrast (1.4.3) in dark mode.** `opacity-60` on the whole region turns muted text (ID, description, headers) into roughly 3:1 or less while refetching (`dark-d-4-dimmed`). Transient (<1s normally) and not a stable state, but a slow API makes it persist. Fix: dim only the rows, or `opacity-75`; keep it as is if accepted as transient.
2. **No perceivable "searching" feedback beyond the dim.** Sighted users get opacity only; AT users get nothing until the result count is announced, and `aria-busy=true` on the wrapper that contains the `<output>` may make some screen readers hold announcements until it flips back (expected, results still announce afterwards). Fix, optional: move the `<output>` outside the `aria-busy` div so the count is announced independent of the busy state.
3. **Two controls share the name "Clear search"** (× and the empty-state button) when no results. They do the same thing so this is acceptable; if the QA/e2e uses `getByRole('button', {name:'Clear search'})` it must disambiguate (`.last()` / scope to `search`). Fix, optional: name the × "Clear search text" or leave as is.
4. **Mobile keyboard hints missing.** Input is `type=text`, so the mobile keyboard shows "return" rather than "search". Fix: add `enterKeyHint="search"` (keep `type=text`; `type=search` would add a native second × in WebKit). Also `autoComplete="off"` to avoid browser history dropdown over the field.

## Not an issue / noted
- Heading levels: empty states use `<h3>` under `<h1>` (no `<h2>`), same as the pre-existing `EmptyItems`. Pre-existing, out of scope.
- Reduced motion: only a 150ms opacity transition; acceptable for 2.3.3, no `motion-reduce` needed.
- Target size of × 32px passes 2.5.8 (24px); 44px not required at AA.

## NOT_REVIEWED
- Real screen-reader output and live-region timing; Safari/Firefox rendering; browsers' autofill overlays.
