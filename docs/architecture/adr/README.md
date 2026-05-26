# Architecture Decision Records

An **ADR** captures a single significant architectural decision: its context,
the choice made, and the consequences. ADRs are immutable once `Accepted` —
when a decision changes, write a new ADR that supersedes the old one rather
than editing history.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-sqlmodel-single-models-file.md) | Single `models.py` with SQLModel for tables and API schemas | Accepted |
| [0002](0002-generated-typed-api-client.md) | Generated typed API client as the frontend/backend contract | Accepted |
| [0003](0003-jwt-bearer-auth.md) | Stateless JWT bearer authentication | Accepted |
| [0004](0004-traefik-reverse-proxy.md) | Traefik reverse proxy with Docker-label routing | Accepted |
| [0005](0005-alembic-migrations.md) | Alembic migrations as the only schema-change mechanism | Accepted |

## Process

1. Copy [`template.md`](template.md) to `NNNN-short-title.md` (next number,
   zero-padded).
2. Draft with status `Proposed`; open it in a pull request for discussion.
3. On merge, set the status to `Accepted` and add a row to the index above.
4. To revisit a decision, write a new ADR; set the old one's status to
   `Superseded by ADR-NNNN` and add a forward link.

## Statuses

- **Proposed** — under discussion, not yet in effect.
- **Accepted** — the decision is in force.
- **Superseded** — replaced by a later ADR (link it).
- **Deprecated** — no longer relevant, not directly replaced.

> ADRs 0001–0005 were written retrospectively to document decisions already
> embodied in the codebase as of 2026-05-22. Their "context" reflects the
> reasoning evident from the template's design.
