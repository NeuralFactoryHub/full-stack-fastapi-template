# ADR-0003: Stateless JWT bearer authentication

- **Status:** Accepted
- **Date:** 2026-05-22 (documented retrospectively)
- **Deciders:** Template authors

## Context

The application needs to authenticate users of a browser SPA against a JSON API
served by a separate backend. The backend runs with multiple Uvicorn workers
and is intended to scale horizontally, so any session state shared across
requests would need an external store.

The frontend and backend are different origins, so the mechanism must work
cross-origin and be expressible in the OpenAPI schema (the API surface is
contract-generated — see [ADR-0002](0002-generated-typed-api-client.md)).

## Decision

We will use **stateless JWT bearer tokens**:

- `POST /api/v1/login/access-token` accepts an OAuth2 password-grant form and
  returns a JWT signed with `SECRET_KEY` using **HS256**.
- The token carries `sub` (user UUID) and `exp`; lifetime is 8 days
  (`ACCESS_TOKEN_EXPIRE_MINUTES`).
- The SPA stores the token in `localStorage` and the generated client sends it
  as an `Authorization: Bearer` header on every request.
- The backend validates each request with the `get_current_user` dependency
  (decode → load user → check `is_active`); `get_current_active_superuser` adds
  the privilege check.
- Passwords are hashed with `pwdlib` (Argon2 primary, bcrypt fallback).

No session state is stored server-side.

## Alternatives Considered

| Option | Why not chosen |
|--------|----------------|
| Server-side sessions | Requires a shared session store across workers/hosts; adds stateful infrastructure. |
| JWT in httpOnly cookie | More XSS-resistant, but adds CSRF handling and complicates the cross-origin, OpenAPI-described flow. A reasonable future hardening — see consequences. |
| OAuth2 / OIDC via an external IdP | Heavyweight for a self-contained template; adds an external dependency and setup burden. |
| Access + refresh token pair | More secure (short access-token TTL) but more moving parts than a template baseline needs. |

## Consequences

**Positive**

- The backend is fully stateless — any worker or replica can serve any request;
  horizontal scaling needs no session store.
- The flow is standard OAuth2 password grant, so it is expressed cleanly in the
  OpenAPI schema and the generated client.
- Argon2 hashing with transparent re-hash-on-login keeps stored credentials
  current.

**Negative / trade-offs**

- The token sits in `localStorage`, readable by any injected script — an XSS
  flaw becomes full account takeover.
- Tokens cannot be revoked; a leaked token is valid for its full 8-day
  lifetime.
- `SECRET_KEY` is a single high-value secret — its compromise forges any
  identity, and rotating it logs everyone out.

**Follow-ups**

- Consider hardening to httpOnly + `SameSite` cookies with a CSP, and/or a
  short-lived access token plus refresh token with a revocation list. Each
  would warrant a superseding ADR.
- Add rate limiting on `login` and `password-recovery` (tracked in the security
  architecture doc).
