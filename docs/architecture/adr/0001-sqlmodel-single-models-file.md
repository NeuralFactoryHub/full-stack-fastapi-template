# ADR-0001: Single `models.py` with SQLModel for tables and API schemas

- **Status:** Accepted
- **Date:** 2026-05-22 (documented retrospectively)
- **Deciders:** Template authors

## Context

The application needs both database table definitions and API request/response
schemas. A typical stack keeps these separate — SQLAlchemy models in one place,
Pydantic schemas in another — and writes mapping code between them. That
duplication is a frequent source of drift and boilerplate.

SQLModel unifies SQLAlchemy and Pydantic: a single class hierarchy can serve as
both the ORM table and the validated API model. The domain is also small — two
entities — so the cost of a single file is low.

## Decision

We will define **all** SQLModel table models and Pydantic API schemas in one
file, `backend/app/models.py`, using a layered class pattern per entity:

- `*Base` — fields shared by input and output.
- `*Create` / `*Register` — inbound creation bodies.
- `*Update` / `*UpdateMe` — inbound all-optional patch bodies.
- `* (table=True)` — the persisted table, adding ids, server-only fields, and
  relationships.
- `*Public` / `*sPublic` — outbound response models that structurally exclude
  sensitive fields (e.g. `hashed_password`).

## Alternatives Considered

| Option | Why not chosen |
|--------|----------------|
| Separate SQLAlchemy models + Pydantic schemas | Duplicate field definitions and hand-written mapping; the drift SQLModel exists to remove. |
| One file per entity (`models/user.py`, `models/item.py`) | Over-structured for a two-entity domain; SQLModel needs all models imported together for relationship resolution anyway. |
| Plain SQLAlchemy + manual serialization | Loses Pydantic validation at the API edge and OpenAPI schema generation. |

## Consequences

**Positive**

- One definition per field; the API schema and the table cannot drift.
- Sensitive fields are excluded *by construction* — `hashed_password` is simply
  not a field of `UserPublic`.
- All models are imported together, so SQLModel resolves relationships
  reliably (the documented failure mode when models are split).

**Negative / trade-offs**

- `models.py` is a change-amplifier: it is touched by nearly every feature and
  is a natural merge-conflict hotspot.
- The single-file convention will not scale to a large domain; a future split
  into a `models/` package would itself warrant a new ADR.

**Follow-ups**

- If the domain grows substantially, revisit with an ADR proposing a `models/`
  package while preserving the unified import requirement.
