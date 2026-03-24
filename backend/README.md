# Backend - Ruby

## Overview

Backend Ruby app that answers portfolio questions using retrieval + optional Claude synthesis.

## Architecture

- app runtime: Ruby + Sinatra
- retrieval: in-memory vectors (no external vector DB required)
- embeddings: local Hugging Face Text Embeddings Inference (HTTP, usually in Docker)
- answer synthesis: Claude API
- data source: JSON files under `external/data`

### Why these fields?

- `content` answers recruiter questions directly
- `metadata.category` supports fast filtering (`work_experience`, `skills`, `personality`, etc.)
- `metadata.tags` improves retrieval quality for keyword-heavy queries
- stable `id` lets startup re-run safely without duplicates

## Runtime Flow

At startup:

1. Load all JSON files from `ABOUTME_DATA_DIR_PATH`
2. Split each `content` into character chunks (configurable)
3. Build vectors in memory using local embedding service
4. On request, retrieve top-k docs by cosine similarity
5. Optionally send contexts + question to Claude for final response

API endpoints:

- `GET /health`
- `POST /api/chat` with body: `{ "message": "..." }`

## Chroma utilities (optional)

This repo now includes:

- `external/aboutme/about.schema` - JSON schema reminder/contract
- `lib/chroma/client.rb` - Faraday-based ChromaDB HTTP client (`Chroma::Client`)
- `lib/chroma/loader.rb` - reads one JSON file and upserts into the file's `collection_name`
- `bin/load_data_to_chroma.rb` - CLI loader that sends data to a running Chroma server

Dependency:

- `faraday` gem (used by `Chroma::Client`)
- `langchainrb` + `anthropic` gems (used by `Llm::AnthropicClient`)

Run loader (example):

```bash
cd backend
bundle add faraday
export CHROMA_BASE_URL=http://localhost:8000
ruby ../bin/load_data_to_chroma.rb external_example/data/work.json
```

Use in app code:

```ruby
result = Chroma::Loader.upsert_file(
  file_path: "external_example/data/work.json",
  client: chroma_client
)

# result includes:
# result[:collection_name]
# result[:count]
# result[:ids]
```

Recommended env flags:

- `ABOUTME_DATA_DIR_PATH` path to JSON data files
- `EMBEDDING_BASE_URL` local embedding service URL
- `EMBEDDING_STARTUP_TIMEOUT_SECS` wait time for embedding service readiness (default `120`)
- `ANTHROPIC_API_KEY` optional, for final answer synthesis
- `RAG_CHUNK_SIZE_CHARS` character chunk size (default `2000`)
- `RAG_CHUNK_OVERLAP_PERCENT` chunk overlap percent (default `10`)

Startup performs fail-fast config validation (via `Config.validate_runtime!`).
The app exits early if required runtime config is invalid (e.g. missing/empty
`ABOUTME_DATA_DIR_PATH`, invalid `EMBEDDING_BASE_URL`, invalid chunk settings).

## Docker (local + production-friendly)

Inside `backend/`:

```bash
cd backend
docker compose up --build
```

Services:

- `backend` on `http://localhost:3001`
- `embeddings` on `http://localhost:8080`

### Startup data sync from private GitHub repo (optional)

In Docker, backend startup can pull your personal JSON data repo before booting the app.

Set:

- `GITHUB_ACCESS_TOKEN`
- `ABOUTME_DATA_GITHUB_REPO_NAME` (format: `owner/repo`)
- optional `ABOUTME_DATA_GITHUB_BRANCH` (default: `main`)

If both token + repo name are set, container startup will clone the repo and copy
`<repo>/data` into `ABOUTME_DATA_DIR_PATH`.
If not set, startup skips git sync and uses local files.

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