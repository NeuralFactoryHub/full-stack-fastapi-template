# ADR-0002: Generated typed API client as the frontend/backend contract

- **Status:** Accepted
- **Date:** 2026-05-22 (documented retrospectively)
- **Deciders:** Template authors

## Context

The React frontend and the FastAPI backend are separate applications in one
repository. They must agree on every endpoint path, request shape, response
shape, and status code. Hand-written HTTP calls let that agreement rot silently:
a backend rename compiles fine on both sides and fails only at runtime.

FastAPI already produces an authoritative OpenAPI 3 schema from its routes and
Pydantic models. That schema can drive code generation instead of being mere
documentation.

## Decision

We will treat the backend's **OpenAPI schema as the single source of truth** for
the API contract, and generate the frontend's HTTP layer from it:

- `scripts/generate-client.sh` dumps `app.openapi()` to `openapi.json`.
- `@hey-api/openapi-ts` generates a typed client into `frontend/src/client/`
  (`sdk.gen.ts`, `types.gen.ts`, `schemas.gen.ts`).
- Frontend feature code calls only the generated services (wrapped in TanStack
  Query) — never raw `fetch`/`axios`.
- `custom_generate_unique_id` in `app/main.py` derives each operation id as
  `{tag}-{route name}`, so generated method names stay stable.
- Files under `frontend/src/client/` are generated artefacts and are never
  hand-edited.

Any backend change that alters routes, request/response models, or status codes
**requires** regenerating the client in the same change.

## Alternatives Considered

| Option | Why not chosen |
|--------|----------------|
| Hand-written `fetch`/`axios` calls | No compile-time link to the backend contract; silent runtime drift. |
| Shared types package, calls still hand-written | Types could be shared but call sites, paths, and status handling still drift. |
| GraphQL with a typed client | Larger paradigm shift; REST + OpenAPI is sufficient for a CRUD template and keeps the backend conventional. |
| Runtime schema validation only | Catches mismatches late (in the browser), not at build time. |

## Consequences

**Positive**

- The TypeScript compiler catches contract breaks at build time, not in QA.
- Endpoint paths, payloads, and types are written once, on the backend.
- New endpoints become typed client methods for free.

**Negative / trade-offs**

- Generated files are committed to version control and can drift if a developer
  skips regeneration — CI should verify they are up to date.
- The generator and FastAPI's operation-id scheme become part of the build
  contract; changing tags or route names renames client methods.
- Cross-cutting backend changes ripple into a frontend regeneration step.

**Follow-ups**

- Add a CI check that fails if `scripts/generate-client.sh` produces a diff.
