# Architecture Documentation

Architecture documentation for the **Full Stack FastAPI Project** — a FastAPI +
SQLModel + PostgreSQL backend and a React 19 + Vite SPA, wired together by an
auto-generated typed API client and deployed via Docker Compose behind Traefik.

This set follows a lightweight [arc42](https://arc42.org/) structure for prose
and the [C4 model](https://c4model.com/) for diagrams. Diagrams are Mermaid —
they render directly on GitHub.

## Documents

| Document | Scope |
|----------|-------|
| [`system-architecture.md`](system-architecture.md) | System context, container & component views, runtime scenarios, quality attributes. |
| [`data-architecture.md`](data-architecture.md) | Data model, ERD, persistence strategy, schema migrations, data flow. |
| [`security-architecture.md`](security-architecture.md) | Authentication/authorization flows, trust zones, threat model, secrets. |
| [`deployment-architecture.md`](deployment-architecture.md) | Docker Compose topology, environments, CI/CD pipelines, operations. |
| [`adr/`](adr/) | Architecture Decision Records — the *why* behind structural choices. |

## How to read this

1. Start with **`system-architecture.md`** — the C4 Context and Container
   diagrams give the whole picture in two screens.
2. Drill into **data**, **security**, or **deployment** as needed.
3. Consult **ADRs** to understand why a decision was made before changing it.

## Source of truth & maintenance

- Code is authoritative. Where this documentation and the code disagree, the
  code wins — fix the doc.
- `.claude/project.yml` is the machine-readable service/contract registry; this
  documentation is its human-readable companion.
- The backend **OpenAPI schema** is the authoritative API contract. These docs
  describe its shape, not its detail — see the live schema at
  `/api/v1/openapi.json` or the Swagger UI at `/docs`.
- Update the relevant document in the **same change** that alters architecture
  (new service, new route group, new external dependency, new trust boundary).
- Record any non-obvious structural decision as a new ADR (see
  [`adr/template.md`](adr/template.md)).

_Last updated: 2026-05-22 — derived from the codebase at branch `master`._
