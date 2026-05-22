---
name: project-conventions
description: Design system, stack details, and screenshot workflow confirmed for this project
metadata:
  type: project
---

## Stack

- React 19 + Vite 7 SPA (NOT Next.js). TanStack Router (file-based). TanStack Query.
- Tailwind CSS 4 + shadcn/ui. Biome linter. Package manager: bun.
- Dark mode default in dev (user has dark theme active).
- App URL: http://localhost:5173. Backend: http://localhost:8000.
- Login: superuser credentials are read from `.env` (`FIRST_SUPERUSER` / `FIRST_SUPERUSER_PASSWORD`) — see `.env`, not stored here.

## Design conventions

- Colour palette: dark background `oklch(0.205 0 0)`, foreground near-white `oklch(0.985 0 0)`, muted-foreground `oklch(0.708 0 0)`, brand teal primary used for CTAs and active states.
- shadcn/ui `Button` variants in use: `default` (teal), `outline`, `ghost`. `size="icon"` = 36×36 px (size-9).
- `ButtonGroup` component at `src/components/ui/button-group.tsx` — sets `role="group"`, forwards all props via spread (including aria-label).
- Cards use `data-slot` attributes: `card`, `card-header`, `card-title`, `card-action`, `card-content`, `card-footer`.
- `CardTitle` renders as a `div` (not a heading) in shadcn default.
- Icons from lucide-react; lucide icons carry `aria-hidden="true"` automatically.
- Focus ring: `focus-visible:ring-ring/50 focus-visible:ring-[3px]` — shadcn default, present on all Button variants.
- Empty state pattern: rounded-full muted bg icon + h3 + muted-foreground p.
- Pagination: `DataTablePagination` from `src/components/Common/DataTablePagination.tsx`, hides itself when `pageCount <= 1`.

## Screenshot workflow

- Playwright module at `node_modules/playwright` (relative to repo root).
- Use ESM import from direct path: `import { chromium } from '.../node_modules/playwright/index.mjs'`.
- Run with `node --experimental-vm-modules /tmp/script.mjs`.
- Screenshots directory convention: `docs/project_context/<feature>/screenshots/`.
- The MCP Playwright browser_evaluate filename trick does NOT produce real screenshots (saves "null" bytes). Always use the Node script approach above.

**Why:** The mcp**playwright**browser_evaluate tool with a filename parameter writes the JS return value as bytes, not a real screenshot.
**How to apply:** Always use the standalone Node ESM script for screenshot capture in this project.
