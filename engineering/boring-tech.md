# Skill: Boring Tech

## Rule
When choosing tools, libraries, or architectural patterns, prefer boring: widely-used, well-documented, battle-tested, easy to swap out, easy to hire help for later. Custom code requires justification; framework defaults don't.

## Why this exists
Agents trained on production code suggest interesting tools because interesting tools generate more discussion in their training data. Solo devs can't afford interesting — they need things that work, that they can debug, that have answers on Stack Overflow.

The boring choice is almost always the right choice for v1.

## Default choices

### Database
- **Start with SQLite.** It handles thousands of writes per second on a laptop. It scales to tens of thousands of users for most apps.
- **Postgres** when you need real concurrency or multi-machine deployment. Not before.
- **NoSQL** only when you've actually outgrown a relational model. Almost never on day one.

### Backend architecture
- **Monolith.** One process, one deployment, one place to look for bugs.
- **Microservices** when team size or scale forces it. Solo devs are never forced.

### Web framework
- **Django, Rails, Laravel, Phoenix** for full-stack with built-in auth, ORM, admin.
- **FastAPI, Express** when you need just an API.
- **Don't** build a SPA frontend unless you specifically need rich interactivity. Server-rendered HTML + HTMX or Turbo handles most cases with 1/10 the complexity.

### Authentication
- **Use a managed service** (Clerk, Auth0, Supabase Auth) for v1.
- **Use the framework's built-in auth** if managed services are too expensive.
- **Never roll your own** unless you specifically know what you're doing. Password hashing, session management, password reset flows — they all have subtle bugs.

### Hosting
- **Managed platforms** (Vercel, Render, Fly.io, Railway, Heroku) for v1.
- **VPS** when you've outgrown managed pricing.
- **Kubernetes** when you have a team that can run it. Never as a solo dev.

### Background jobs
- **Database-backed queues** (e.g., `django-q`, `solid_queue`) for v1.
- **Redis-backed queues** (Sidekiq, RQ, Celery) when DB queues hit limits.
- **Kafka, RabbitMQ** when you have actual event-driven requirements.

### Frontend
- **Framework defaults.** Use what the backend framework wants.
- **HTMX or Turbo** for interactive forms without a SPA.
- **React/Vue/Svelte** only when you have client-side state worth managing.

## How to apply

In the implementer system prompt:

> When choosing a tool, library, or architectural pattern, default to the boring choice listed in `boring-tech.md`. To use a non-default choice, justify it in the decision log with: (1) the specific user-facing reason the default is insufficient, and (2) what you'll lose by going non-default.

In the reviewer system prompt:

> If a non-default choice is used without justification in the decision log, flag as Major. Custom auth, custom queue infrastructure, and custom session management without documented justification are Critical.

## What this prevents
- Spending v1 budget on infrastructure complexity instead of features
- Stack choices the user can't maintain or debug
- Resume-driven development that delays shipping
- Solving problems you don't actually have yet

## When to override
The boring default is wrong when:
- The user has documented domain expertise in a different stack
- A specific user-facing requirement rules out the default (e.g., real-time collaboration rules out server-rendered HTML)
- Compliance or contractual requirements force a specific choice

Override is fine. Override silently is not. Document the override in the decision log.

## Anti-pattern
Choosing a tool because you want to learn it. Solo dev = your learning budget and your shipping budget are the same pool. Pick boring tools for projects you want to ship; pick interesting tools for projects where shipping isn't the point.
