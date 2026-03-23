import type { NextConfig } from "next";
import path from "path";

// Repo may have a lockfile above `frontend/`, so Turbopack can pick the wrong
// workspace root and fail to resolve `tailwindcss`. Pin the app root to cwd.
// Run dev/build from `frontend/` (e.g. `cd frontend && npm run dev`).
const appRoot = path.resolve(process.cwd());

/** Static export for GitHub Pages (no Node server). */
const nextConfig: NextConfig = {
  turbopack: {
    root: appRoot,
  },
  output: "export",
  // Helps GitHub Pages serve `/career/` as `career/index.html`
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
