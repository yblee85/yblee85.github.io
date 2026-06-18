# Architecture

Portfolio site at [https://yunbo-lee.me/](https://yunbo-lee.me/) with a static Next.js frontend and a Ruby API backend that powers a RAG-based chat agent.

## System overview

The app is split into two deployable parts:

| Part | Stack | Hosting |
|------|-------|---------|
| **Frontend** | Next.js (static export) | GitHub Pages |
| **Backend** | Ruby + Sinatra (Rack/Puma) | DigitalOcean App Platform |

The frontend serves portfolio pages (home, career, personal) and a protected **Chat with my agent** feature. The backend handles OAuth sessions, rate limiting, retrieval-augmented generation (RAG), and admin operations.

```mermaid
flowchart TB
  subgraph Browser["Browser"]
    FE["Next.js static site<br/>(GitHub Pages)"]
  end

  subgraph DO["DigitalOcean App Platform"]
    API["Portfolio API<br/>Sinatra + Puma"]
    IDX["In-memory vector index"]
    CHAT["Chat history cache<br/>(LocalStore, TTL 1h)"]
    API --> IDX
    API --> CHAT
  end

  subgraph External["External services"]
    AUTH0["Auth0<br/>(OAuth2 IdP)"]
    GH_DATA["Private GitHub repo<br/>(portfolio JSON data)"]
    EMB["Embeddings<br/>Voyage API or local TEI"]
    CLAUDE["Anthropic Claude API"]
    SLACK["Slack<br/>(optional notifications)"]
    IDP["Google / GitHub / LinkedIn<br/>(via Auth0 connections)"]
  end

  FE -->|"GET pages, static assets"| FE
  FE -->|"credentials: include<br/>/auth/*, /api/*"| API
  API --> AUTH0
  AUTH0 --> IDP
  API -->|"startup + admin reindex"| GH_DATA
  API --> EMB
  API --> CLAUDE
  API -.-> SLACK
```

## Frontend

The frontend lives in `frontend/` and uses the Next.js App Router with **`output: "export"`** so it builds to static HTML/JS in `frontend/out/`.

### Pages

| Route | Purpose |
|-------|---------|
| `/` | Home |
| `/career/` | Work history |
| `/personal/` | Personal background |
| `/chat/` | Protected chat UI (`ProtectedAuthContent`) |
| `/admin/` | Admin-only reindex trigger (`AdminContent`) |

### Key components

- **`AuthProvider`** — On load, calls `GET /auth/me` on the backend (with cookies) to determine session state and obtain a CSRF token.
- **`ProtectedAuthContent`** — Login buttons redirect to backend OAuth routes; chat messages are sent to `POST /api/chat`.
- **`Nav`** — Site navigation; reflects auth state via `localStorage` flag.

The API origin is configured at build time via `NEXT_PUBLIC_API_URL`.

```mermaid
flowchart LR
  subgraph Frontend["frontend/"]
    LAYOUT["app/layout.tsx<br/>AuthProvider + Nav"]
    PAGES["app/*/page.tsx<br/>static pages"]
    CHAT["components/ProtectedAuthContent.tsx"]
    ADMIN["components/AdminContent.tsx"]
    API_LIB["lib/api.ts<br/>getApiBaseUrl()"]
  end

  LAYOUT --> PAGES
  LAYOUT --> CHAT
  LAYOUT --> ADMIN
  CHAT --> API_LIB
  ADMIN --> API_LIB
  AUTH["AuthProvider"] --> API_LIB
```

## Backend

The backend lives in `backend/` and is a Rack application (`config.ru` → `PortfolioApi`).

### Request pipeline

Incoming requests pass through middleware before reaching route handlers:

```mermaid
flowchart TD
  REQ["HTTP request"] --> CORS["Rack::Cors"]
  CORS --> ERR["JsonApiErrorHandler"]
  ERR --> SESS["Rack::Session::Pool"]
  SESS --> AUTH["ApiAuth<br/>(/api/* requires session)"]
  AUTH --> CSRF["CsrfProtection<br/>(POST /api/*)"]
  CSRF --> RL["RateLimiter<br/>(POST /api/chat)"]
  RL --> ROUTES["Route handlers"]

  subgraph Routes["Route modules"]
    HOME["HomeRoute<br/>GET /, /health"]
    AUTH_R["AuthRoute<br/>/auth/*"]
    CHAT_R["ChatRoute<br/>POST /api/chat"]
    ADMIN_R["AdminRoute<br/>POST /api/admin/reindex_db"]
  end

  ROUTES --> Routes
```

### API endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/` | — | API root |
| `GET` | `/health` | — | Health check |
| `GET` | `/auth/login` | — | Start OAuth or guest login |
| `GET` | `/auth/auth0/callback` | — | Auth0 OAuth callback |
| `GET` | `/auth/logout` | session | Clear session / Auth0 logout |
| `GET` | `/auth/me` | session | Current user + CSRF token |
| `POST` | `/api/chat` | session + CSRF | Ask the portfolio agent |
| `POST` | `/api/admin/reindex_db` | admin session + CSRF | Sync data + rebuild index |

CORS allows the frontend origin with `credentials: true` so session cookies work cross-origin.

### Dependency container

At boot, `App::PortfolioContainer.build` wires the RAG stack:

```mermaid
flowchart LR
  CONTAINER["PortfolioContainer"] --> QA["Rag::QaService"]
  QA --> INDEX["Vector::InMemoryIndex"]
  QA --> LLM["Llm::AnthropicClient"]
  QA --> ROOM["Chat::Chatroom"]

  INDEX --> LOADER["PortfolioData::DocumentLoader"]
  INDEX --> EMB["Embeddings::Client<br/>tei | voyage"]
  LOADER --> JSON["JSON files in<br/>ABOUTME_DATA_DIR_PATH"]
  ROOM --> CACHE["Cache::LocalStore"]
```

## RAG pipeline

Portfolio knowledge is stored as JSON documents (work history, personal info, etc.). At startup the backend loads, chunks, embeds, and indexes them in memory — no external vector database.

```mermaid
sequenceDiagram
  participant U as User
  participant FE as Frontend
  participant API as Backend
  participant IDX as InMemoryIndex
  participant EMB as Embeddings provider
  participant LLM as Claude API
  participant CR as Chatroom

  Note over API,IDX: Startup (entrypoint.sh)
  API->>API: sync_portfolio_data.sh (optional GitHub clone)
  API->>IDX: build!
  IDX->>IDX: DocumentLoader.load_all → chunk JSON
  IDX->>EMB: embed each chunk
  EMB-->>IDX: vectors stored in memory

  Note over U,CR: Chat request
  U->>FE: Send message
  FE->>API: POST /api/chat { message } + session cookie + X-CSRF-Token
  API->>CR: get_messages(user_id)
  API->>IDX: search(query, top-k, min_score)
  IDX->>EMB: embed query
  IDX-->>API: top-k chunks + scores
  API->>LLM: summarize(contexts + question + history)
  LLM-->>API: Markdown answer
  API->>CR: add_question_and_answer
  API-->>FE: { answer, sources }
  FE-->>U: Render Markdown response
```

### Document loading

1. Read all `*.json` files under `ABOUTME_DATA_DIR_PATH`.
2. Each file has a `collection_name` and `documents` array.
3. Document `contents` strings are joined and split into overlapping character chunks (`RAG_CHUNK_SIZE_CHARS`, `RAG_CHUNK_OVERLAP_PERCENT`).
4. Metadata (organization, category, period, tags) is included in the embedding text to improve retrieval.

### Retrieval + synthesis

1. Embed the user question (`input_type: "query"`).
2. Rank chunks by cosine similarity; filter by `RAG_MIN_SCORE`; take top `RAG_K`.
3. Pass retrieved snippets + conversation history to Claude with a detailed system prompt (grounding rules, STAR format, Markdown output).
4. Return the answer and source metadata.

Search events are published on the internal event bus for optional Slack analytics.

## Authentication

Auth uses **server-side sessions** (Rack session cookie) with **Auth0** as the OAuth2 broker. Social logins (Google, GitHub, LinkedIn) are Auth0 connections. A **guest** login path assigns an anonymous user ID derived from client IP for local/demo use.

```mermaid
sequenceDiagram
  participant U as User
  participant FE as Frontend (GitHub Pages)
  participant API as Backend
  participant A0 as Auth0
  participant IDP as Google / GitHub / LinkedIn

  U->>FE: Click "Continue with Google"
  FE->>API: GET /auth/login?connection=google-oauth2&return_to=...
  API->>A0: Redirect to Auth0
  A0->>IDP: OAuth consent
  IDP-->>A0: Tokens
  A0-->>API: GET /auth/auth0/callback
  API->>API: session[:user] = user payload<br/>issue CSRF token
  API-->>FE: Redirect to return_to (chat page)
  FE->>API: GET /auth/me (credentials: include)
  API-->>FE: { user, csrf_token }
  FE->>API: POST /api/chat + X-CSRF-Token
```

Protected API routes require:

1. Valid session with `user_id`.
2. CSRF token (from `/auth/me`) on mutating requests.
3. Rate limit headroom (for `/api/chat`).

Admin routes additionally require the `admin` role in the session user payload.

## Data sync

Portfolio JSON is kept in a **separate private GitHub repository**. On container startup (`entrypoint.sh`), `script/sync_portfolio_data.sh` clones that repo using a GitHub personal access token and copies `data/` into `ABOUTME_DATA_DIR_PATH`.

For local development, bundled example data lives in `backend/external_example/data/`.

Admins can trigger a live reindex from the `/admin/` page, which calls `POST /api/admin/reindex_db`:

1. Re-run the GitHub data sync.
2. Rebuild the in-memory vector index (`qa.reindex_db`).

## Embeddings providers

| Provider | Config | Use case |
|----------|--------|----------|
| **tei** | `EMBEDDING_PROVIDER=tei`, local HuggingFace TEI container | Local dev via `docker-compose.yml` |
| **voyage** | `EMBEDDING_PROVIDER=voyage`, `VOYAGE_API_KEY` | Production (no local embeddings container) |

## Observability

An in-process **`Events::EventBus`** publishes domain events. When Slack is configured, `Notifier::SlackListener` sends messages for:

- `auth.login` — someone signed in
- `rag.search` — query + top retrieval results
- `llm.error` — Claude API failures

## Deployment & CI

```mermaid
flowchart LR
  subgraph GH["GitHub (this repo)"]
    MAIN["main branch"]
    WF_FE["deploy-github-pages.yml"]
    WF_BE["backend-ci.yml"]
    WF_CI["ci.yml (frontend)"]
  end

  subgraph Targets["Deployment targets"]
    PAGES["GitHub Pages<br/>frontend/out/"]
    DO["DigitalOcean<br/>backend Docker image"]
  end

  MAIN --> WF_FE --> PAGES
  MAIN --> WF_BE
  MAIN --> WF_CI
  DO -.->|"separate deploy<br/>(App Platform)"| DO
```

| Workflow | Trigger | Action |
|----------|---------|--------|
| `deploy-github-pages.yml` | Push to `main` | Build Next.js static export → deploy to GitHub Pages |
| `backend-ci.yml` | Push / PR | RuboCop + Rake tests |
| `ci.yml` | Push / PR | Frontend lint + Vitest |

### Local development

```bash
# Terminal 1 — backend (Docker, includes TEI embeddings)
cd backend && docker compose up --build
# API at http://localhost:3001

# Terminal 2 — frontend
cd frontend && npm install && npm run dev
# Site at http://localhost:3000
```

Set `NEXT_PUBLIC_API_URL=http://localhost:3001` in `frontend/.env` and configure `backend/.env` from `.env.example`.

## Repository layout

```
yblee85.github.io/
├── frontend/          # Next.js static site
│   ├── app/           # App Router pages
│   ├── components/    # UI, auth, chat, admin
│   └── lib/           # API helpers
├── backend/           # Ruby Sinatra API
│   ├── src/
│   │   ├── app/           # DI container
│   │   ├── lib/           # Config, embeddings, LLM, cache, events
│   │   ├── middleware/    # Auth, CSRF, rate limit, errors
│   │   └── service/       # Routes, RAG, auth, vector index, CLI
│   ├── script/        # Data sync shell script
│   └── docker-compose.yml
└── .github/workflows/ # CI/CD
```

## Design notes

- **No vector DB** — simplicity for a single-tenant portfolio; the full index fits in memory.
- **Static frontend + cookie auth** — GitHub Pages cannot run a Node server, so auth and chat logic live entirely on the backend with CORS + credentials.
- **Private data repo** — portfolio JSON stays out of the public site repo; the backend pulls it at runtime with a PAT.
- **Guest login** — lowers friction for demos while OAuth users get identifiable rate-limit keys.
