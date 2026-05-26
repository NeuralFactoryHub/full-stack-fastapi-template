# ADR-0004: Traefik reverse proxy with Docker-label routing

- **Status:** Accepted
- **Date:** 2026-05-22 (documented retrospectively)
- **Deciders:** Template authors

## Context

The deployed stack exposes several HTTP services — the frontend SPA, the
backend API, and the Adminer DB UI — that must share ports 80/443 on a single
host, each reachable at its own hostname and served over HTTPS with valid
certificates.

The stack is already orchestrated with Docker Compose, and the template aims for
a one-command deploy with minimal manual configuration. Multiple independent
stacks may run on the same host.

## Decision

We will use **Traefik 3.6** as the single ingress reverse proxy:

- Traefik runs as its own service on a shared external Docker network,
  `traefik-public` (defined in `compose.traefik.yml`, deployed once per host).
- Application services declare their routing through **Docker labels** —
  hostname rules, entrypoints, TLS — rather than a central proxy config file.
- Routing is **host-based**: `dashboard.<domain>`, `api.<domain>`,
  `adminer.<domain>`, `traefik.<domain>`.
- Traefik terminates TLS using **Let's Encrypt** certificates obtained via the
  ACME TLS challenge, and permanently redirects HTTP to HTTPS.
- `exposedbydefault=false` — only services that explicitly carry
  `traefik.enable=true` labels are routable; the database carries none.
- Locally, `compose.override.yml` substitutes a Traefik with an insecure
  dashboard and a no-op HTTPS redirect.

## Alternatives Considered

| Option | Why not chosen |
|--------|----------------|
| nginx as reverse proxy | Static config file must be edited and the proxy reloaded for every routing change; no native Docker service discovery or automatic ACME. |
| Caddy | Automatic HTTPS like Traefik, but weaker Docker-label service discovery for a multi-stack host. |
| Cloud load balancer (ALB / Cloud LB) | Ties the template to a specific cloud provider; the template targets a plain Docker host. |
| Per-service published ports, no proxy | No shared 443, no hostname routing, no automatic TLS. |

## Consequences

**Positive**

- Adding or moving a route is a label change on the service — no proxy config
  file, no reload.
- TLS certificates are issued and renewed automatically.
- Services are private by default; exposure is explicit and auditable.
- One Traefik instance fronts multiple independent stacks on the same host.

**Negative / trade-offs**

- Traefik mounts the Docker socket to read labels — a privileged, sensitive
  mount that widens the host's attack surface.
- Routing intent is spread across service labels rather than centralised, which
  can be harder to review at a glance.
- Traefik is a single ingress point — a SPOF for all fronted services in the
  default single-host topology.

**Follow-ups**

- For HA, run Traefik redundantly behind an external load balancer or move to
  an orchestrator — would warrant a superseding ADR.
- Add security headers (HSTS, CSP, `X-Frame-Options`) as Traefik middleware.
