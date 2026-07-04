# oc-server

Stripped-down opencode HTTP server for the immune-system stack. Bun monorepo, Effect TS, SQLite, ~100MB Docker image.

## Commands

- **Install**: `bun install` (postinstall runs `fix-node-pty`)
- **Run**: `bun packages/server/src/server.ts`
- **Typecheck**: `tsgo --noEmit` (from `@typescript/native-preview`, not `tsc`)
- **Formatter**: Biome via `pre-commit` — no ESLint or prettier
- **Test (single pkg)**: `bun test --timeout 30000` (omit `--only-failures` for full run)
- **Test (all)**: `bun turbo typecheck` — no test task defined for the server package
- **Clean**: `scripts/clean.sh` (remove .turbo, dist, node_modules)
- **Version**: `scripts/get-version.sh` (reads `VERSION.txt`)
- **Bump**: `scripts/bump-version.sh -b=patch -c -t -p`
- **Docker**: `docker build -t oc-server .` (root `Dockerfile`, multi-stage, ~100MB)
- **Docker compose**: `docker compose up -d` (reads `.env`)

## Architecture

- **`packages/server/src/server.ts`** — entrypoint. `Bun.serve({ fetch: webHandler().handler })`
- **`packages/server/src/routes.ts`** — Effect `HttpApiBuilder` wiring all services via layer composition
- **`packages/core/`** — everything: DB, sessions, LLM orchestration, PTY, credentials, permissions, filesystem
- **`packages/llm/`** — LLM provider adapters. Uses Effect Schema-first model with four-axis routes (Protocol / Endpoint / Auth / Framing)
- **`packages/protocol/`** — HTTP API route definitions (includes health at `/api/health`)
- **`packages/schema/`** — shared Zod/Effect Schema contracts. Must stay browser-safe and dependency-light
- **`packages/http-recorder/`** — VCR-style HTTP cassette recording for LLM test fixtures

Key Effect framework packages: `effect`, `@effect/sql-sqlite-bun`, `@effect/platform-node`, `drizzle-orm`.

## Testing Quirks

- `bun test --only-failures` is the default script — it only runs previously failed tests. First run needs `bun test` without the flag or `--rerun-failures`.
- LLM tests use recorded cassettes. Set `RECORD=true` to re-record. Filters: `RECORDED_PROVIDER`, `RECORDED_PREFIX`, `RECORDED_TAGS`, `RECORDED_TEST`.
- Use `testEffect(...)` from `packages/llm/test/lib/effect.ts` for tests requiring Effect layers.
- `packages/core` has database migrations: `bun run db` runs `drizzle-kit`.

## Config & Environment

| Env Var | Default | Note |
|---|---|---|
| `PORT` | `3000` | Also `HOST` (default `0.0.0.0`) |
| `OPENCODE_DB` | `/data/opencode.db` | SQLite, created on first run |
| `OPENCODE_SERVER_USERNAME` | `opencode` | Basic auth |
| `OPENCODE_SERVER_PASSWORD` | `opencode` | Change for production |
| LLM keys (at least one) | — | `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `GOOGLE_API_KEY`, etc. |

## Docker Hub

Image: `redteamsubnet61/oc-server` (private). CI pushes on tag (`v*.*.*-*`). Multi-arch: `linux/amd64,linux/arm64`.

## Immune System Integration

Used as the `agent-server` service. Port **4096**, sessions scoped via `?directory=/workspaces/<challenge_id>`.

Key endpoints: `POST /session`, `POST /session/{id}/prompt_async`, `GET /session`, `GET /event`, `GET /api/health`.

## Release Pipeline

1. Manual trigger: `1. Bump Version` (patch/minor/major) — commits VERSION.txt + package.json, tags, pushes
2. Auto on tag: `2. Build and Publish` — Docker buildx + push to Docker Hub, then triggers release
3. Manual: `3. Create Release` — `gh release create` with auto-notes
4. Auto after release: `4. Update Changelog` — pulls release body into CHANGELOG.md + docs/release-notes.md

Branch `main` is default. Pre-commit hooks block commits to `main`/`master`.

## Patches

10 patches in `patches/` for `patchedDependencies` — do not remove.

## Package-Level AGENTS.md Files

For per-package deeper guidance, see:
- `packages/schema/AGENTS.md` — contract conventions, naming, schema patterns
- `packages/llm/AGENTS.md` — Effect LLM architecture, route design, test recording
- `packages/effect-drizzle-sqlite/AGENTS.md` — Drizzle + Effect adapter conventions
- `packages/core/src/tool/AGENTS.md` — tool runtime conventions
