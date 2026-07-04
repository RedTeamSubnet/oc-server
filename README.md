# oc-server

Stripped-down [opencode](https://opencode.ai) HTTP server — no UI, no CLI, no desktop. Runs the agent backend as a standalone service.

## Quick Start

```bash
echo "OPENCODE_SERVER_PASSWORD=changeme" > .env
docker compose up -d
```

Health: `curl http://localhost:3000/api/health`

## Configuration

| Env Var | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP listen port |
| `HOST` | `0.0.0.0` | HTTP listen address |
| `OPENCODE_SERVER_USERNAME` | `opencode` | Basic auth username |
| `OPENCODE_SERVER_PASSWORD` | `opencode` | Basic auth password |
| `OPENCODE_DB` | `/data/opencode.db` | SQLite database path |

LLM provider keys (at least one required): `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_API_KEY`, or any provider supported by opencode.

All vars can be set via `.env` file or passed directly to the container.

## API

Full API is defined by the protocol package — key endpoints used by the immune system:

### Sessions

```http
POST /session?directory=/workspaces/<challenge_id>
Content-Type: application/json
Authorization: Basic base64(username:password)

{"title": "<run_id>", "agent": "redteam"}
```

Response:
```json
{"id": "<session_id>", "title": "<run_id>", "agent": "redteam"}
```

### Send Prompt

```http
POST /session/<session_id>/prompt_async
Content-Type: application/json
Authorization: Basic base64(username:password)

{"agent": "redteam", "parts": [{"type": "text", "text": "..."}]}
```

### List Sessions

```http
GET /session
Authorization: Basic base64(username:password)
```

### Stream Events

```http
GET /event
Authorization: Basic base64(username:password)
```

## Docker

```bash
# Build
docker build -t oc-server .

# Run with defaults
docker run -p 3000:3000 oc-server

# Run with auth and LLM keys
docker run -p 3000:3000 \
  -e OPENCODE_SERVER_PASSWORD=secret \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -v oc-data:/data \
  oc-server
```

## Immune System Integration

When used as part of the [immune-system](https://github.com/RedTeamSubnet/immune-system) stack, this service:

- Runs as the `agent-server` compose service on port **4096**
- Resolvable at `http://agent-server:4096` internally
- Sessions are scoped to challenge workspaces via `?directory=/workspaces/<challenge_id>`
- Consumed by the **backend** (FastAPI, `/api/opencode/*` proxy), **redteam MCP**, and **blueteam MCP**

```yaml
# compose.yml snippet
services:
  agent-server:
    image: oc-server:latest
    ports:
      - "4096:4096"
    environment:
      PORT: 4096
      OPENCODE_SERVER_PASSWORD: ${OPENCODE_SERVER_PASSWORD}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      OPENCODE_DB: /data/opencode.db
    volumes:
      - oc-data:/data
      - workspace-data:/workspaces
```

## Build

Multi-stage, ~100MB final image. Uses `turbo prune` to include only server dependencies.

```bash
docker build -t oc-server .
```

## Project Structure

```
├── Dockerfile
├── compose.yml
├── packages/
│   ├── server/       # Entrypoint (server.ts → routes.ts)
│   ├── core/         # Database, LLM orchestration, filesystem, PTY
│   ├── protocol/     # HTTP API contracts and route definitions
│   ├── schema/       # Shared Zod schemas
│   ├── sdk/          # TypeScript client SDK
│   ├── llm/          # LLM provider adapters
│   ├── plugin/       # Plugin system
│   ├── http-recorder/ # HTTP request recording
│   ├── effect-drizzle-sqlite/
│   └── effect-sqlite-node/
├── packages/effect-drizzle-sqlite/
├── packages/effect-sqlite-node/
├── scripts/          # bump-version, changelog, clean, release
├── VERSION.txt
└── patches/          # Dependency patches (bun patchedDependencies)
```
