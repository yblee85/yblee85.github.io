/** Base URL for the portfolio API (no trailing slash). */
export function getApiBaseUrl(): string | null {
  const u = process.env.NEXT_PUBLIC_API_URL?.trim();
  if (!u) return null;
  return u.replace(/\/$/, "");
}
