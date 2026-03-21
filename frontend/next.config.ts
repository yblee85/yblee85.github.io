import type { NextConfig } from "next";

/** Static export for GitHub Pages (no Node server). */
const nextConfig: NextConfig = {
  output: "export",
  // Helps GitHub Pages serve `/career/` as `career/index.html`
  trailingSlash: true,
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
