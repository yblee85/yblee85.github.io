# yblee85.github.io

Personal site (Next.js) for [https://yblee85.github.io/](https://yblee85.github.io/).

## Local dev

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build (static export)

This project uses **`output: "export"`** so it can be hosted on **GitHub Pages** (static files only).

```bash
cd frontend
npm ci
npm run build
```

Output is **`frontend/out/`** (ignored by git). Do not commit it; CI builds on each push.

## Deploy to GitHub Pages

1. Push this repo to GitHub (branch **`main`**).
2. In the repo on GitHub: **Settings → Pages**.
3. Under **Build and deployment → Source**, choose **GitHub Actions** (not “Deploy from a branch” unless you use a manual `docs/` flow).
4. The workflow **Deploy to GitHub Pages** (`.github/workflows/deploy-github-pages.yml`) will:
   - install deps and run `npm run build` in **`frontend/`**
   - upload **`frontend/out`** as the site root for **`https://yblee85.github.io/`**

Because this is the **`username.github.io`** repository, the site is served from the **root** — no `basePath` is set in Next.js.

### Manual deploy (optional)

If you prefer not to use Actions, you can build locally and publish the contents of `frontend/out/` to the **`gh-pages`** branch or copy them into a **`docs/`** folder on `main` and set Pages to that folder (not recommended if you already use Actions).

## Project layout

- **`frontend/`** — Next.js app (App Router).
- **`frontend/public/`** — static assets (images, etc.) served as `/media/...`, etc.
