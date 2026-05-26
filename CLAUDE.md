# Full Stack FastAPI Project

Full-stack template: a **FastAPI + SQLModel + PostgreSQL** backend and a
**React 19 + Vite** single-page frontend, wired together by an auto-generated
typed API client. Runs locally and in production via Docker Compose behind
Traefik.

This root file holds only cross-cutting context. Each service has its own
`CLAUDE.md` with local conventions — **read the one for the service you are
working in**:

- [`backend/CLAUDE.md`](backend/CLAUDE.md) — FastAPI service
- [`frontend/CLAUDE.md`](frontend/CLAUDE.md) — React/Vite SPA

`.claude/project.yml` is the machine-readable source of truth for services,
commands, dependencies, and contracts.

## Codebase map

| Path          | What it is                                                        |
|---------------|-------------------------------------------------------------------|
| `backend/`    | FastAPI app, SQLModel models, Alembic migrations, Pytest suite.   |
| `frontend/`   | React 19 + Vite SPA; `src/client/` is the generated API client.   |
| `scripts/`    | Repo-level scripts (`test.sh`, `generate-client.sh`).             |
| `hooks/`      | Copier post-generation hooks (template tooling, not app code).    |
| `.copier/`    | Copier template machinery (`copier.yml` drives project scaffolding). |
| `.github/`    | GitHub Actions CI/CD workflows.                                   |
| `img/`        | README screenshots.                                               |
| `compose*.yml`| Docker Compose: base, local override, Traefik proxy.              |
| `.claude/`    | Agent configuration (`project.yml`, skills, agents, SDLC).        |

## Cross-cutting gotchas

- **The API is a contract.** The frontend's `src/client/` is *generated* from
  the backend's OpenAPI schema. After any backend change that alters routes,
  request/response models, or status codes, regenerate it:
  `bash scripts/generate-client.sh` (needs the backend importable). Do not
  hand-edit files under `frontend/src/client/`.
- **`.env` at the repo root** is shared by both services and Docker Compose.
  Defaults contain `changethis` placeholders — never deploy those.
- **Backend tests need a database.** `bash scripts/test.sh` (root) spins up the
  full stack via Docker Compose; the backend-local `scripts/test.sh` assumes a
  reachable PostgreSQL.
- **Frontend E2E tests need the backend running** (`docker compose up -d --wait
  backend`) before `bunx playwright test`.
- This repo is also a **Copier template**: `copier.yml` + `hooks/` rewrite
  files on generation. Treat `hooks/` and `.copier/` as template tooling.

## Editor setup

Symbol-level navigation beats text search on a multi-language repo — a
high-ROI, one-time install. Recommended language servers:

| Stack            | Language server                | Tracked in            |
|------------------|--------------------------------|-----------------------|
| `python-fastapi` | `pyright`                      | `project.yml` → `onboarding.lsp` |
| `react-vite`     | `typescript-language-server`   | `project.yml` → `onboarding.lsp` |

Flip `done: true` in `project.yml` once each is installed.

## SDLC & Workflow

The project follows a defined SDLC (`.claude/SDLC.md`) using Claude agents and skills. 

Key conventions:
- Branching: `feature/<service>-<topic>` or `fix/<service>-<issue-id>` from `main`
- Commits: use conventional commit messages via `gh-commit` command
- Code review via `review-new-code` command and `reviewer` agent
- QA via `qa` agent, UX review via `ui-ux-reviewer` agent

## Layered context

This root CLAUDE.md is intentionally lean — pointers and cross-cutting gotchas only. The
project is a single flat pipeline (`src/*.py` + `main.py`), so there is no per-service
CLAUDE.md to consult.

The harness also runs deterministic **hooks** (`.claude/hooks/`): touched files are
auto-formatted, writes to generated/build paths are blocked, and a Stop hook reminds you to
journal. Hooks act on their own — see `.claude/hooks/README.md`.

## ClickUp Integration

Configurazione ClickUp in `.claude/project.yml` sotto `integrations.clickup`. **Consulta sempre `project.yml`** per ottenere workspace_id, list_id, default_assignee e default_status prima di interagire con ClickUp.

### Auto Status Sync

**When implementing user stories, always keep ClickUp in sync:**
- **Starting a story:** invoke `@update-story-status` with status `in progress`
- **Opening a PR for a story:** invoke `@update-story-status` with status `review`
- **Story verified/merged:** invoke `@update-story-status` with status `closed`

This applies to all skills and agents that touch user stories — `@executing-plans`, `@team-dispatcher`, direct implementation, etc. The sync state lives in `docs/backlog/.clickup-sync.json`.

## Rules

- Extremely concise in all interactions and commit messages. Sacrifice grammar for concision.
- At end of each plan, list unresolved questions (extremely concise).
- DO NOT write tests unless explicitly requested.
- DO NOT run dev server — assume already running.
- Add code comments sparingly — focus on "why", not "what".
- Write design docs to `docs/plans/YYYY-MM-DD-<topic>/design.md`.
- Follow the project SDLC in `.claude/SDLC.md` for end-to-end feature delivery (idea → design → ClickUp → implementation → release).

### Skills (when available in a subdirectory)

- **Read skill files before executing.** Always read the SKILL.md fully and follow every step literally.
- **One question per message.** Never batch multiple questions.
- **Incremental design presentation.** Present design in 200-300 word sections. Ask for validation after each section.
- **Follow after-design steps.** Ask "Ready to set up for implementation?" then use writing-plans skill.

# IMPORTANT
- When the user asks for implementing a new task always follow SDLC