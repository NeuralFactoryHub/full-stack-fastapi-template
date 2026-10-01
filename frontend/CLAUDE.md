# frontend — React/Vite SPA

The dashboard UI: **React 19 + Vite 7 + TypeScript**, TanStack Router +
TanStack Query for routing/data, Tailwind CSS 4 + shadcn/ui for components.
Talks to the backend through an auto-generated typed API client.

**Skill:** load `frontend-nextjs` for now — its React / Tailwind / shadcn/ui
guidance applies. Note its **Next.js App Router routing conventions do not**:
this is a Vite SPA with TanStack Router. A dedicated `frontend-react` skill
should be created as the proper long-term home (see `.claude/project.yml`).

## Layout

- `src/main.tsx` — app entry point.
- `src/routes/` — TanStack Router route files = the pages.
- `src/routeTree.gen.ts` — **generated** by the TanStack Router plugin; do not
  edit by hand.
- `src/client/` — **generated** OpenAPI client (`sdk.gen.ts`, `types.gen.ts`,
  `schemas.gen.ts`). Do not edit by hand.
- `src/components/` — feature components (`Admin`, `Items`, `UserSettings`,
  `Sidebar`, `Common`, `Pending`) and `components/ui/` (shadcn/ui primitives).
- `src/hooks/` — custom hooks. `src/lib/`, `src/utils.ts` — shared helpers.
- `tests/` — Playwright end-to-end tests.

## Conventions

- **Package manager: Bun.** `bun install`; `bun run dev` (serves on :5173).
- **Data fetching:** call the generated services in `src/client/` through
  TanStack Query — do not write raw `fetch`/`axios`. The API base URL comes
  from `VITE_API_URL`.
- **Routing:** add a file under `src/routes/`; the plugin regenerates
  `routeTree.gen.ts`. Never edit that file directly.
- **Components:** prefer shadcn/ui primitives from `components/ui/`; style with
  Tailwind utility classes. Forms use `react-hook-form` + `zod`.
- **Regenerate the client** after backend API changes:
  `bun run generate-client` (expects an up-to-date `openapi.json`), or run the
  repo-level `bash scripts/generate-client.sh`.

## Commands

Run from `frontend/`:

- Lint: `bun run lint` — Biome check with autofix.
- Build: `bun run build` — `tsc -p tsconfig.build.json` + `vite build`.
- Test: `bun run test` — Playwright E2E. **Requires the backend running**
  (`docker compose up -d --wait backend`). `bun run test:ui` for UI mode.

## Gotchas

- `src/client/` and `src/routeTree.gen.ts` are generated — edits there are
  overwritten.
- Lint is Biome, not ESLint/Prettier; config is `biome.json`.
- The dev server runs *outside* Docker; only the production image uses nginx.
