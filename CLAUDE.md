# CLAUDE.md

This file provides guidance for AI assistants (Claude and others) working in this repository.

---

## Project Overview

**Repository:** Mijroy/TBI
**Status:** Newly initialized — no source code committed yet.

> Update this section as the project takes shape. Describe the purpose, target users, and high-level goals of the application.

---

## Repository Structure

```
TBI/
└── (no source files yet)
```

> As files are added, maintain this section to reflect the actual layout:
>
> ```
> TBI/
> ├── src/          # Application source code
> ├── tests/        # Test files
> ├── docs/         # Documentation
> ├── CLAUDE.md     # This file
> └── README.md     # Public-facing project description
> ```

---

## Technology Stack

> Document the chosen stack here once decided. For example:
>
> - **Language:** TypeScript / Python / Go / Rust
> - **Framework:** Next.js / FastAPI / Gin / Axum
> - **Database:** PostgreSQL / SQLite / MongoDB
> - **Package manager:** npm / pnpm / pip / cargo

---

## Development Setup

> Fill in once the project is initialized. Typical sections:

### Prerequisites

- List required runtimes and tools (Node.js, Python, Docker, etc.)

### Installation

```bash
# Example — replace with real commands
git clone <repo-url>
cd TBI
# install dependencies
```

### Environment Variables

> List required environment variables and point to any `.env.example` file.

```
# Example
DATABASE_URL=
SECRET_KEY=
```

---

## Common Commands

> Replace with real commands once the toolchain is set up.

| Purpose | Command |
|---------|---------|
| Install dependencies | `<command>` |
| Start dev server | `<command>` |
| Run tests | `<command>` |
| Run linter | `<command>` |
| Format code | `<command>` |
| Build for production | `<command>` |

---

## Git Workflow

### Branch Naming

- Feature branches: `feature/<short-description>`
- Bug fixes: `fix/<short-description>`
- AI-assisted work: `claude/<session-slug>`

### Commit Messages

Use the imperative mood and keep the subject line under 72 characters:

```
Add user authentication endpoint
Fix null pointer in payment processor
Refactor database connection pooling
```

### Pull Requests

- Open a PR against `main` (or the designated base branch) once changes are ready for review.
- Ensure all checks pass before requesting review.
- Reference related issues with `Closes #<issue-number>` in the PR description.

---

## Testing

> Document the testing strategy once established:
>
> - **Unit tests:** test individual functions/modules in isolation
> - **Integration tests:** test interactions between components
> - **End-to-end tests:** test full user flows

Run tests before committing:

```bash
# Replace with real command
<test command>
```

---

## Code Conventions

> Fill in as conventions are established. Common examples:

### General

- Prefer explicit over implicit.
- Keep functions small and single-purpose.
- Avoid premature abstraction — duplicate code twice before extracting.

### Naming

- Files: `kebab-case` or `snake_case` (pick one and be consistent)
- Variables/functions: `camelCase` (JS/TS) or `snake_case` (Python/Go/Rust)
- Constants: `UPPER_SNAKE_CASE`
- Types/Classes: `PascalCase`

### Error Handling

- Never silently swallow errors.
- Return errors to callers; only handle (log/alert) at boundaries.
- Use structured error types rather than raw strings where the language supports it.

---

## AI Assistant Guidelines

When working in this repository, Claude and other AI assistants should:

1. **Read before writing** — always read existing files before modifying them.
2. **Match existing style** — mirror the formatting, naming, and patterns already present.
3. **Minimal changes** — only modify what is directly required by the task; avoid opportunistic refactoring.
4. **No unnecessary files** — do not create documentation, README files, or helper utilities unless explicitly requested.
5. **No secrets** — never commit `.env` files, API keys, tokens, or passwords.
6. **Test after changes** — run the relevant test suite after any code modification and fix failures before marking a task complete.
7. **Descriptive commits** — write commit messages that explain *why*, not just *what*.
8. **Update this file** — when the project structure, stack, or conventions change materially, update the relevant section of this `CLAUDE.md`.

---

## Security Notes

- Keep all secrets out of version control; use environment variables or a secrets manager.
- Validate all external input at system boundaries (HTTP request bodies, file uploads, CLI arguments).
- Apply least-privilege principles to database users and service accounts.
- Dependency updates: review changelogs before bumping major versions.

---

*Last updated: 2026-02-20 — initial scaffold, repository contains no source code yet.*
