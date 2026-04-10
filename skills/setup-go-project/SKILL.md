---
name: setup-go-project
description: Bootstrap a new Go project with selected modules (config, cli, tui, metrics, tracing, http, logger, cache, ORM, tests, frontend) using parallel agents
argument-hint: <project-name>
---

# Go Project Bootstrap

Scaffold a production-ready Go project with selected modules. Each module is set up by a dedicated agent running in parallel.

## Principles

Follow these throughout the entire scaffolding process:

1. **KISS** - Keep It Simple, Stupid. No premature abstractions. No wrapper layers unless they add real value. Prefer stdlib when it's good enough.
2. **Google Go Style Guide** - Follow https://google.github.io/styleguide/go/ for naming, package design, error handling, and documentation.
3. **Uber Go Style Guide** - Follow https://github.com/uber-go/guide/blob/master/style.md for performance patterns, nil handling, goroutine safety, and functional options.
4. **Flat is better than nested** - Avoid deep package hierarchies. A package should do one thing.
5. **Accept interfaces, return structs** - Keep coupling low.
6. **Errors are values** - Use `fmt.Errorf` with `%w` for wrapping. Define sentinel errors at package level when callers need to check them.
7. **No globals** - Pass dependencies explicitly. Use constructors.

---

## Workflow

When invoked with `$ARGUMENTS`:

### Step 1: Parse Arguments

- **project-name**: The first argument (required). This becomes the Go module name and directory.
- If no arguments provided, ask the user for a project name.

### Step 2: Present Module Menu

Present the module catalog below and ask the user which modules to include. The user can:
- Select categories by number or name
- For categories with multiple library options, ask which one they prefer
- Type `all` to include everything with defaults (first listed library)
- Type a comma-separated list like `config,cli,logger,http`

### Step 3: Scaffold with Agents

After the user confirms their selections:

1. **First** (sequential): Create the project directory, `go.mod`, `.gitignore`, `Taskfile.yaml`, `Dockerfile`, `compose.yaml` - this must complete before agents run.
2. **Then** (parallel agents): Spawn one agent per selected module. Each agent:
   - Creates the module's package under `internal/`
   - Writes the boilerplate code with the selected library
   - Adds necessary imports
3. **Then** (sequential): Run `go mod tidy` and verify the project compiles with `go build ./...`.
4. **Finally**: Print a summary of what was created.

---

## Module Catalog

### 1. Config (environment & files)

Load configuration from environment variables and YAML config files.

| Library | Import | Use for |
|---------|--------|---------|
| **caarlos0/env** | `github.com/caarlos0/env/v11` | Environment variables - parse into struct with tags |
| **spf13/viper** | `github.com/spf13/viper` | YAML/TOML/JSON config files - when file-based config is needed |

Both are included together: env for env vars, viper for config files.

**Important**: Use nested config structs with `envPrefix` tags to group related env vars. Each module's config lives in its own sub-struct. Example:
```go
type Config struct {
	App    AppConfig    `envPrefix:"APP_"`
	Sentry SentryConfig `envPrefix:"SENTRY_"`
	DB     DBConfig     `envPrefix:"DB_"`
	Redis  RedisConfig  `envPrefix:"REDIS_"`
}

type SentryConfig struct {
	URL string `env:"URL"` // reads SENTRY_URL
	DSN string `env:"DSN"` // reads SENTRY_DSN
}

type DBConfig struct {
	Host string `env:"HOST" envDefault:"localhost"`
	Port int    `env:"PORT" envDefault:"5432"`
	Name string `env:"NAME,required"`
}
```
This keeps config organized and makes it clear which env var belongs to which subsystem.

### 2. CLI

Build command-line interfaces with subcommands and flags.

| Library | Import | When to use |
|---------|--------|-------------|
| **spf13/cobra** (default) | `github.com/spf13/cobra` | Feature-rich CLIs with subcommands, flags, completions |
| **urfave/cli** | `github.com/urfave/cli/v3` | Simpler API, less boilerplate, lighter weight |

Ask the user which one they prefer at project creation time.

### 3. TUI & CLI UI (Charmbracelet)

Rich terminal user interfaces and beautiful CLI output. Uses the full Charmbracelet stack.

| Library | Import | Use for |
|---------|--------|---------|
| **bubbletea** | `github.com/charmbracelet/bubbletea` | TUI framework - Elm-architecture (Model/Update/View) |
| **lipgloss** | `github.com/charmbracelet/lipgloss` | Terminal styling - colors, borders, padding, alignment |
| **bubbles** | `github.com/charmbracelet/bubbles` | Ready-made components - spinner, text input, list, table, progress bar |
| **huh** | `github.com/charmbracelet/huh` | Interactive forms and prompts |

All four are included together when this module is selected.

### 4. Metrics

Expose application metrics for monitoring.

| Library | Import | When to use |
|---------|--------|-------------|
| **prometheus/client_golang** (default) | `github.com/prometheus/client_golang` | Prometheus/Grafana stack |
| **OpenTelemetry metrics** | `go.opentelemetry.io/otel/metric` | Vendor-neutral, pairs with OTel tracing |

Ask the user which one they prefer at project creation time.

### 5. Error Tracking

Report and track errors in production.

| Library | Import |
|---------|--------|
| **getsentry/sentry-go** | `github.com/getsentry/sentry-go` |

No alternatives - Sentry is the standard.

### 6. Tracing

Distributed tracing for request flows across services.

| Library | Import |
|---------|--------|
| **OpenTelemetry** | `go.opentelemetry.io/otel` |

No alternatives - OTel is the vendor-neutral standard.

### 7. HTTP Router

Handle HTTP requests with routing, middleware, and parameter parsing.

| Library | Import |
|---------|--------|
| **gin-gonic/gin** | `github.com/gin-gonic/gin` |

No alternatives - Gin is the chosen router.

### 8. HTTP Client

Make outbound HTTP requests to external services and APIs.

| Library | Import | When to use |
|---------|--------|-------------|
| **go-resty/resty** (default) | `github.com/go-resty/resty/v2` | Feature-rich REST client with retries, middleware, auth |
| **hashicorp/go-retryablehttp** | `github.com/hashicorp/go-retryablehttp` | Simple retryable HTTP, wraps stdlib, Hashicorp ecosystem |
| **stdlib net/http** | (built-in) | No dependencies, full control, enough for simple calls |

Ask the user which one they prefer at project creation time.

### 9. Logger

Structured logging for application events.

| Library | Import | When to use |
|---------|--------|-------------|
| **uber-go/zap** (default) | `go.uber.org/zap` | Services - structured, fast, widely adopted, JSON output |
| **rs/zerolog** | `github.com/rs/zerolog` | Services - zero-allocation JSON logger, simpler API |
| **charmbracelet/log** | `github.com/charmbracelet/log` | CLIs & TUIs - human-readable, colorful, no timestamps, no JSON |

Ask the user which one they prefer at project creation time.
**Important**: If the project is a CLI/TUI tool (cli or tui module selected), recommend **charmbracelet/log** as the default. For services (http, metrics, tracing selected), recommend **zap** or **zerolog**.

### 10. Frontend

Server-side rendered HTML with type safety.

| Library | Import |
|---------|--------|
| **a-h/templ** | `github.com/a-h/templ` |

No alternatives - templ is the chosen frontend library.

### 11. Cache

Caching layer - supports both external (Redis) and in-memory caching.

| Library | Import | Use for |
|---------|--------|---------|
| **redis/go-redis** | `github.com/redis/go-redis/v9` | External distributed cache (Redis) |
| **dgraph-io/ristretto** | `github.com/dgraph-io/ristretto/v2` | In-memory cache (local, no external dependency) |

Both are included together: go-redis for distributed cache, ristretto for local in-memory cache.

### 12. ORM / Database

Database access and query building.

| Library | Import | When to use |
|---------|--------|-------------|
| **go-gorm/gorm** (default) | `gorm.io/gorm` | Full ORM with migrations, hooks, associations |
| **uptrace/bun** | `github.com/uptrace/bun` | Lightweight, SQL-first with struct mapping, good for Postgres |

Ask the user which one they prefer at project creation time.

### 13. Tests

Testing utilities and assertion libraries.

| Library | Import | When to use |
|---------|--------|-------------|
| **stretchr/testify** (default) | `github.com/stretchr/testify` | Assertions (`assert`, `require`), mocking, test suites |
| **matryer/is** | `github.com/matryer/is` | Minimal, one-function assertion library |
| **stdlib testing** | (built-in) | No dependencies, table-driven tests only |

Ask the user which one they prefer at project creation time.

---

## Project Structure

Generate this layout (only include directories for selected modules):

```
<project-name>/
├── cmd/
│   └── <app-name>/
│       └── main.go              # Wires everything together, starts the app
├── internal/
│   ├── config/
│   │   └── config.go            # [if config] Configuration struct + loaders
│   ├── handler/
│   │   ├── handler.go           # [if http] HTTP handlers
│   │   └── routes.go            # [if http] Route definitions
│   ├── middleware/
│   │   └── middleware.go         # [if http] HTTP middleware
│   ├── client/
│   │   └── client.go            # [if http-client] HTTP client wrapper
│   ├── model/
│   │   └── model.go             # [if orm] Domain / DB models
│   ├── repository/
│   │   └── repository.go        # [if orm] Data access layer
│   ├── cache/
│   │   └── cache.go             # [if cache] Cache abstraction (redis + ristretto)
│   ├── tui/
│   │   └── tui.go               # [if tui] Bubbletea model + views
│   ├── view/
│   │   ├── layout.templ         # [if frontend] Base HTML layout
│   │   └── index.templ          # [if frontend] Index page
│   └── telemetry/
│       ├── logger.go            # [if logger] Logger setup
│       ├── metrics.go           # [if metrics] Metrics setup
│       ├── tracing.go           # [if tracing] Tracing setup
│       └── sentry.go            # [if error-tracking] Sentry setup
├── migrations/                   # [if orm] SQL migrations directory
│   └── .keep
├── go.mod
├── Taskfile.yaml                 # Build, run, test, lint targets
├── Dockerfile                    # Multi-stage build with best practices
├── compose.yaml                  # Docker Compose for local dev
├── .gitignore
├── .env.example                  # [if config] Example environment variables
└── config.yaml                   # [if config+viper] Example YAML config
```

### Key structure rules:
- `cmd/` contains only the entry point. No business logic.
- `internal/` is the meat. Not importable by external packages.
- No `pkg/` unless there's code that genuinely needs to be shared with other Go modules.
- No `utils/` or `helpers/` packages. Put functions where they belong.
- No `models/` (plural) - use `model/` (singular, per Go convention).

---

## Agent Scaffolding Instructions

### Pre-flight (sequential, no agent needed)

```bash
mkdir -p <project-name>/cmd/<app-name>
cd <project-name>
go mod init <project-name>
```

Create `.gitignore`:
```
# Binaries
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test
*.test
*.out
coverage.html

# IDE
.idea/
.vscode/
*.swp
*.swo

# Environment
.env
*.local

# OS
.DS_Store
Thumbs.db

# Build
dist/
tmp/

# templ
*_templ.go
```

Create `Taskfile.yaml`:
```yaml
version: "3"

vars:
  APP_NAME: <app-name>
  BUILD_DIR: bin

tasks:
  build:
    desc: Build the application binary
    cmds:
      - go build -o {{.BUILD_DIR}}/{{.APP_NAME}} ./cmd/{{.APP_NAME}}
    sources:
      - ./**/*.go
    generates:
      - "{{.BUILD_DIR}}/{{.APP_NAME}}"

  run:
    desc: Build and run the application
    deps: [build]
    cmds:
      - ./{{.BUILD_DIR}}/{{.APP_NAME}}

  test:
    desc: Run all tests with race detection and coverage
    cmds:
      - go test ./... -race -cover

  lint:
    desc: Run golangci-lint
    cmds:
      - golangci-lint run

  clean:
    desc: Remove build artifacts
    cmds:
      - rm -rf {{.BUILD_DIR}}

  # Add module-specific tasks below based on selected modules:
  # [if frontend/templ]
  # templ:
  #   desc: Generate templ templates
  #   cmds:
  #     - templ generate

  # [if orm/gorm]
  # migrate:
  #   desc: Run database migrations
  #   cmds:
  #     - go run ./cmd/migrate
```

Create `Dockerfile`:
```dockerfile
# syntax=docker/dockerfile:1

# --- Build stage ---
FROM golang:1.24-alpine AS builder

# Install ca-certificates and tzdata for the final image
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Cache dependency downloads
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -o /app/bin/server \
    ./cmd/<app-name>

# --- Final stage ---
FROM scratch

# Import ca-certificates and timezone data from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy the binary
COPY --from=builder /app/bin/server /server

# Run as non-root (numeric UID for scratch image)
USER 65534:65534

EXPOSE 8080

ENTRYPOINT ["/server"]
```

Create `compose.yaml`:
```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    env_file:
      - .env
    depends_on:
      # Uncomment services as needed based on selected modules:
      # [if orm] postgres:
      # [if orm]   condition: service_healthy
      # [if cache/redis] redis:
      # [if cache/redis]   condition: service_healthy

  # [if orm] Uncomment for database:
  # postgres:
  #   image: postgres:17-alpine
  #   environment:
  #     POSTGRES_USER: app
  #     POSTGRES_PASSWORD: app
  #     POSTGRES_DB: app
  #   ports:
  #     - "5432:5432"
  #   volumes:
  #     - pgdata:/var/lib/postgresql/data
  #   healthcheck:
  #     test: ["CMD-SHELL", "pg_isready -U app"]
  #     interval: 5s
  #     timeout: 5s
  #     retries: 5

  # [if cache/redis] Uncomment for Redis:
  # redis:
  #   image: redis:7-alpine
  #   ports:
  #     - "6379:6379"
  #   healthcheck:
  #     test: ["CMD", "redis-cli", "ping"]
  #     interval: 5s
  #     timeout: 5s
  #     retries: 5

# [if orm] Uncomment for persistent volumes:
# volumes:
#   pgdata:
```

**Important**: After all agents complete, uncomment the relevant services in `compose.yaml` based on which modules were selected (postgres for ORM, redis for cache, etc.). Remove the comment markers and `[if ...]` annotations.

---

### Agent: Config Module

**Spawn when**: User selected "config"

Create `internal/config/config.go` with:
- Nested config structs using `envPrefix` tags (see pattern in Module Catalog above)
- A top-level `Config` struct with sub-structs for each selected module (e.g. `App AppConfig`, `Sentry SentryConfig`, `DB DBConfig`, `Redis RedisConfig`)
- A `Load()` function that calls `env.Parse()` for env vars and `viper.ReadInConfig()` for optional YAML file config
- Viper should treat config file as optional (don't error on `ConfigFileNotFoundError`)

Create `.env.example` showing all env vars with their defaults.
Create `config.yaml` as an empty example YAML config file.

---

### Agent: CLI Module

**Spawn when**: User selected "cli"

Ask the user: **cobra** or **urfave/cli**?

Create `cmd/<app-name>/main.go` with the chosen library. Include a root command and a `serve` subcommand (if http module selected) or a sensible default command. If CLI is NOT selected, create a simple `main.go` that boots the app directly without subcommands.

---

### Agent: TUI & CLI UI Module (Charmbracelet)

**Spawn when**: User selected "tui"

Create `internal/tui/tui.go` with a basic Bubbletea application scaffold using the Elm-architecture pattern (Model/Init/Update/View). Use lipgloss for styling. Include a `Run()` function that creates a `tea.NewProgram` and runs it.

Create `internal/tui/form.go` with a basic huh form example demonstrating an interactive input prompt.

Wire `tui.Run()` into `main.go` or CLI command.

---

### Agent: Logger Module

**Spawn when**: User selected "logger"

Ask the user: **zap**, **zerolog**, or **charmbracelet/log**?

**Important**: If the project uses cli or tui modules, recommend **charmbracelet/log** as default. For services (http, metrics, tracing), recommend **zap** or **zerolog**.

Create `internal/telemetry/logger.go` with a `SetupLogger(level string)` function.

For **charmbracelet/log** specifically: configure with `ReportTimestamp: false` - human-readable colorful output, no timestamps, no JSON. Output to stderr. This is the CLI/TUI logger.

For **zap** / **zerolog**: standard structured JSON logger to stdout with configurable level.

---

### Agent: HTTP Router Module (Gin)

**Spawn when**: User selected "http"

Create `internal/handler/handler.go` with a `Handler` struct (dependency injection via fields), a `New()` constructor, and a `HealthCheck` handler.

Create `internal/handler/routes.go` with a `Routes(r *gin.Engine)` method that registers routes including `/health`.

If **metrics** is also selected, add metrics middleware and `/metrics` endpoint.
If **tracing** is also selected, add `otelgin` middleware.
If **error-tracking** is also selected, add `sentrygin` middleware.

---

### Agent: HTTP Client Module

**Spawn when**: User selected "http-client"

Ask the user: **resty**, **go-retryablehttp**, or **stdlib**?

Create `internal/client/client.go` with a `Client` struct wrapping the chosen HTTP library. Include sensible defaults: 10s timeout, 3 retries, exponential backoff. Provide a `New()` constructor.

---

### Agent: Metrics Module

**Spawn when**: User selected "metrics"

Ask the user: **prometheus** or **OpenTelemetry metrics**?

Create `internal/telemetry/metrics.go`. For prometheus: expose a `MetricsHandler()` and register standard HTTP metrics (requests total, duration histogram). For OTel: set up meter provider with OTLP exporter.

If HTTP (Gin) is also selected, add Gin-compatible metrics middleware and wire `/metrics` as a route.

---

### Agent: Error Tracking Module (Sentry)

**Spawn when**: User selected "error-tracking"

Create `internal/telemetry/sentry.go` with a `SetupSentry(dsn, environment string) error` function. Skip initialization gracefully if DSN is empty. Add `defer sentry.Flush(2 * time.Second)` in main.

If HTTP (Gin) is also selected, add `sentrygin` middleware.

---

### Agent: Tracing Module (OpenTelemetry)

**Spawn when**: User selected "tracing"

Create `internal/telemetry/tracing.go` with a `SetupTracing(ctx, serviceName) (*sdktrace.TracerProvider, error)` function. Use OTLP HTTP exporter, set service name via semconv resource attributes.

If HTTP (Gin) is also selected, add `otelgin` middleware.

---

### Agent: Cache Module

**Spawn when**: User selected "cache"

Create `internal/cache/cache.go` with two types:
- `Redis` struct wrapping `redis.Client` with `NewRedis(addr)`, `Get`, `Set`, `Close` methods
- `Memory` struct wrapping `ristretto.Cache` with `NewMemory()`, `Get`, `Set`, `Close` methods

Both use constructors that validate connectivity (redis ping) or configuration (ristretto).

---

### Agent: ORM / Database Module

**Spawn when**: User selected "orm"

Ask the user: **gorm** or **bun**?

Create `internal/repository/db.go` with a `NewDB(dsn string)` function that opens a Postgres connection using the chosen library.

Create `internal/model/model.go` with an example model struct using the library's conventions (gorm.Model embedding or bun.BaseModel).

Create `internal/repository/example.go` with a basic repository struct that takes the DB as dependency.

Create `migrations/` directory with `.keep`.

---

### Agent: Frontend Module (templ)

**Spawn when**: User selected "frontend"

Create `internal/view/layout.templ` with a base HTML layout (doctype, head, body, children slot).
Create `internal/view/index.templ` with a simple index page using the layout.
Add `templ generate` task to Taskfile.yaml.

If HTTP (Gin) is also selected, add a handler that renders the templ component via `component.Render(c.Request.Context(), c.Writer)`.

---

### Agent: Tests Module

**Spawn when**: User selected "tests"

Ask the user: **testify**, **matryer/is**, or **stdlib**?

Create an example `_test.go` file next to the first existing package (prefer config if it exists). The test should demonstrate the chosen library's assertion style and actually test something from the generated code. If stdlib, use table-driven tests.

---

## Post-scaffold (sequential)

After all agents complete:

1. Uncomment relevant services in `compose.yaml` based on selected modules.
2. Uncomment module-specific tasks in `Taskfile.yaml`.
3. Remove all `[if ...]` annotation comments from generated files.
4. Run:

```bash
cd <project-name>
go mod tidy
go build ./...
```

If build fails, diagnose and fix. Then print:

```
Project <project-name> created with modules: [list]

Next steps:
  cd <project-name>
  # Copy .env.example to .env and fill in values
  cp .env.example .env
  task run
```
