# Backend

## Overview

Backend Ruby app that answers portfolio questions using retrieval + optional Claude synthesis.

## Architecture

- app runtime: Ruby + Sinatra
- retrieval: in-memory vectors (no external vector DB required)
- embeddings: provider-based (`tei` local service or `voyage` public API)
- answer synthesis: Claude API
- data source: JSON files under `external/data`

## Runtime Flow

At startup:

1. Load all JSON files from `ABOUTME_DATA_DIR_PATH`
2. Split each `content` into character chunks (configurable)
3. Build vectors in memory using configured embedding provider
4. On request, retrieve top-k docs by cosine similarity
5. Optionally send contexts + question to Claude for final response

API endpoints:

- `GET /`
- `GET /health`
- `POST /api/chat` with body: `{ "message": "..." }`


## Docker (local + production-friendly)

Inside `backend/`:

Copy `.env.example` and paste into `.env`, replace `CHANGE_ME` with actual value 

```bash
cd backend
docker compose up --build
```

Services (for local `tei` provider):

- `backend` on `http://localhost:3001`
- `embeddings` on `http://localhost:8080`

When using `voyage`, set `EMBEDDING_PROVIDER=voyage` and `VOYAGE_API_KEY`.
In that mode, the backend does not depend on the local `embeddings` container.

Quick test:

```bash
curl -s http://localhost:3001/health | jq
curl -s -X POST http://localhost:3001/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What are Yunbo contributions at Mappedin?"}' | jq
```

## Lint and test

```bash
cd backend
bundle install
bundle exec rubocop
bundle exec rake test
```