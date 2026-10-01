# backend — FastAPI service

The API service: **FastAPI + SQLModel + PostgreSQL**, JWT authentication,
email-based password recovery. Owns the OpenAPI schema that the frontend's
client is generated from.

**For work in this service, load the `backend-python` skill.**

## Layout

- `app/main.py` — FastAPI app entry point; mounts `app/api/main.py` router.
- `app/api/routes/` — endpoint modules (`items`, `login`, `users`, `utils`,
  `private`). Add new routes here and register them in `app/api/main.py`.
- `app/api/deps.py` — shared dependencies (DB session, current user).
- `app/models.py` — **all** SQLModel models and Pydantic schemas in one file.
- `app/crud.py` — Create/Read/Update/Delete helpers.
- `app/core/` — `config.py` (Pydantic Settings), `db.py`, `security.py`.
- `app/alembic/versions/` — database migrations.
- `tests/` — Pytest suite.

## Conventions

- **Dependencies:** managed with `uv`. `uv sync` to install; `uv add <pkg>` to
  add. Python `>=3.10`.
- **Models:** define new tables/schemas in `app/models.py`, then generate a
  migration — `alembic revision --autogenerate -m "..."` — and commit it.
  Never change a table without a migration.
- **Settings:** read config via `app.core.config.settings`; never `os.environ`
  directly. New settings are typed fields on the `Settings` class.
- **Typing is strict:** `mypy --strict` and `ty` both run in lint. Annotate
  everything.
- **No `print`** — ruff rule `T201` rejects it.
- Changing any route signature or model is an **API contract change**: rerun
  `bash ../scripts/generate-client.sh` so the frontend client stays in sync.

## Commands

Run from `backend/`:

- Lint: `bash scripts/lint.sh` — `mypy app` + `ty check app` + `ruff check app`
  + `ruff format app --check`.
- Autofix formatting: `bash scripts/format.sh`.
- Test: `bash scripts/test.sh` — `coverage run -m pytest tests/` (**requires a
  reachable PostgreSQL**; from the repo root, `bash scripts/test.sh` brings the
  stack up via Docker Compose).
- Build: none — the Docker image (`Dockerfile`) is the deployable artifact.

## Gotchas

- Migrations are normally created *inside* the running container so the
  generated files land in your mounted `app/` dir — see `README.md`.
- `app/email-templates/`: edit the `.mjml` files in `src/`, export the built
  `.html` into `build/`. The app uses `build/`.
- `scripts/prestart.sh` runs migrations + seeds initial data on boot.
