# Development Guide

This project follows the **Hyperpolymath Standard** for language and tooling choices.

## Architecture Overview

```
candy-crash/
├── backend/           # Gleam backend (API server)
│   ├── src/           # Gleam source files
│   │   ├── candy_crash.gleam    # Main entry point
│   │   ├── arango/              # ArangoDB client
│   │   ├── handlers/            # HTTP request handlers
│   │   ├── middleware/          # Auth, CORS middleware
│   │   ├── models/              # Data models
│   │   └── services/            # Business logic
│   ├── test/          # Tests
│   └── gleam.toml     # Gleam project config
├── frontend/          # ReScript frontend (SPA)
│   ├── src/           # ReScript source files
│   │   ├── Main.res             # App entry point (TEA architecture)
│   │   ├── components/          # UI components
│   │   ├── pages/               # Page views
│   │   ├── Api.res              # API client
│   │   └── Router.res           # Client-side routing
│   ├── rescript.json  # ReScript config
│   └── deno.json      # Deno runtime config
├── scripts/           # Development scripts
└── .github/           # CI/CD workflows
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Backend | **Gleam** | Type-safe functional backend |
| Web Framework | **Wisp** | HTTP handlers & middleware |
| Database | **ArangoDB** | Multi-model document/graph DB |
| Frontend | **ReScript** | Type-safe UI development |
| Architecture | **rescript-tea** | The Elm Architecture for ReScript |
| Routing | **cadre-router** | Type-safe URL routing |
| Runtime | **Deno** | JavaScript/TypeScript runtime |

## Prerequisites

- **Erlang/OTP 26+** - For Gleam runtime (BEAM)
- **Gleam 1.6+** - Backend language
- **Deno 1.40+** - Frontend runtime
- **ArangoDB 3.11+** - Database
- **ReScript 11+** - Frontend compiler (via Deno)

## Getting Started

### 1. Install Dependencies

```bash
# Install Gleam (macOS)
brew install gleam

# Install Gleam (Linux)
curl -fsSL https://gleam.run/install.sh | sh

# Install Deno
curl -fsSL https://deno.land/install.sh | sh

# Start ArangoDB (Docker)
docker run -d --name arangodb \
  -p 8529:8529 \
  -e ARANGO_ROOT_PASSWORD=password \
  arangodb/arangodb:3.11
```

### 2. Setup Backend

```bash
cd backend

# Download dependencies
gleam deps download

# Build
gleam build

# Run tests
gleam test

# Start development server
ARANGO_URL=http://localhost:8529 \
ARANGO_DATABASE=candy_crash \
ARANGO_USER=root \
ARANGO_PASSWORD=password \
SECRET_KEY_BASE=$(openssl rand -hex 32) \
gleam run
```

### 3. Setup Frontend

```bash
cd frontend

# Build ReScript
deno run -A npm:rescript build -with-deps

# Start development server
deno task dev
```

## Environment Variables

### Backend

| Variable | Description | Required |
|----------|-------------|----------|
| `ARANGO_URL` | ArangoDB connection URL | Yes |
| `ARANGO_DATABASE` | Database name | Yes |
| `ARANGO_USER` | Database username | Yes |
| `ARANGO_PASSWORD` | Database password | Yes |
| `SECRET_KEY_BASE` | JWT signing secret (32+ bytes) | Yes |
| `PORT` | Server port (default: 4000) | No |

### Frontend

| Variable | Description | Required |
|----------|-------------|----------|
| `API_URL` | Backend API URL | No (default: http://localhost:4000/api) |

## Language Policy

This project follows the **Hyperpolymath Standard**. See `.claude/CLAUDE.md` for details.

### Allowed Languages

- **Gleam** - Backend services
- **ReScript** - Frontend UI
- **Rust** - Performance-critical, WASM
- **Bash** - Scripts, automation

### Banned Languages

- TypeScript → Use ReScript
- Node.js → Use Deno
- Ruby/Rails → Use Gleam
- Go → Use Rust
- Python (general) → Use ReScript/Rust

### Enforcement

- Pre-commit hooks block banned languages
- CI/CD workflows verify compliance
- Run `./scripts/check-languages.sh` to verify locally

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/logout` | Logout |
| GET | `/api/auth/me` | Current user |

### Courses

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/courses` | List courses |
| GET | `/api/courses/:id` | Course detail |
| GET | `/api/categories` | List categories |

### Enrollments (Authenticated)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/enrollments` | User's enrollments |
| POST | `/api/enrollments/enroll/:course_id` | Enroll in course |

### Lessons (Authenticated)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/courses/:id/lessons` | Course lessons |
| GET | `/api/courses/:id/lessons/:lesson_id` | Lesson detail |
| POST | `/api/courses/:id/lessons/:lesson_id/complete` | Mark complete |

### Quizzes (Authenticated)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/courses/:id/quizzes` | Course quizzes |
| POST | `/api/quizzes/:id/attempts/new` | Start attempt |
| POST | `/api/attempts/:id/submit` | Submit answer |
| POST | `/api/attempts/:id/complete` | Complete quiz |

## Testing

### Backend

```bash
cd backend
gleam test
```

### Frontend

```bash
cd frontend
deno test
```

## Contributing

1. Follow the language policy
2. Add SPDX license headers to all files
3. Run `./scripts/check-languages.sh` before committing
4. Ensure CI passes before merging

## License

MIT License - See LICENSE.txt
