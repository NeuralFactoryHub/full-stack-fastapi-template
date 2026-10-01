# UI/UX Reviewer Journal — items-search

### Review Log

#### Review: Items page search (SearchItems + items route)
**URL:** http://localhost:5173/items (and ?q=)
**Viewports:** 1280, 375; light + dark
**Screenshots:** 26 in docs/project_context/items-search/screens
**Verdict:** PASS
**Critical issues:** 0 | **Major:** 0 | **Minor:** 4
**Key findings:** Layout, focus management, labels, landmark, live region and contrast pass. Minor: dimmed-state contrast in dark, aria-busy around live region, duplicate "Clear search" names, missing enterKeyHint.
**Tooling note:** Chrome MCP unavailable; used playwright-core from another local repo with cached Chromium.
**NOT_REVIEWED:** real screen reader, Safari/Firefox.
