# yblee85.github.io

My portfolio site [https://yblee85.github.io/](https://yblee85.github.io/).

# Overview

It conists of 2 parts;

1. `frontend`(next.js app) that serves my portfolio page. One of features are `Chat with my agent` which you can ask anything about me and it will respond based on given context that are based on my experience.
   Hosted in github page

2. `backend`(ruby) REST api that has `/api/chat` endpoint which receives a question from a client and generates response using claude. Contexts (My personal experience) are downloaded separately using github personal access token.
   Hosted in digitalocean (App Platform)

# Getting started

## Prerequisite

1. Anthropic API key: to generate answer based on given context

2. Voyage AI API key (embeddings): to generate text embeddings for semantic search/retrieval in the RAG pipeline.

   - Alternatively, we can run embedding server locally using hugginface. (`backend/docker-compose.yml`)

3. auth0 (IdP): `Chat with my agent` tab is a protected route and requires oauth2 login (google, github, linkedin)

4. At least one of following upstream IdPs

   - Google Developer console account (Auth Platform): if you want `Continue with google`

   - Github OAuth app (Developer settings): if you want `Continue with github`

   - Linkedin Developer, Company page: if you want `Continue with linkedin`

## Run demo

1. Run `backend`; see [Docker (local + production-friendly)](backend/README.md#docker-local--production-friendly).

2. Run `frontend`; see [Local dev](frontend/README.md#local-dev).

3. Visit [http://localhost:3000](http://localhost:3000).
